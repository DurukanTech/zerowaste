---
tags: [teknik, test]
---

# Test ve Autotest

Oyunda, editör açmadan tam bir run'ı simüle eden bir **autotest** modu var:
- Oyuncu ölümsüz olur.
- Oyuncu en çok malzeme taşıdığı kutuya doğru yürür.
- Seviye kartları rastgele seçilir.
- Her 30 sn'de bir konsola istatistik ve performans satırı basılır.

```powershell
$g = "C:\Users\cimih\Desktop\files\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
# headless, 11 dk oyun süresi
& $g --headless --fixed-fps 60 --path game res://scenes/game.tscn --quit-after 40000 -- --autotest
# pencereli + ekran görüntüleri (20 sn, 95 sn kart önizleme, 160 sn)
& $g --fixed-fps 60 --path game res://scenes/game.tscn -- --autotest --shots=C:/klasor
# ana menü ekran görüntüsü
& $g --path game -- --shots=C:/klasor
```

## Sonuçlar (2026-10-31)
| Ölçüm | Değer |
|---|---|
| Script hatası | Yok |
| 10:00'da seviye | 37–38 |
| Mini boss süresi | 43 sn (can 750) |
| Final boss | 10:55'te öldü → **Zafer** ekranı |
| Oyun mantığı (kare başına, masaüstü) | Ort. 2–6 ms, 300+ düşmanla en kötü ~18 ms (boss doğarken tek seferlik 56 ms) |
| Toplam öldürme | ~7500 |

> [!note] Autotest ölümsüz olduğu için zorluk ölçmez
> Gerçek zorluk, insanlarla yapılan oyun testinde ayarlanmalı ([[Görev Panosu]]).

İlgili notlar: [[Mimari]]
