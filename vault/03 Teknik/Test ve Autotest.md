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
# model galerisi: tüm düşmanlar sabit + 1.7 sn'de tüm silahlar (showcase_16 / showcase_32.png)
& $g --fixed-fps 60 --path game res://scenes/game.tscn -- --autotest --showcase --shots=C:/klasor
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

## Görsel overhaul sonrası, pencereli render (2026-10-31)
| Ölçüm | Değer |
|---|---|
| FPS (V-sync kapalı, 1280×720, bu bilgisayar) | Başta ~220, 3. dk'dan sonra 100–150, en düşük 95 (630. sn) |
| En kalabalık an | 277 düşman + ~390 malzeme, 107 FPS |
| Hata | Yok |

> [!note] Kare hızını en çok etkileyen şey ekrandaki malzeme sayısı (her biri 1 draw call). Gerekirse malzemeler MultiMesh'e taşınabilir.

> [!note] Autotest ölümsüz olduğu için zorluk ölçmez
> Gerçek zorluk, insanlarla yapılan oyun testinde ayarlanmalı ([[Görev Panosu]]).

İlgili notlar: [[Mimari]]
