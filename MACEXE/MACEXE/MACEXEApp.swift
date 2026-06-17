import SwiftUI

@main
struct MACEXEApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // Force macOS to respect our custom interface bounding sizes on boot
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }
}
