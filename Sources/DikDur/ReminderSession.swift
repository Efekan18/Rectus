import Foundation
import Observation

/// Bir hatırlatma oturumunun zamanlamasını tutar: ne zaman bitecek,
/// sıradaki hatırlatma ne zaman, şimdiye kadar kaç hatırlatma yapıldı.
@MainActor
@Observable
final class ReminderSession {
    private(set) var isActive = false
    private(set) var endDate: Date?          // nil = durdurana kadar
    private(set) var nextReminder: Date?
    private(set) var reminderCount = 0
    private(set) var now = Date()            // her saniye güncellenir, arayüz buna bakar

    private var interval: TimeInterval = 0
    private var ticker: Task<Void, Never>?

    /// Hatırlatma zamanı geldiğinde çağrılır (adım 3'te panel + ses buraya bağlanacak).
    var onReminder: () -> Void = {}
    /// Oturum süresi dolduğunda çağrılır.
    var onFinish: () -> Void = {}

    /// sessionMinutes 0 ise oturum durdurulana kadar sürer.
    func start(sessionMinutes: Int, intervalMinutes: Int, at start: Date = Date()) {
        interval = TimeInterval(intervalMinutes * 60)
        endDate = sessionMinutes > 0 ? start.addingTimeInterval(TimeInterval(sessionMinutes * 60)) : nil
        nextReminder = start.addingTimeInterval(interval)
        reminderCount = 0
        now = start
        isActive = true

        ticker?.cancel()
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                self?.tick()
            }
        }
    }

    func stop() {
        ticker?.cancel()
        ticker = nil
        isActive = false
        endDate = nil
        nextReminder = nil
    }

    /// Her saniye çalışır. Zamanı dışarıdan alabildiği için test edilebilir.
    func tick(at time: Date = Date()) {
        guard isActive else { return }
        now = time

        if let endDate, time >= endDate {
            stop()
            onFinish()
            return
        }

        if let next = nextReminder, time >= next {
            reminderCount += 1
            // Bir sonrakini "şimdi"den say: Mac uykudan uyanınca biriken hatırlatmalar
            // art arda patlamasın, tek bir hatırlatma yeterli.
            nextReminder = time.addingTimeInterval(interval)
            onReminder()
        }
    }

    var secondsUntilNextReminder: TimeInterval? {
        nextReminder.map { $0.timeIntervalSince(now) }
    }

    var secondsUntilEnd: TimeInterval? {
        endDate.map { $0.timeIntervalSince(now) }
    }
}

/// 75 → "1:15", 3725 → "1:02:05"
func formatCountdown(_ seconds: TimeInterval) -> String {
    let total = max(0, Int(seconds.rounded(.up)))
    let h = total / 3600, m = (total % 3600) / 60, s = total % 60
    return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
}
