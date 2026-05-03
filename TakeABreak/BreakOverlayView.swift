import SwiftUI
import AppKit

// MARK: - Sliding panel (pure AppKit + explicit CABasicAnimation)

final class SlidingNSView: NSView {
    private let imageLayer = CALayer()
    private let slideFromTop: Bool
    private let slideDelay: Double

    init(image: NSImage, slideFromTop: Bool, delay: Double) {
        self.slideFromTop = slideFromTop
        self.slideDelay = delay
        super.init(frame: .zero)

        wantsLayer = true
        layer!.masksToBounds = true

        imageLayer.contents = image
        imageLayer.contentsGravity = .resizeAspectFill
        imageLayer.masksToBounds = true
        layer!.addSublayer(imageLayer)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layout() {
        super.layout()
        // Keep the MODEL frame at the final/normal position at all times.
        // CABasicAnimation drives the PRESENTATION layer independently, so
        // this never conflicts with a running animation.
        imageLayer.frame = bounds
    }

    /// Call this after the window is on-screen with a valid frame.
    func startSlideIn() {
        guard !bounds.isEmpty else { return }

        let h = bounds.height
        let centerY = imageLayer.position.y    // = h/2 (centre of normal frame)

        // Non-flipped NSView coordinate system: positive-Y is upward.
        // slideFromTop  → start ABOVE screen → fromY = centerY + h
        // slideFromBottom → start BELOW screen → fromY = centerY - h
        let fromY: CGFloat = slideFromTop ? (centerY + h) : (centerY - h)

        let anim = CABasicAnimation(keyPath: "position.y")
        anim.fromValue = fromY       // off-screen start position
        anim.toValue   = centerY     // final on-screen position
        anim.duration  = 1.7
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        // beginTime delay staggers panels; fillMode=.backwards shows the
        // fromValue immediately so the panel is invisible until it slides in.
        anim.beginTime  = CACurrentMediaTime() + slideDelay + 0.05
        anim.fillMode   = .backwards

        imageLayer.add(anim, forKey: "slideIn")
    }
}

// MARK: - Break controls (countdown + skip button, no panels)

struct BreakControlsView: View {
    @ObservedObject var scheduler: BreakScheduler
    var showHeader: Bool = true

    var body: some View {
        ZStack(alignment: showHeader ? .center : .top) {
            Color.clear
            VStack(spacing: 24) {
                if showHeader {
                    Image(systemName: "eye")
                        .font(.system(size: 64))
                        .foregroundColor(.white)

                    Text(titleText)
                        .font(.title)
                        .foregroundColor(.white)
                }

                Text(countdownText)
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)

                HStack(spacing: 12) {
                    Button("Postpone 5 min") {
                        scheduler.postpone(minutes: 5)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.white.opacity(0.15))
                    .foregroundColor(.white)

                    Button(skipButtonLabel) {
                        scheduler.skip()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.white.opacity(0.35))
                    .foregroundColor(.white)
                }
            }
            .padding(.top, showHeader ? 0 : 60)
        }
    }

    private var titleText: String {
        guard case .onBreak(let type, _) = scheduler.state else { return "" }
        return type == .micro ? "Rest your eyes" : "Time for a longer break"
    }

    private var countdownText: String {
        guard case .onBreak(_, let secs) = scheduler.state else { return "" }
        let m = secs / 60, s = secs % 60
        return m > 0 ? String(format: "%d:%02d", m, s) : "\(secs)s"
    }

    private var skipButtonLabel: String {
        guard case .onBreak(let type, _) = scheduler.state else { return "Skip" }
        return type == .micro ? "Skip Break" : "Stop Break"
    }
}
