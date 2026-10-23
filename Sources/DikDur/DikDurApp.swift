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
        // Ses ayarı hiç seçilmemişse açık say (@AppStorage'daki varsayılanla aynı).
        UserDefaults.standard.register(defaults: ["soundEnabled": true])

        session.onReminder = {
            ReminderPanel.shared.show(title: "Dik dur",
                                      message: postureTips.randomElement()!,
                                      playSound: UserDefaults.standard.bool(forKey: "soundEnabled"))
        }
        session.onFinish = {
            ReminderPanel.shared.show(title: "Oturum bitti",
                                      message: "Kalk, biraz esne.",
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

/// Menü çubuğunda görünen kısım: ikon, oturum açıkken yanında kalan dakika.
/// Saniye gösterilmiyor: metnin genişliği her saniye değişince ikon kayıyor ve açık
/// menüyü de kaydırıyordu. Dakika en fazla dakikada bir değişir.
struct MenuLabel: View {
    let session: ReminderSession

    var body: some View {
        Image(systemName: "figure.stand")
        if session.isActive, let left = session.secondsUntilNextReminder {
            Text("\(minutesLeft(left)) dk")
                .monospacedDigit()
        }
    }
}

/// İkona tıklayınca açılan menü.
struct MenuContent: View {
    let session: ReminderSession

    // UserDefaults'a yazılır: uygulama kapanıp açılınca son seçim hatırlanır.
    @AppStorage("sessionMinutes") private var sessionMinutes = 60
    @AppStorage("intervalMinutes") private var intervalMinutes = 20
    @AppStorage("soundEnabled") private var soundEnabled = true

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
        Toggle("Ses", isOn: $soundEnabled)
        Button("Hatırlatmayı önizle") {
            session.onReminder()
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

    // Menünün içinde geri sayım değil sabit saat var: menü açıkken satırlar her saniye
    // değişirse macOS menüyü yeniden kuruyor ve fare başka bir satıra kayıyordu.
    @ViewBuilder
    private var activeMenu: some View {
        if let next = session.nextReminder {
            Text("Sonraki hatırlatma: \(clockTime(next))")
        }
        if let end = session.endDate {
            Text("Oturum bitişi: \(clockTime(end))")
        } else {
            Text("Oturum: durdurana kadar")
        }
        Text("Bu oturumda: \(session.reminderCount) hatırlatma")
        Button("Durdur") {
            session.stop()
        }
    }

    /// 14:35 gibi saat:dakika.
    private func clockTime(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    private func sessionLabel(_ minutes: Int) -> String {
        switch minutes {
        case 0: "Durdurana kadar"
        case 60...: "\(minutes / 60) saat"
        default: "\(minutes) dk"
        }
    }
}
