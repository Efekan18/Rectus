import Foundation
import Observation

/// Keeps the timing of one reminder session: when it ends, when the next reminder is
/// due, and how many reminders have fired so far.
@MainActor
@Observable
final class ReminderSession {
    private(set) var isActive = false
    private(set) var endDate: Date?          // nil = until stopped
    private(set) var nextReminder: Date?
    private(set) var reminderCount = 0
    private(set) var now = Date()            // updated every second; the UI reads this

    private var interval: TimeInterval = 0
    private var ticker: Task<Void, Never>?

    /// Called when a reminder is due (the panel + sound are hooked up here).
    var onReminder: () -> Void = {}
    /// Called when the session time runs out.
    var onFinish: () -> Void = {}

    /// A sessionMinutes of 0 means the session runs until stopped.
    func start(sessionMinutes: Int, intervalMinutes: Int, at start: Date = Date()) {
        interval = TimeInterval(intervalMinutes * 60)
        endDate = sessionMinutes > 0 ? start.addingTimeInterval(TimeInterval(sessionMinutes * 60)) : nil
        nextReminder = start.addingTimeInterval(interval)
        reminderCount = 0
        now = start
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
        now = time

        if let endDate, time >= endDate {
            stop()
            onFinish()
            return
        }

        if let next = nextReminder, time >= next {
            reminderCount += 1
            // Count the next one from "now": after the Mac wakes from sleep, missed
            // reminders shouldn't fire back to back; a single one is enough.
            nextReminder = time.addingTimeInterval(interval)
            onReminder()
        }
    }

    var secondsUntilNextReminder: TimeInterval? {
        nextReminder.map { $0.timeIntervalSince(now) }
    }

    var secondsUntilEnd: TimeInterval? {
        endDate.map { $0.timeIntervalSince(now) }
    }
}

/// Converts seconds left to minutes, rounded up: 1200 s → 20, 1199 s → 20, 30 s → 1.
/// Rounding up means it never says "0 min" while you're still waiting.
func minutesLeft(_ seconds: TimeInterval) -> Int {
    max(0, Int((seconds / 60).rounded(.up)))
}
