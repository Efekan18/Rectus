import Foundation
import Observation

/// Keeps the timing of one reminder session: when it ends and when the next reminder is due.
@MainActor
@Observable
final class ReminderSession {
    /// intervalMinutes value meaning "a random interval between 15 and 30 minutes".
    nonisolated static let variedInterval = 0
    /// Reminders are skipped if there has been no keyboard or mouse input for this long:
    /// you're probably not at the desk.
    static let idleThreshold: TimeInterval = 5 * 60

    private(set) var isActive = false
    private(set) var endDate: Date?          // nil = until stopped
    private(set) var nextReminder: Date?

    private var intervalMinutes = 20
    private var ticker: Task<Void, Never>?

    /// Called when a reminder is due (the panel + sound are hooked up here).
    var onReminder: () -> Void = {}
    /// Called when the session time runs out.
    var onFinish: () -> Void = {}
    /// Seconds since the last user input. Replaceable so tests can fake it.
    var idleSeconds: () -> TimeInterval = { 0 }

    /// sessionMinutes 0 = until stopped; intervalMinutes 0 = varied (15–30 min).
    func start(sessionMinutes: Int, intervalMinutes: Int, at start: Date = Date()) {
        self.intervalMinutes = intervalMinutes
        endDate = sessionMinutes > 0 ? start.addingTimeInterval(TimeInterval(sessionMinutes * 60)) : nil
        nextReminder = start.addingTimeInterval(nextInterval())
        isActive = true

        ticker?.cancel()
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                self?.tick()
            }
        }
    }

    func stop() {
        ticker?.cancel()
        ticker = nil
        isActive = false
        endDate = nil
        nextReminder = nil
    }

    /// Runs every second. Takes the time as a parameter so it can be tested.
    func tick(at time: Date = Date()) {
        guard isActive else { return }

        if let endDate, time >= endDate {
            stop()
            onFinish()
            return
        }

        if let next = nextReminder, time >= next {
            // Schedule the next one from "now", not from the old plan, so reminders
            // can never pile up and fire back to back.
            nextReminder = time.addingTimeInterval(nextInterval())
            if idleSeconds() < Self.idleThreshold {
                onReminder()
            }
        }
    }

    /// The fixed interval, or a fresh random one in varied mode. A slightly unpredictable
    /// rhythm is harder to tune out than a reminder that comes like clockwork.
    private func nextInterval() -> TimeInterval {
        let minutes = intervalMinutes == Self.variedInterval ? Int.random(in: 15...30) : intervalMinutes
        return TimeInterval(minutes * 60)
    }
}
