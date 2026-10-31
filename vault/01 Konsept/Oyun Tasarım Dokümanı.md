---
tags: [konsept, gdd]
---

# Oyun Tasarım Dokümanı (GDD)

## Tek Cümle (Elevator Pitch)
*"Vampire Survivors'ın bağımlılık yapan döngüsü, ama XP kristallerinin yerine geri dönüştürülebilir malzemeler var ve onları doğru kutuya atmak sana güç veriyor."*

## Hikâye
COP31 öncesi Antalya sahilindeki park, tek kullanımlık tüketimin ürettiği **canlanmış atıklarla** dolup taşmıştır. Sen bir **Sıfır Atık Gönüllüsü**sün. Elinde yeniden kullanılabilir araçlar ve yenilenebilir enerji var. Hedefin 10 dakika dayanıp tüm bunların kaynağı olan **Aşırı Tüketim Devi**'ni durdurmak.

## Çekirdek Sütunlar
1. **Anlaşılır:** Tek tuş takımı (WASD), saldırılar otomatik, 10 saniyede öğrenilir.
2. **Mesaj oynanışın içinde:** Ayrıştırma bir quiz değil; mekaniğin kendisi ([[Ayrıştırma Kutuları]]).
3. **Kısa ve tatmin edici:** 10 dakikalık run, jüri bir oturumda baştan sona oynayabilir.
4. **Kendi başına öğretici:** Her yükseltme kartında ve her teslimatta bir "Biliyor muydun?" bilgisi çıkar ([[Tema ve Mesaj]]).

## Kontroller
| Eylem | Tuş |
|---|---|
| Hareket | WASD / Ok tuşları |
| Saldırı | Otomatik |
| Yükseltme seçimi | Fare veya 1 / 2 / 3 |
| Duraklat | Esc / P |

## Ekranlar
- Ana Menü: Oyna, Nasıl Oynanır, Dil (TR/EN), Çıkış
- Oyun HUD'u: Can, XP, seviye, süre, öldürme sayısı, taşınan malzemeler, aktif bufflar, kutu yön oklarının yanı sıra boss barı
- Seviye Atlama: 3 kart, her birinde bir bilgi notu
- Duraklatma menüsü: Mevcut build, dil, ana menü
- Oyun Sonu: Kazandın/Kaybettin, istatistikler (malzeme türüne göre geri dönüştürülen), rastgele bilgi

## Kazanma / Kaybetme
- **Kazanma:** 10:00'da gelen Aşırı Tüketim Devi'ni yenmek
- **Kaybetme:** Canın 0'a düşerse

## Kapsam Dışı (48 saatte yapılmayacaklar)
- Kalıcı meta-ilerleme ve karakter seçimi
- Online skor tablosu
- Harici 3D model ve müzik (sesler kodla üretiliyor, bkz. [[Mimari]])

İlgili notlar: [[Oynanış Döngüsü]], [[48 Saat Yol Haritası]]
