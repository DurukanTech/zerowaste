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
# geç oyun: 6:20'ye atlar; evrim kartı, sel, ultimate, boss faz 2 (late_*.png)
& $g --fixed-fps 60 --path game res://scenes/game.tscn -- --autotest --late --shots=C:/klasor
# ana menü, Nasıl Oynanır ve Geliştirmeler ekranları
& $g --path game -- --shots=C:/klasor
```

Autotest pilotu her 3 sn'de bir atılır, ultimate dolunca hemen kullanır, e-atık taşıyorsa E-Atık Noktası'na yürür. Hazır evrim kartını her zaman seçer. Kalıcı yükseltmeleri yok sayar ve puan kaydetmez. Pilot boss mekaniklerinden kaçmaya çalışmaz; ölümsüz olduğu için zorluğu değil, akışı ve performansı ölçer.

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

## Mekanik overhaul sonrası, headless (2026-10-31)
| Ölçüm | Run A (boss 16000 can) | Run B (boss 11000 can) |
|---|---|---|
| Script hatası | Yok | Yok |
| Mini boss | 5:00'te doğdu, 71 sn'de öldü (can 2400) | 45 sn'de öldü (can 1800) |
| Final boss | 138 sn | 29 sn (güçlü build, 4 evrim) |
| 10:00'da seviye | 40 | 44 |
| Görev / e-atık teslimi | — | 7 / 61 |
| Kazanılan puan | — | 1447 |
| Oyun mantığı | Ort. 1–2.5 ms | Ort. 1–3 ms |

Final boss canı iki run arasında bir değer olarak **14000** yapıldı. Evrimlerin ilk denemede 2:00'de gelmesi üzerine 5:00 kilidi eklendi.

## Zorluk analizi ve düzeltme (2026-10-31)
Autotest her 30 sn'de bir `[balance]` satırı da basar: sandık kaynakları, öldürülen elit sayısı, kart havuzunun boşaldığı an, tek vuruşta ölen düşman oranı ve alınan hasar.

| Ölçüm | Önce | Sonra |
|---|---|---|
| Ödül sandığı (10:00'a kadar) | 89 (81'i elitlerden) | 17 |
| Kart havuzunun boşalması | 7:12 | Hiç (gelişim kartları) |
| 10:00'da seviye | 38 | 32 |
| Tek vuruşta ölen düşman (8–10 dk) | %35–40 | %6–20 |
| 30 sn'de alınan hasar (8–10 dk) | ölçülmedi | 100–400 |
| Mini boss | 45 sn | 41 sn (can 1570, güç 29) |
| Final boss | 29–138 sn | 109–211 sn (pilot bossa saldırmıyor, kutulara yürüyor) |

> [!note] Kare hızını en çok etkileyen şey ekrandaki malzeme sayısı (her biri 1 draw call). Gerekirse malzemeler MultiMesh'e taşınabilir.

> [!note] Autotest ölümsüz olduğu için zorluk ölçmez
> Gerçek zorluk, insanlarla yapılan oyun testinde ayarlanmalı ([[Görev Panosu]]).

İlgili notlar: [[Mimari]]
