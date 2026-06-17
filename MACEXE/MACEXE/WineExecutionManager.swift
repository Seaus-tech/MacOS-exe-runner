import Foundation
import SwiftUI
import Combine

class WineExecutionManager: ObservableObject {
    @Published var logOutput: String = ""
    @Published var isExecuting: Bool = false
    
    private var process: Process?
    private var outputPipe: Pipe?
    
    /// Launches an embedded Windows executable using the bundled Wine runtime.
    /// - Parameter targetExePath: The absolute path to the Windows file (e.g., an installer .exe).
    func runExecutable(at targetExePath: String, args: String = "") {
        guard !isExecuting else {
            appendLog("[Warning] Execution already in progress.")
            return
        }
        
        self.isExecuting = true
        self.logOutput = "[System] Initializing isolated translation layer...\n"
        
        // Prefer system Wine Devel.app if installed
        let wineDevelBase = (NSHomeDirectory() as NSString)
            .appendingPathComponent("Applications/Wine Devel.app/Contents/Resources/wine")
        let useSystemWine = FileManager.default.isExecutableFile(atPath: "\(wineDevelBase)/bin/wine")
        
        let binDirectory: String
        let libDirectory: String
        let wine64Binary: String
        
        if useSystemWine {
            binDirectory  = "\(wineDevelBase)/bin"
            libDirectory  = "\(wineDevelBase)/lib"
            wine64Binary  = "\(wineDevelBase)/bin/wine"
            appendLog("[System] Using Wine Devel.app\n")
        } else {
            guard let runtimesURL = Bundle.main.url(forResource: "Runtimes", withExtension: nil) else {
                appendLog("[Fatal Error] 'Runtimes' folder could not be located in the App Bundle Resources.")
                isExecuting = false
                return
            }
            binDirectory = runtimesURL.appendingPathComponent("bin").path
            libDirectory = runtimesURL.appendingPathComponent("lib").path
            wine64Binary = runtimesURL.appendingPathComponent("bin/wine").path
            appendLog("[System] Using bundled Wine runtime\n")
        }
        
        guard FileManager.default.isExecutableFile(atPath: wine64Binary) else {
            appendLog("[Fatal Error] Wine binary not found at: \(wine64Binary)")
            isExecuting = false
            return
        }
        let extraArgs = args
        let customPrefix = (NSHomeDirectory() as NSString).appendingPathComponent(".macexe_prefix")
        
        // 2. Spawn a background thread to prevent blocking the SwiftUI main thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let task = Process()
            let pipe = Pipe()
            self.outputPipe = pipe
            
            task.standardOutput = pipe
            task.standardError = pipe
            task.executableURL = URL(fileURLWithPath: "/bin/zsh")
            
            // 3. Construct the shell command sequence.
            // Crucial: WINELOADER and DYLD_FALLBACK_LIBRARY_PATH prevent path-linkage crashes.
            let launchScript = """
            export WINEPREFIX="\(customPrefix)"
            export PATH="\(binDirectory):$PATH"
            export WINELOADER="\(wine64Binary)"
            export DYLD_FALLBACK_LIBRARY_PATH="\(libDirectory):/usr/lib:/usr/local/lib"
            export WINEDEBUG=-all
            export DISPLAY=
            export WINEDLLOVERRIDES="winemenubuilder.exe=d"
            
            # Kill any stale wineserver
            "\(binDirectory)/wineserver" -k 2>/dev/null
            sleep 0.5
            
            # Init prefix silently if needed (timeout 30s)
            if [ ! -f "$WINEPREFIX/system.reg" ]; then
                "\(wine64Binary)" wineboot --init 2>/dev/null &
                BOOT_PID=$!
                for i in $(seq 1 30); do
                    [ -f "$WINEPREFIX/system.reg" ] && break
                    sleep 1
                done
                kill $BOOT_PID 2>/dev/null
                wait $BOOT_PID 2>/dev/null
            fi
            
            "\(wine64Binary)" "\(targetExePath)" \(extraArgs)
            """
            
            task.currentDirectoryURL = URL(fileURLWithPath: targetExePath).deletingLastPathComponent()
            task.arguments = ["-c", launchScript]
            self.process = task
            
            // Handle process termination cleanup
            task.terminationHandler = { [weak self] completedTask in
                DispatchQueue.main.async {
                    self?.isExecuting = false
                    self?.appendLog("\n[System] Wine environment exited with code: \(completedTask.terminationStatus)")
                }
            }
            
            // 4. Set up non-blocking stream listening for standard output logs
            let fileHandle = pipe.fileHandleForReading
            fileHandle.waitForDataInBackgroundAndNotify()
            
            var dataObserver: NSObjectProtocol?
            dataObserver = NotificationCenter.default.addObserver(
                forName: NSNotification.Name.NSFileHandleDataAvailable,
                object: fileHandle,
                queue: nil
            ) { [weak self] _ in
                let data = fileHandle.availableData
                if data.count > 0 {
                    if let text = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async {
                            self?.appendLog(text)
                        }
                    }
                    fileHandle.waitForDataInBackgroundAndNotify()
                } else {
                    if let observer = dataObserver {
                        NotificationCenter.default.removeObserver(observer)
                    }
                }
            }
            
            do {
                try task.run()
            } catch {
                DispatchQueue.main.async {
                    self.isExecuting = false
                    self.appendLog("\n[Execution Error] Shell launch failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func appendLog(_ text: String) {
        if Thread.isMainThread {
            self.logOutput += text
        } else {
            DispatchQueue.main.async {
                self.logOutput += text
            }
        }
    }
    
    func terminateActiveEnvironment() {
        if let process = process, process.isRunning {
            process.terminate()
            appendLog("\n[System] Execution forcefully terminated by user.")
        }
    }
}
