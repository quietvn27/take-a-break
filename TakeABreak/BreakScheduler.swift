import Foundation
import Combine

enum BreakType: Equatable { case micro, macro }

enum SchedulerState: Equatable {
    case idle
    case working(secondsUntilMicro: Int, secondsUntilMacro: Int)
    case onBreak(type: BreakType, secondsRemaining: Int)
}

final class BreakScheduler: ObservableObject {
    @Published var state: SchedulerState = .idle

    var settings: BreakSettings {
        didSet { settings.save(); restart() }
    }

    private var cancellable: AnyCancellable?
    private var microCountdown: Int = 0
    private var macroCountdown: Int = 0
    private var breakCountdown: Int = 0
    private var currentBreakType: BreakType = .micro

    init(settings: BreakSettings = .load()) {
        self.settings = settings
    }

    func start() {
        cancellable = nil
        microCountdown = settings.microWorkSeconds
        macroCountdown = settings.macroWorkSeconds
        state = .working(secondsUntilMicro: microCountdown, secondsUntilMacro: macroCountdown)
        scheduleTick()
    }

    func skip() {
        guard case .onBreak = state else { return }
        endBreak()
    }

    func postpone(minutes: Int) {
        guard case .onBreak(let type, _) = state else { return }
        let extra = minutes * 60
        switch type {
        case .micro:
            microCountdown = extra
            // macroCountdown keeps its current value from when the break started
        case .macro:
            macroCountdown = extra
            microCountdown = settings.microWorkSeconds
        }
        // Timer is already running; changing state to .working is enough
        state = .working(secondsUntilMicro: microCountdown, secondsUntilMacro: macroCountdown)
    }

    func pause() {
        cancellable = nil
        state = .idle
    }

    private func restart() {
        cancellable = nil
        start()
    }

    private func scheduleTick() {
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    func tick() {
        switch state {
        case .working:
            microCountdown -= 1
            macroCountdown -= 1

            if macroCountdown <= 0 {
                startBreak(type: .macro)
            } else if microCountdown <= 0 {
                if macroCountdown <= 45 {
                    microCountdown = settings.microWorkSeconds
                } else {
                    startBreak(type: .micro)
                }
            } else {
                state = .working(secondsUntilMicro: microCountdown, secondsUntilMacro: macroCountdown)
            }

        case .onBreak:
            breakCountdown -= 1
            if breakCountdown <= 0 {
                endBreak()
            } else {
                state = .onBreak(type: currentBreakType, secondsRemaining: breakCountdown)
            }

        case .idle:
            break
        }
    }

    private func startBreak(type: BreakType) {
        cancellable = nil
        currentBreakType = type
        breakCountdown = type == .micro ? settings.microBreakSeconds : settings.macroBreakSeconds
        state = .onBreak(type: type, secondsRemaining: breakCountdown)
        scheduleTick()
    }

    private func endBreak() {
        microCountdown = settings.microWorkSeconds
        if currentBreakType == .macro {
            macroCountdown = settings.macroWorkSeconds
        }
        state = .working(secondsUntilMicro: microCountdown, secondsUntilMacro: macroCountdown)
    }
}
