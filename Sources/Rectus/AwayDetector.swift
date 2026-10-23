import AppKit

/// Notices when the Mac stops being used: it goes to sleep, or the display is off or
/// locked. Reading or watching a video without touching the keyboard is NOT "away":
/// there's deliberately no idle-time check.
@MainActor
final class AwayDetector {
    /// True while the display is asleep or the screen is locked.
    private(set) var screenUnavailable = false

    /// `onSleep` runs when the Mac itself goes to sleep (lid closed, Apple menu → Sleep).
    init(onSleep: @escaping @MainActor () -> Void) {
        let workspace = NSWorkspace.shared.notificationCenter
        listen(workspace, NSWorkspace.willSleepNotification) { onSleep() }
        listen(workspace, NSWorkspace.screensDidSleepNotification) { [weak self] in self?.screenUnavailable = true }
        listen(workspace, NSWorkspace.screensDidWakeNotification) { [weak self] in self?.screenUnavailable = false }

        // Lock and unlock are only announced as system-wide "distributed" notifications.
        let distributed = DistributedNotificationCenter.default()
        listen(distributed, Notification.Name("com.apple.screenIsLocked")) { [weak self] in self?.screenUnavailable = true }
        listen(distributed, Notification.Name("com.apple.screenIsUnlocked")) { [weak self] in self?.screenUnavailable = false }
    }

    private func listen(_ center: NotificationCenter, _ name: Notification.Name,
                        _ handler: @escaping @MainActor () -> Void) {
        Task {
            for await _ in center.notifications(named: name) { handler() }
        }
    }
}
