---
tags: [mekanik, denge, meta]
---

# Kalıcı Gelişim (Meta-progression)

Her run sonunda **Geri Dönüşüm Puanı** kazanılır. Puanlar ana menüdeki **GELİŞTİRMELER** ekranında kalıcı yükseltmelere harcanır. Kayıt `user://save.json` dosyasında tutulur (Web'de tarayıcının IndexedDB'si). Kod: `scripts/autoload/meta.gd` (`Meta` autoload).

## Puan Formülü
`⌊ayrıştırılan / 2⌋ + ⌊öldürme / 50⌋ + seviye + e-atık teslimi × 2 + görev × 10 (+100 zafer)`

Bitiş ekranında kazanılan puan ve toplam gösterilir. Autotest run'ları puan kaydetmez ve satın alınmış yükseltmeleri yok sayar, böylece ölçümler karşılaştırılabilir kalır.

## Yükseltmeler
Fiyat: `taban × (seviye + 1)^1.5`, 5'e yuvarlanır.

| Yükseltme | ID | Etki / seviye | Maks | Taban fiyat |
|---|---|---|---|---|
| Sağlıklı Yaşam | `hp` | +10 maks. can | 5 | 40 |
| Kararlılık | `dmg` | +%5 hasar | 5 | 50 |
| Spor Ayakkabı | `speed` | +%4 hareket hızı | 5 | 40 |
| Eğitim | `xp` | +%6 XP | 5 | 45 |
| Uzun Maşa | `pickup` | +%12 toplama yarıçapı | 3 | 35 |
| Büyük Çuval | `carry` | +5 taşıma kapasitesi | 3 | 35 |
| Çeviklik | `dash` | −%12 atılma bekleme süresi | 3 | 45 |
| Gönüllü Ağı | `ult` | +%15 ultimate dolumu | 3 | 55 |
| Yeniden Düşün | `reroll` | Run başına +1 kart yenileme | 3 | 60 |
| İkinci Şans | `revive` | Bir kez %50 canla dirilme (etraftaki düşmanlar silinir) | 1 | 300 |

Hepsini almak toplam yaklaşık 7300 puan tutar. İyi bir zafer run'ı yaklaşık 1000–1500 puan getirir, yani hepsini açmak 5–7 run sürer. Menüde **SIFIRLA** ile tüm puanlar iade edilir.

İlgili notlar: [[Yetenekler]], [[Pasif Yükseltmeler]]
