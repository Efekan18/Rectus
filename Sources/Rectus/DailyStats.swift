import Foundation
import Observation

/// Today's tally: how many reminders appeared and how many you confirmed with
/// "I'm upright". Resets on a new day; stored in UserDefaults.
@MainActor
@Observable
final class DailyStats {
    private(set) var shown = 0
    private(set) var checked = 0
    private var day = ""

    private let defaults = UserDefaults.standard

    init() {
        day = defaults.string(forKey: "statsDay") ?? ""
        shown = defaults.integer(forKey: "statsShown")
        checked = defaults.integer(forKey: "statsChecked")
        rollOverIfNewDay()
    }

    func recordShown() {
        rollOverIfNewDay()
        shown += 1
        save()
    }

    func recordChecked() {
        rollOverIfNewDay()
        checked += 1
        save()
    }

    private func rollOverIfNewDay(now: Date = Date()) {
        let today = now.formatted(.iso8601.year().month().day())   // e.g. 2026-10-24
        if day != today {
            day = today
            shown = 0
            checked = 0
            save()
        }
    }

    private func save() {
        defaults.set(day, forKey: "statsDay")
        defaults.set(shown, forKey: "statsShown")
        defaults.set(checked, forKey: "statsChecked")
    }
}
