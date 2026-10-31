---
tags: [mekanik, denge]
---

# Düşmanlar

Temas hasarı **saniye başına** uygulanır. Can, zamanla `×(1 + dk × 0.22)`, hasar da `×(1 + dk × 0.08)` ölçeklenir.

| Düşman | ID | Can | Hız | Hasar/sn | XP | Malzeme | Özellik |
|---|---|---|---|---|---|---|---|
| Poşet Hayaleti | `bag` | 6 | 4.0 | 6 | 1 | Plastik | Hızlı, yalpalayarak uçar |
| Şişe Golemi | `bottle` | 14 | 3.0 | 9 | 2 | Cam | Standart |
| Çürük Yığın | `rot` | 20 | 2.6 | 9 | 2 | Organik | Ölünce 2 küçük yığına bölünür |
| Küçük Yığın | `rot_small` | 6 | 3.6 | 5 | 1 | Organik | |
| Karton Canavar | `box` | 34 | 2.1 | 12 | 3 | Kağıt | Tank, geri itilmeye dirençli |
| Pil Bombası | `battery` | 10 | 5.0 | 22 (tek sefer) | 3 | E-atık | Temas edince patlar, yanıp söner |

## Bosslar
### Çöp Dağı (Trash Mountain), mini boss, 5:00
- Can 750 (900'de autotest 62 sn sürdü, 750'de 43 sn), hız 1.9
- 3.5 sn'de bir etrafına 4 poşet çağırır
- Ölünce 20 karışık malzeme ve 1 su matarası (can) bırakır

### Aşırı Tüketim Devi (Overconsumption Giant), final boss, 10:00
- Can 5000, hız 2.3
- 6 sn'de bir 0.8 sn kırmızı yanıp sönerek uyarır, ardından oyuncuya doğru **hücum** eder (hız 14, 0.7 sn)
- 5 sn'de bir 6 minyon çağırır
- Canı %50'nin altına düşünce daha hızlı hareket eder
- **Yenilirse oyun kazanılır**

İlgili notlar: [[Dalga Zaman Çizelgesi]]
