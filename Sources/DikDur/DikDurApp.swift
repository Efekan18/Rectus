import SwiftUI

// Not: @State kullanılmıyor. macOS 27 SDK'sında @State bir macro ve onu açan eklenti
// yalnızca Xcode ile geliyor; Command Line Tools ile derlenmiyor. Kalıcı ayarlar
// @AppStorage'da, değişen oturum durumu @Observable ReminderSession'da.

@main
struct DikDurApp: App {
    private let session = ReminderSession()

    init() {
        // Dock'ta ikon gösterme, sadece menü çubuğunda yaşa.
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContent(session: session)
        } label: {
            MenuLabel(session: session)
        }
    }
}

/// Menü çubuğunda görünen kısım: ikon, oturum açıkken yanında geri sayım.
struct MenuLabel: View {
    let session: ReminderSession

    var body: some View {
        Image(systemName: "figure.stand")
        if session.isActive, let left = session.secondsUntilNextReminder {
            Text(formatCountdown(left))
        }
    }
}

/// İkona tıklayınca açılan menü.
struct MenuContent: View {
    let session: ReminderSession

    // UserDefaults'a yazılır: uygulama kapanıp açılınca son seçim hatırlanır.
    @AppStorage("sessionMinutes") private var sessionMinutes = 60
    @AppStorage("intervalMinutes") private var intervalMinutes = 20

    private let sessionOptions = [30, 60, 120, 0]   // 0 = durdurana kadar
    private var intervalOptions: [Int] {
        #if DEBUG
        [1, 10, 15, 20, 30]                          // 1 dk sadece test için
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
        Button("Çıkış") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    @ViewBuilder
    private var idleMenu: some View {
        Picker("Süre", selection: $sessionMinutes) {
            ForEach(sessionOptions, id: \.self) { minutes in
                Text(sessionLabel(minutes)).tag(minutes)
            }
        }
        Picker("Aralık", selection: $intervalMinutes) {
            ForEach(intervalOptions, id: \.self) { minutes in
                Text("\(minutes) dk").tag(minutes)
            }
        }
        Button("Başlat") {
            session.start(sessionMinutes: sessionMinutes, intervalMinutes: intervalMinutes)
        }
    }

    @ViewBuilder
    private var activeMenu: some View {
        if let left = session.secondsUntilNextReminder {
            Text("Sonraki hatırlatma: \(formatCountdown(left))")
        }
        if let left = session.secondsUntilEnd {
            Text("Oturumun bitmesine: \(formatCountdown(left))")
        } else {
            Text("Oturum: durdurana kadar")
        }
        Text("Bu oturumda: \(session.reminderCount) hatırlatma")
        Button("Durdur") {
            session.stop()
        }
    }

    private func sessionLabel(_ minutes: Int) -> String {
        switch minutes {
        case 0: "Durdurana kadar"
        case 60...: "\(minutes / 60) saat"
        default: "\(minutes) dk"
        }
    }
}
