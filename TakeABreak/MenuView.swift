import SwiftUI

struct MenuView: View {
    @EnvironmentObject var scheduler: BreakScheduler
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        if case .working = scheduler.state {
            Button("Pause") { scheduler.pause() }
        } else if case .idle = scheduler.state {
            Button("Resume") { scheduler.start() }
        }

        Button("Settings...") {
            openWindow(id: "settings")
            NSApp.activate(ignoringOtherApps: true)
        }

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
    }
}
