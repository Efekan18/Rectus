import AppKit
import CoreGraphics

/// Notices when you leave the desk: the Mac sleeps, the display sleeps, the screen locks,
/// or the screen saver starts. Reminders only make sense while you're sitting there.
@MainActor
enum AwayDetector {
    static func watch(onAway: @escaping @MainActor () -> Void) {
        let workspace = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.willSleepNotification,
                     NSWorkspace.screensDidSleepNotification,
                     NSWorkspace.sessionDidResignActiveNotification] {   // switched user
            Task {
                for await _ in workspace.notifications(named: name) { onAway() }
            }
        }

        // Screen lock and screen saver are only announced as system-wide "distributed"
        // notifications, under these string names.
        let distributed = DistributedNotificationCenter.default()
        for name in ["com.apple.screenIsLocked", "com.apple.screensaver.didstart"] {
            Task {
                for await _ in distributed.notifications(named: Notification.Name(name)) { onAway() }
            }
        }
    }

    /// Seconds since the last keyboard or mouse input, from anywhere in the system.
    static func idleSeconds() -> TimeInterval {
        let anyInput = CGEventType(rawValue: ~0)!   // kCGAnyInputEventType
        return CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyInput)
    }
}
