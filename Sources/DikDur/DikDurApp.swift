import SwiftUI

@main
struct DikDurApp: App {
    init() {
        // Dock'ta ikon gösterme, sadece menü çubuğunda yaşa.
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra("DikDur", systemImage: "figure.stand") {
            Text("DikDur hazır")
            Divider()
            Button("Çıkış") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
