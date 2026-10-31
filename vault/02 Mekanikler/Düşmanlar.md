---
tags: [mekanik, denge]
---

# Düşmanlar

Temas hasarı **saniye başına** uygulanır.
- Can: `(1 + dk × 0.28 + dk² × 0.012 + max(0, dk − 5)² × 0.12) × adaptif çarpan`
- Hasar: `1 + dk × 0.08 + max(0, dk − 5)² × 0.03`
- **Adaptif çarpan:** Oyuncunun build gücü (alınan kart seviyeleri toplamı; evrim +4, gelişim kartı +0.5), o ana kadar beklenen güce (`2 + 4.5 × dk`) bölünür. Çarpan `1 + 0.7 × (oran − 1)` olur ve 0.85–1.6 arasında sınırlanır. Güçlü oynayan daha dayanıklı düşmanlarla karşılaşır.

| Düşman | ID | Can | Hız | Hasar/sn | XP | Malzeme | Özellik |
|---|---|---|---|---|---|---|---|
| Poşet Hayaleti | `bag` | 6 | 4.0 | 6 | 1 | Plastik | Hızlı, yalpalayarak uçar |
| Şişe Golemi | `bottle` | 14 | 3.0 | 9 | 2 | Cam | Standart |
| Çürük Yığın | `rot` | 20 | 2.6 | 9 | 2 | Organik | Ölünce 2 küçük yığına bölünür |
| Küçük Yığın | `rot_small` | 6 | 3.6 | 5 | 1 | Organik | |
| Karton Canavar | `box` | 34 | 2.1 | 12 | 3 | Kağıt | Tank, geri itilmeye dirençli |
| Pil Bombası | `battery` | 10 | 5.0 | 22 (tek sefer) | 3 | E-atık | Temas edince patlar, yanıp söner |
| Sprey Kutusu | `spray` | 16 | 3.2 | 8 | 3 | E-atık | **Menzilli**: 6.5–10 birim mesafede durur, yana kayar, 2.4–3.2 sn'de bir zehirli bulut fırlatır (hasar ×1.3) |
| Strafor Sürüsü | `foam` | 5 | 5.4 | 5 | 1 | Plastik | 5'li sürü hâlinde doğar, zikzak çizerek koşar |

## Elit Düşmanlar
- **Planlı:** 1:30'dan başlayarak 75 sn'de bir, o anki düşman havuzundan bir elit doğar (final boss'a kadar ~7 adet). Doğduğunda uyarı yazısı çıkar.
- Can ×12, hasar ×1.5, boyut ×1.45, hız ×1.1, XP ×4, geri itilmeye daha dirençli.
- Altında dönen altın halka ve kıvılcımlar olur. Ölünce **ödül sandığı** düşürür.

## Bosslar
### Çöp Dağı (Trash Mountain), mini boss, 5:00
- Can 1300 × `clamp(build gücü / 24, 0.75, 1.4)`, hız 1.9
- 3.5 sn'de bir etrafına 4 poşet çağırır
- **Faz 2 (%50 altı, öfke):** 4 sn'de bir oyuncunun etrafına 3 uyarılı çöp darbesi (r 2.2, 1.1 sn uyarı, 16 hasar) ve 12 parçalık çöp halkası (hız 7, 10 hasar)
- Ölünce 20 karışık malzeme ve 1 su matarası (can) bırakır

### Aşırı Tüketim Devi (Overconsumption Giant), final boss, 10:00
- Can 14000 × `clamp(build gücü / 62, 0.7, 1.5)`, hız 2.3. Doğduğu andaki build'e göre ayarlanır, hedef ~60–90 sn'lik dövüş.
- **Faz 1 (%100–66):** 6 sn'de bir 0.8 sn kırmızı yanıp sönerek uyarır, ardından oyuncuya doğru **hücum** eder (hız 14, 0.7 sn). 5 sn'de bir 6 minyon çağırır.
- **Faz 2 (%66 altı, "Fatura yağmuru"):** 5.5 sn'de bir art arda 3 dalga, 14'er mermilik dönen fatura halkası (hız 8, 12 hasar)
- **Faz 3 (%33 altı, "Çıldırma"):** ×1.35 hız, daha sık hücum (4.5 sn), 3.6 sn'de bir oyuncuya doğru ilerleyen 5 uyarılı darbe (r 1.9, 20 hasar), fatura halkaları 4.5 sn'de bir
- Faz geçişlerinde ekranda uyarı yazısı ve sarsıntı olur; boss barında %66 ve %33 işaretleri var.
- **Yenilirse oyun kazanılır**

İlgili notlar: [[Dalga Zaman Çizelgesi]]
