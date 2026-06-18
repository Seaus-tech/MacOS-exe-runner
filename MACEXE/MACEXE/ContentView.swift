import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var wineManager = WineExecutionManager()
    @State private var targetFilePath: String = ""
    @State private var extraArgs: String = ""
    @State private var isDraggingOver = false
    @State private var showWaitlist = false
    @State private var showExeBrowser = false
    @State private var prefixExes: [String] = []

    @AppStorage("recentExes") private var recentExesData: Data = Data()
    @AppStorage("macexe.ai.approved") private var aiApproved = false

    var recentExes: [String] {
        (try? JSONDecoder().decode([String].self, from: recentExesData)) ?? []
    }

    func addRecent(_ path: String) {
        var list = recentExes.filter { $0 != path }
        list.insert(path, at: 0)
        recentExesData = (try? JSONEncoder().encode(Array(list.prefix(10)))) ?? Data()
    }

    func launch() {
        guard !targetFilePath.isEmpty else { return }
        addRecent(targetFilePath)
        wineManager.runExecutable(at: targetFilePath, args: extraArgs)
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(nsColor: .windowBackgroundColor), Color(nsColor: .controlBackgroundColor)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "cube.transparent.fill").font(.title2).foregroundStyle(.tint)
                    Text("MACEXE").font(.title2.bold())
                    Spacer()
                    if wineManager.isExecuting {
                        Label("Running", systemImage: "circle.fill")
                            .font(.caption).foregroundStyle(.green)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .glassEffect()
                    }
                    Button {
                        showWaitlist = true
                    } label: {
                        Label(aiApproved ? "AI Approved" : "AI", systemImage: aiApproved ? "checkmark.circle.fill" : "brain.head.profile")
                            .font(.caption)
                            .foregroundStyle(aiApproved ? .green : .primary)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal, 4)
                .sheet(isPresented: $showWaitlist) {
                    if aiApproved {
                        AIView(targetFilePath: $targetFilePath, extraArgs: $extraArgs, logOutput: wineManager.logOutput)
                    } else {
                        WaitlistView()
                    }
                }

                // Input panel
                VStack(spacing: 8) {
                    // Drop zone
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(isDraggingOver ? Color.accentColor : Color.secondary.opacity(0.3),
                                          style: StrokeStyle(lineWidth: 2, dash: [6]))
                            .frame(height: 56)
                        VStack(spacing: 2) {
                            Image(systemName: "arrow.down.doc")
                                .foregroundStyle(isDraggingOver ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                            Text("Drop .exe here").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .onDrop(of: [.fileURL], isTargeted: $isDraggingOver) { providers in
                        providers.first?.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { data, _ in
                            guard let data,
                                  let str = String(data: data, encoding: .utf8),
                                  let url = URL(string: str.trimmingCharacters(in: .whitespacesAndNewlines)) else { return }
                            DispatchQueue.main.async { targetFilePath = url.path }
                        }
                        return true
                    }

                    // Path row
                    HStack(spacing: 8) {
                        TextField("Absolute path to .exe", text: $targetFilePath)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 10).padding(.vertical, 7)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 8))

                        Button {
                            let panel = NSOpenPanel()
                            panel.allowedContentTypes = [UTType(filenameExtension: "exe") ?? .data]
                            panel.canChooseFiles = true; panel.canChooseDirectories = false
                            if panel.runModal() == .OK, let url = panel.url { targetFilePath = url.path }
                        } label: { Image(systemName: "folder") }
                        .buttonStyle(.bordered)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 8))

                        Button { launch() } label: {
                            if wineManager.isExecuting {
                                ProgressView().controlSize(.small).frame(width: 56)
                            } else {
                                Label("Launch", systemImage: "play.fill").frame(width: 56)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(wineManager.isExecuting || targetFilePath.isEmpty)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 8))
                    }

                    TextField("Arguments (optional, e.g. --no-sandbox)", text: $extraArgs)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 10).padding(.vertical, 7)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 8))
                }
                .padding(12)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))

                // Recents + prefix browser
                HStack(spacing: 12) {
                    // Recents
                    if !recentExes.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Recent", systemImage: "clock").font(.caption).foregroundStyle(.secondary)
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(alignment: .leading, spacing: 2) {
                                    ForEach(recentExes, id: \.self) { path in
                                        Button {
                                            targetFilePath = path
                                        } label: {
                                            HStack {
                                                Image(systemName: "doc").foregroundStyle(.secondary).font(.caption)
                                                Text(URL(fileURLWithPath: path).lastPathComponent)
                                                    .lineLimit(1).truncationMode(.middle)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                            .padding(.horizontal, 8).padding(.vertical, 4)
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)
                                        .background(targetFilePath == path ? Color.accentColor.opacity(0.15) : Color.clear,
                                                    in: RoundedRectangle(cornerRadius: 6))
                                    }
                                }
                            }
                            .frame(maxHeight: 120)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                    }

                    // Prefix EXE browser
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Label("Wine Prefix", systemImage: "tray.full").font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            Button {
                                let prefix = NSHomeDirectory() + "/.macexe_prefix/drive_c"
                                prefixExes = findExes(in: prefix)
                                showExeBrowser = true
                            } label: { Image(systemName: "arrow.clockwise").font(.caption) }
                            .buttonStyle(.plain)
                        }
                        if prefixExes.isEmpty {
                            Text("Click ↺ to scan installed .exe files")
                                .font(.caption2).foregroundStyle(.tertiary)
                        } else {
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(alignment: .leading, spacing: 2) {
                                    ForEach(prefixExes, id: \.self) { path in
                                        Button {
                                            targetFilePath = path
                                        } label: {
                                            HStack {
                                                Image(systemName: "doc").foregroundStyle(.secondary).font(.caption)
                                                Text(URL(fileURLWithPath: path).lastPathComponent)
                                                    .lineLimit(1).truncationMode(.middle)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                            .padding(.horizontal, 8).padding(.vertical, 4)
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)
                                        .background(targetFilePath == path ? Color.accentColor.opacity(0.15) : Color.clear,
                                                    in: RoundedRectangle(cornerRadius: 6))
                                    }
                                }
                            }
                            .frame(maxHeight: 120)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                }

                // Console log
                ScrollViewReader { proxy in
                    ScrollView(.vertical) {
                        Text(wineManager.logOutput.isEmpty ? "Console output will stream here…" : wineManager.logOutput)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(wineManager.logOutput.isEmpty ? .tertiary : .primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10).id("log")
                    }
                    .frame(maxHeight: .infinity)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
                    .onChange(of: wineManager.logOutput) { _, _ in proxy.scrollTo("log", anchor: .bottom) }
                }

                if wineManager.isExecuting {
                    Button("Force Terminate", role: .destructive) { wineManager.terminateActiveEnvironment() }
                        .buttonStyle(.borderedProminent)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()
        }
        .frame(minWidth: 680, minHeight: 520)
    }

    func findExes(in directory: String) -> [String] {
        var results: [String] = []
        guard let enumerator = FileManager.default.enumerator(atPath: directory) else { return [] }
        for case let path as String in enumerator {
            if path.lowercased().hasSuffix(".exe") {
                results.append(directory + "/" + path)
            }
        }
        return results.sorted { URL(fileURLWithPath: $0).lastPathComponent < URL(fileURLWithPath: $1).lastPathComponent }
    }
}

#Preview { ContentView() }
