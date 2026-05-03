import SwiftUI

@main
struct TakeABreakApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup("Take a Break", id: "settings") {
            SettingsView()
                .environmentObject(appDelegate.scheduler)
        }
        .defaultSize(width: 380, height: 740)
    }
}
