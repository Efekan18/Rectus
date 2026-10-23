import AppKit
import SwiftUI

/// Ekranın üst ortasında birkaç saniye görünüp kaybolan küçük hatırlatma kutusu.
/// Sistem bildirimi değil, kendi penceremiz: izin istemez, Odak modunda da görünür.
@MainActor
final class ReminderPanel {
    static let shared = ReminderPanel()

    private var panel: NSPanel?
    private var generation = 0          // her show() bir artırır; eski gizleme işleri yenisini kapatmasın
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
        panel.orderFrontRegardless()     // uygulamayı öne getirmeden göster, yazdığın yerden odağı çalmaz
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
        panel.level = .statusBar                     // normal pencerelerin üstünde
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isOpaque = false
        panel.backgroundColor = .clear               // köşeleri SwiftUI tarafı yuvarlıyor
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        return panel
    }

    private func moveToTopCenter(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let area = screen.visibleFrame                // menü çubuğu ve Dock hariç alan
        let size = panel.frame.size
        panel.setFrameOrigin(NSPoint(x: area.midX - size.width / 2,
                                     y: area.maxY - size.height - 12))
    }
}

/// Kutunun içi.
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
        .onTapGesture(perform: onTap)                 // tıklayınca hemen kapanır
    }
}

/// Her hatırlatmada biri rastgele seçilir; hep aynı cümle bir süre sonra görülmez olur.
let postureTips = [
    "Omuzlar geride, göğüs açık.",
    "Ekran göz hizasında mı?",
    "Sırtını sandalyeye yasla.",
    "Ayaklar yere bassın.",
    "Başını öne uzatma, çeneni hafif geri al.",
]
