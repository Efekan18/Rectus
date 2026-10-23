import SwiftUI

// Note: no @State here. In the macOS 27 SDK @State is a macro whose plugin ships only
// with Xcode, so it doesn't compile with the Command Line Tools alone. Persistent
// settings live in @AppStorage, changing session state in the @Observable ReminderSession.

@main
struct RectusApp: App {
    private let session = ReminderSession()

    init() {
        // No Dock icon; live only in the menu bar.
        NSApplication.shared.setActivationPolicy(.accessory)
        // Treat sound as on if it was never set (matches the @AppStorage default).
        UserDefaults.standard.register(defaults: ["soundEnabled": true])

        session.onReminder = {
            ReminderPanel.shared.show(title: "Sit up straight",
                                      message: postureTips.randomElement()!,
                                      playSound: UserDefaults.standard.bool(forKey: "soundEnabled"))
        }
        session.onFinish = {
            ReminderPanel.shared.show(title: "Session finished",
                                      message: "Get up and stretch a little.",
                                      playSound: UserDefaults.standard.bool(forKey: "soundEnabled"))
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContent(session: session)
        } label: {
            MenuLabel(session: session)
        }
    }
}

/// What shows in the menu bar: the icon, plus minutes left while a session is running.
/// No seconds: when the text width changed every second, the icon shifted and dragged
/// the open menu with it. Minutes change at most once a minute.
struct MenuLabel: View {
    let session: ReminderSession

    var body: some View {
        Image(systemName: "figure.stand")
        if session.isActive, let left = session.secondsUntilNextReminder {
            Text("\(minutesLeft(left)) min")
                .monospacedDigit()
        }
    }
}

/// The menu that opens when you click the icon.
struct MenuContent: View {
    let session: ReminderSession

    // Stored in UserDefaults, so the last choice survives a restart.
    @AppStorage("sessionMinutes") private var sessionMinutes = 60
    @AppStorage("intervalMinutes") private var intervalMinutes = 20
    @AppStorage("soundEnabled") private var soundEnabled = true

    private let sessionOptions = [30, 60, 120, 0]   // 0 = until stopped
    private var intervalOptions: [Int] {
        #if DEBUG
        [1, 10, 15, 20, 30]                          // 1 min is for testing only
        #else
        [10, 15, 20, 30]
        #endif
    }

    var body: some View {
        if session.isActive {
            activeMenu
        } else {
            idleMenu
        }
        Divider()
        Toggle("Sound", isOn: $soundEnabled)
        Button("Preview Reminder") {
            session.onReminder()
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
            ForEach(sessionOptions, id: \.self) { minutes in
                Text(sessionLabel(minutes)).tag(minutes)
            }
        }
        Picker("Interval", selection: $intervalMinutes) {
            ForEach(intervalOptions, id: \.self) { minutes in
                Text("Every \(minutes) min").tag(minutes)
            }
        }
        Button("Start") {
            session.start(sessionMinutes: sessionMinutes, intervalMinutes: intervalMinutes)
        }
    }

    // Fixed clock times instead of a countdown: if rows change every second while the
    // menu is open, macOS rebuilds it and the pointer lands on a different item.
    @ViewBuilder
    private var activeMenu: some View {
        if let next = session.nextReminder {
            Text("Next reminder: \(clockTime(next))")
        }
        if let end = session.endDate {
            Text("Session ends: \(clockTime(end))")
        } else {
            Text("Session: until stopped")
        }
        Text("Reminders so far: \(session.reminderCount)")
        Button("Stop") {
            session.stop()
        }
    }

    /// Hours and minutes, e.g. 14:35 (or 2:35 PM, depending on system settings).
    private func clockTime(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    private func sessionLabel(_ minutes: Int) -> String {
        switch minutes {
        case 0: "Until stopped"
        case 60: "1 hour"
        case 60...: "\(minutes / 60) hours"
        default: "\(minutes) min"
        }
    }
}
