import AppKit
import SwiftUI
import Combine

final class OverlayWindowController: NSObject {
    private var window: NSWindow?
    private var cancellable: AnyCancellable?
    private let scheduler: BreakScheduler
    private var overlayVisible = false

    private static let microPanelImages: [NSImage?] = loadPanels(["panel1", "panel2", "panel3"])
    private static let macroPanelImages: [NSImage?] = loadPanels(["panel4", "panel5", "panel6"])

    private static func loadPanels(_ names: [String]) -> [NSImage?] {
        names.map { name in
            guard let path = Bundle.main.path(forResource: name, ofType: "png", inDirectory: "resources") else {
                return nil
            }
            return NSImage(contentsOfFile: path)
        }
    }

    init(scheduler: BreakScheduler) {
        self.scheduler = scheduler
        super.init()
        cancellable = scheduler.$state.sink { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .onBreak: self?.showOverlay()
                default:       self?.hideOverlay()
                }
            }
        }
    }

    private func showOverlay() {
        guard !overlayVisible else { return }
        overlayVisible = true

        let screen = NSScreen.main ?? NSScreen.screens[0]
        let screenFrame = screen.frame

        if window == nil {
            let win = NSWindow(
                contentRect: screenFrame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            win.level = .screenSaver
            win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            win.isOpaque = false
            win.backgroundColor = .clear
            win.ignoresMouseEvents = false
            win.isReleasedWhenClosed = false
            self.window = win
        }

        let size = screenFrame.size

        switch scheduler.settings.overlayStyle {
        case .simple:
            buildSimpleOverlay(size: size)
        case .animation:
            guard case .onBreak(let breakType, _) = scheduler.state else { return }
            let images = breakType == .micro ? Self.microPanelImages : Self.macroPanelImages
            buildAnimationOverlay(size: size, images: images)
        }
    }

    private func buildSimpleOverlay(size: CGSize) {
        let root = NSView(frame: CGRect(origin: .zero, size: size))
        root.wantsLayer = true
        root.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.5).cgColor

        let controlsView = NSHostingView(rootView: BreakControlsView(scheduler: scheduler, showHeader: true))
        controlsView.frame = CGRect(origin: .zero, size: size)
        root.addSubview(controlsView)

        addAppIconBadge(to: root, screenSize: size)

        window?.contentView = root
        window?.makeKeyAndOrderFront(nil)
    }

    private func buildAnimationOverlay(size: CGSize, images: [NSImage?]) {
        let panelWidth = size.width / 3

        let root = NSView(frame: CGRect(origin: .zero, size: size))
        root.wantsLayer = true
        root.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.5).cgColor

        let configs: [(Bool, Double)] = [(true, 0.0), (false, 1.7), (true, 3.4)]
        var panels: [SlidingNSView] = []

        for (i, (fromTop, delay)) in configs.enumerated() {
            guard let img = images[i] else { continue }
            let panel = SlidingNSView(image: img, slideFromTop: fromTop, delay: delay)
            panel.frame = CGRect(x: CGFloat(i) * panelWidth, y: 0, width: panelWidth, height: size.height)
            root.addSubview(panel)
            panels.append(panel)
        }

        let controlsView = NSHostingView(rootView: BreakControlsView(scheduler: scheduler, showHeader: false))
        controlsView.frame = CGRect(origin: .zero, size: size)
        root.addSubview(controlsView)

        addAppIconBadge(to: root, screenSize: size)

        window?.contentView = root
        window?.makeKeyAndOrderFront(nil)

        DispatchQueue.main.async {
            panels.forEach { $0.startSlideIn() }
        }
    }

    // Adds the app icon as the topmost subview, pinned to the bottom-right corner.
    // NSView coordinates are non-flipped: y=0 is the bottom edge.
    private func addAppIconBadge(to root: NSView, screenSize: CGSize) {
        guard let icon = NSImage(named: NSImage.applicationIconName) else { return }
        let size: CGFloat = 52
        let margin: CGFloat = 20
        let imageView = NSImageView(frame: CGRect(
            x: screenSize.width - size - margin,
            y: margin,
            width: size,
            height: size
        ))
        imageView.image = icon
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.wantsLayer = true
        imageView.layer?.opacity = 0.9
        root.addSubview(imageView)
    }

    private func hideOverlay() {
        overlayVisible = false
        window?.orderOut(nil)
    }
}
