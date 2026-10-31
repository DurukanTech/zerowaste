---
tags: [teknik, ses]
---

# Ses ve Müzik

## Kanallar (bus)
`Master` (hard limiter, −1 dB) ← `Music` (low-pass filtresi) + `SFX` (kompresör: −14 dB eşik, 4:1). Kanallar `scripts/autoload/sfx.gd` içinde oyun açılışında kuruluyor. Müzik ve Efekt ses seviyeleri ana menüdeki ve duraklatma ekranındaki kaydırıcılardan ayarlanıyor ve `Meta` kaydına yazılıyor.

## Efektler (`Sfx`)
Tüm sesler kodla üretiliyor, ses dosyası yok. Palet yumuşak ve organik: marimba ve ahşap tınısı, su damlası, yumuşak çan ve boğuk "tump" sesleri. Tiz frekanslar kısıldı. Seviyeler tek bir yerden, `MIX` tablosundan yönetiliyor: `ses → [taban dB, en kısa aralık, aynı anda en fazla kopya]`. Çağrı noktaları sadece fark (offset) verir.

- **Malzeme toplama:** Art arda topladıkça C majör pentatonik gamda (C4–E5) yükselen bir melodi çalar, 0.6 sn ara verince başa döner. En fazla ~13/sn ve aynı anda 3 kopya.
- **Ses kanalı seçimi:** 18 kanal var. Bir ses kopya sınırına ulaştıysa kendi en eski kopyası yeniden kullanılır, değilse boş bir kanal seçilir. Böylece rastgele bir ses yarıda kesilip tıkırtı yapmaz.
- **Ducking:** Patlama, ultimate, uyarı, seviye atlama, zafer ve yenilgi sesleri müziği kısa süre kısar.

### Eski ve yeni sesler (çalındığı seviyede ölçüm)
| Ses | Eski RMS / 1 kHz üstü enerji | Yeni RMS / 1 kHz üstü enerji |
|---|---|---|
| Malzeme toplama | −40.6 dB / %98 | −39.9 dB / %0.7 |
| Vuruş | −45 dB / %20 | −46 dB / %0.2 |
| Hasar alma | −24 dB / %10 (kare dalga) | −24 dB / %0 |
| Atış (cam) | −43 dB / %92 | −42 dB / %6 |
| Güneş ışını | −30 dB / %34 | −31 dB / %1.7 |
| Uyarı | −17 dB / %4 (kare dalga siren) | −19 dB / %0 (yumuşak gong) |

Sürekli çalan sesler müziğin 11–17 dB altında, önemli olaylar müziğin 5–12 dB üstünde. Sesleri WAV olarak dışarı aktarmak için: `godot --headless --path game --quit-after 2 -- --dumpsfx=C:/klasor`.

## Müzik (`Music` autoload)
- Parça: `game/music/sifiratikmusic.wav`, 32.4 sn'lik döngü, mono, 48 kHz.
  - Orijinal dosya 32 bit "extensible" WAV formatındaydı ve Godot içe aktaramıyordu. 16 bit PCM'e çevrildi.
  - İçe aktarma ayarları: döngü açık (`loop_mode=2`), QOA sıkıştırması açık. Export boyutu 6.2 MB'tan 630 KB'a indi.
- Sahneler arasında kesilmeden çalar (menü + oyun). Taban seviye −9 dB.
- **Duraklatma, seviye kartı, bitiş ekranı:** Oyun duraklatılınca müzik boğuklaşır (low-pass 20 kHz → 900 Hz) ve 5 dB kısılır.
- **Final boss:** Müzik çok yavaşça %5 hızlanır, tonu da biraz yükselir.

İlgili notlar: [[Mimari]]
