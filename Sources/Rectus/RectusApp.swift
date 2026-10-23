import SwiftUI

// Note: no @State here. In the macOS 27 SDK @State is a macro whose plugin ships only
// with Xcode, so it doesn't compile with the Command Line Tools alone. Persistent
// settings live in @AppStorage, changing state in @Observable classes.

@main
struct RectusApp: App {
    private let session = ReminderSession()
    private let stats = DailyStats()

    init() {
        // No Dock icon; live only in the menu bar.
        NSApplication.shared.setActivationPolicy(.accessory)
        // Treat sound as on if it was never set (matches the @AppStorage default).
        UserDefaults.standard.register(defaults: ["soundEnabled": true])
        Options.resetInvalidSettings()

        let session = session, stats = stats
        session.idleSeconds = AwayDetector.idleSeconds
        session.onReminder = {
            stats.recordShown()
            showReminder(onCheck: { stats.recordChecked() })
        }
        session.onFinish = {
            ReminderPanel.shared.show(title: "Session finished",
                                      message: "Get up and stretch a little.",
                                      playSound: soundEnabled)
        }
        // Away from the desk (sleep, lock, screen saver): end the session instead of
        // counting down for nobody.
        AwayDetector.watch { session.stop() }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContent(session: session, stats: stats)
        } label: {
            // Standing figure while reminders are on, seated figure while they're off.
            Image(systemName: session.isActive ? "figure.stand" : "figure.seated.side.left")
        }
    }
}

@MainActor
private var soundEnabled: Bool { UserDefaults.standard.bool(forKey: "soundEnabled") }

@MainActor
private func showReminder(onCheck: @escaping () -> Void) {
    ReminderPanel.shared.show(title: "Sit up straight",
                              message: postureTips.randomElement()!,
                              playSound: soundEnabled,
                              onCheck: onCheck)
}

/// The choices offered in the menu.
enum Options {
    static let sessionMinutes = [60, 120, 180, 0]        // 0 = until stopped
    static let intervalMinutes: [Int] = {
        #if DEBUG
        [1, 15, 20, 30, 45, ReminderSession.variedInterval]   // 1 min is for testing only
        #else
        [15, 20, 30, 45, ReminderSession.variedInterval]
        #endif
    }()

    /// A value saved by an older version (e.g. a 10-minute interval) may no longer be on
    /// the menu; fall back to the default instead of starting with an invisible choice.
    static func resetInvalidSettings() {
        let defaults = UserDefaults.standard
        if let saved = defaults.object(forKey: "sessionMinutes") as? Int, !sessionMinutes.contains(saved) {
            defaults.removeObject(forKey: "sessionMinutes")
        }
        if let saved = defaults.object(forKey: "intervalMinutes") as? Int, !intervalMinutes.contains(saved) {
            defaults.removeObject(forKey: "intervalMinutes")
        }
    }
}

/// The menu that opens when you click the icon.
struct MenuContent: View {
    let session: ReminderSession
    let stats: DailyStats

    // Stored in UserDefaults, so the last choice survives a restart.
    @AppStorage("sessionMinutes") private var sessionMinutes = 0
    @AppStorage("intervalMinutes") private var intervalMinutes = 20
    @AppStorage("soundEnabled") private var soundEnabled = true

    var body: some View {
        if session.isActive {
            Text("Reminders on")
            Button("Stop") {
                session.stop()
            }
        } else {
            idleMenu
        }
        if stats.shown > 0 {
            Divider()
            Text("Today: \(stats.checked) of \(stats.shown) confirmed")
        }
        Divider()
        Toggle("Sound", isOn: $soundEnabled)
        Button("Preview Reminder") {
            showReminder(onCheck: {})                // a preview doesn't count
        }
        Divider()
        Button("Quit Rectus") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    @ViewBuilder
    private var idleMenu: some View {
        Picker("Duration", selection: $sessionMinutes) {
            ForEach(Options.sessionMinutes, id: \.self) { minutes in
                Text(sessionLabel(minutes)).tag(minutes)
            }
        }
        Picker("Interval", selection: $intervalMinutes) {
            ForEach(Options.intervalMinutes, id: \.self) { minutes in
                Text(intervalLabel(minutes)).tag(minutes)
            }
        }
        Button("Start") {
            session.start(sessionMinutes: sessionMinutes, intervalMinutes: intervalMinutes)
        }
    }

    private func sessionLabel(_ minutes: Int) -> String {
        switch minutes {
        case 0: "Until stopped"
        case 60: "1 hour"
        default: "\(minutes / 60) hours"
        }
    }

    private func intervalLabel(_ minutes: Int) -> String {
        minutes == ReminderSession.variedInterval ? "Varied (15–30 min)" : "Every \(minutes) min"
    }
}
