import AppKit
import ServiceManagement
import os.log

private let log = Logger(subsystem: "com.quanphan.take-a-break", category: "App")

final class AppDelegate: NSObject, NSApplicationDelegate {
    let scheduler = BreakScheduler()
    private var overlayController: OverlayWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let service = SMAppService.mainApp
        if !UserDefaults.standard.bool(forKey: "launchAtLoginConfigured") {
            do {
                try service.register()
                log.info("Launch at login registered. Status: \(service.status.rawValue)")
            } catch {
                log.error("Failed to register launch at login: \(error)")
            }
            UserDefaults.standard.set(true, forKey: "launchAtLoginConfigured")
        }

        overlayController = OverlayWindowController(scheduler: scheduler)
        scheduler.start()

        NotificationCenter.default.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.scheduler.start()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            sender.windows.first(where: { $0.canBecomeKey })?.makeKeyAndOrderFront(nil)
        }
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
