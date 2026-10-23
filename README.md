# DikDur

Mac'in menü çubuğunda duran küçük bir dik durma hatırlatıcısı. Bir oturum başlatırsın;
oturum açık kaldığı sürece seçtiğin aralıklarla ekranın üstünde kısa bir kutu belirir
("Dik dur — omuzlar geride") ve istersen hafif bir ses çalar.

*A tiny macOS menu bar app that reminds you to sit up straight at regular intervals.*

## Özellikler

- Menü çubuğunda ikon; oturum açıkken yanında sıradaki hatırlatmaya kalan dakika
- Oturum süresi: 30 dk, 1 saat, 2 saat ya da durdurana kadar
- Hatırlatma aralığı: 10, 15, 20, 30 dk
- Hatırlatma: ekranın üst ortasında 5 sn görünen kutu + isteğe bağlı ses
- Kutu odağı çalmaz; yazarken klavyen kutuya kaymaz
- Mac uykudan uyanınca biriken hatırlatmalar art arda gelmez, tek seferde gelir
- Son seçilen ayarlar hatırlanır
- Dock'ta görünmez, ~200 KB

## Kurulum

Gereken: macOS 14+, Swift 6 (Xcode ya da yalnızca Command Line Tools: `xcode-select --install`).

```bash
git clone https://github.com/Efekan18/DikDur.git
cd DikDur
./build.sh --install
```

Uygulama `~/Applications/DikDur.app` olarak kurulur ve açılır.
Girişte otomatik açılması için: Sistem Ayarları → Genel → Giriş Öğeleri → DikDur'u ekle.

Geliştirirken `swift run` ile doğrudan çalıştırılabilir; debug sürümde test için 1 dk aralık
seçeneği de vardır.

## Neden sistem bildirimi değil?

Ücretli Apple Developer imzası olmayan (ad-hoc imzalı) uygulamalara macOS bildirim izni
vermiyor. Kendi kutumuz izin gerektirmiyor ve Odak modunda da görünüyor. Dik durma
hatırlatıcısı için istenen davranış da bu.

## Yapı

| Dosya | Görevi |
| --- | --- |
| `Sources/DikDur/DikDurApp.swift` | Giriş noktası, menü çubuğu ikonu ve menü |
| `Sources/DikDur/ReminderSession.swift` | Zamanlama: oturum bitişi, sıradaki hatırlatma |
| `Sources/DikDur/ReminderPanel.swift` | Ekranda beliren kutu + ses |
| `Resources/Info.plist` | Uygulama kimliği; `LSUIElement` ile Dock'ta görünmez |
| `build.sh` | Derle → `.app` paketle → imzala → kur |

## Nasıl yapıldı

Kodu [Claude Code](https://claude.com/claude-code) yazdı. Fikir, ihtiyacın tanımı, yaklaşım
seçimi, test ve günlük kullanım bana ait. Bulduğum bir hata da bu sürece dahil: açık menü
saniyede bir kayıyordu. Her adımın nedeni commit geçmişinde yazılı.

*Code written by Claude Code; idea, requirements, testing and decisions by me.*
