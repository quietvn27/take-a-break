import Foundation

enum OverlayStyle: String, CaseIterable {
    case simple
    case animation
}

struct BreakSettings {
    var microWorkSeconds: Int
    var microBreakSeconds: Int
    var macroWorkSeconds: Int
    var macroBreakSeconds: Int
    var overlayStyle: OverlayStyle

    static let defaults = BreakSettings(
        microWorkSeconds: 300,
        microBreakSeconds: 15,
        macroWorkSeconds: 1200,
        macroBreakSeconds: 300,
        overlayStyle: .animation
    )

    static func load() -> BreakSettings {
        let ud = UserDefaults.standard
        let styleRaw = ud.string(forKey: "overlayStyle") ?? "animation"
        return BreakSettings(
            microWorkSeconds: ud.integer(forKey: "microWorkSeconds").nonZeroOr(300),
            microBreakSeconds: ud.integer(forKey: "microBreakSeconds").nonZeroOr(15),
            macroWorkSeconds: ud.integer(forKey: "macroWorkSeconds").nonZeroOr(1200),
            macroBreakSeconds: ud.integer(forKey: "macroBreakSeconds").nonZeroOr(300),
            overlayStyle: OverlayStyle(rawValue: styleRaw) ?? .animation
        )
    }

    func save() {
        let ud = UserDefaults.standard
        ud.set(microWorkSeconds, forKey: "microWorkSeconds")
        ud.set(microBreakSeconds, forKey: "microBreakSeconds")
        ud.set(macroWorkSeconds, forKey: "macroWorkSeconds")
        ud.set(macroBreakSeconds, forKey: "macroBreakSeconds")
        ud.set(overlayStyle.rawValue, forKey: "overlayStyle")
    }
}

private extension Int {
    func nonZeroOr(_ fallback: Int) -> Int { self > 0 ? self : fallback }
}
