import AppKit
import SwiftUI

/// A small reminder box that appears at the top center of the screen for a few seconds.
/// It's our own window, not a system notification: no permission needed, and it still
/// shows in Focus mode.
@MainActor
final class ReminderPanel {
    static let shared = ReminderPanel()

    private var panel: NSPanel?
    private var generation = 0          // bumped on every show(), so an old hide timer can't close a newer box
    private let visibleSeconds = 5.0

    func show(title: String, message: String, playSound: Bool) {
        generation += 1
        let current = generation
        let panel = self.panel ?? makePanel()
        self.panel = panel

        let content = NSHostingView(rootView: ReminderView(title: title, message: message) { [weak self] in
            self?.hide()
        })
        panel.contentView = content
        panel.setContentSize(content.fittingSize)
        moveToTopCenter(panel)

        panel.alphaValue = 0
        panel.orderFrontRegardless()     // show without activating the app, so it doesn't steal focus from where you're typing
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            panel.animator().alphaValue = 1
        }

        if playSound {
            NSSound(named: "Glass")?.play()
        }

        Task { [weak self] in
            try? await Task.sleep(for: .seconds(self?.visibleSeconds ?? 5))
            if self?.generation == current {
                self?.hide()
            }
        }
    }

    func hide() {
        guard let panel else { return }
        let current = generation
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.4
            panel.animator().alphaValue = 0
        }
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(0.4))
            if self?.generation == current {
                panel.orderOut(nil)
            }
        }
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar                     // above normal windows
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isOpaque = false
        panel.backgroundColor = .clear               // SwiftUI draws the rounded corners
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        return panel
    }

    private func moveToTopCenter(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let area = screen.visibleFrame                // screen area minus menu bar and Dock
        let size = panel.frame.size
        panel.setFrameOrigin(NSPoint(x: area.midX - size.width / 2,
                                     y: area.maxY - size.height - 12))
    }
}

/// The contents of the box.
private struct ReminderView: View {
    let title: String
    let message: String
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "figure.stand")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(message).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .onTapGesture(perform: onTap)                 // click to dismiss early
    }
}

/// One is picked at random each time; the same sentence every time soon goes unnoticed.
let postureTips = [
    "Shoulders back, chest open.",
    "Is your screen at eye level?",
    "Lean back against your chair.",
    "Keep both feet on the floor.",
    "Don't push your head forward; tuck your chin slightly.",
]
