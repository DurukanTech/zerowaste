---
tags: [mekanik, ozgun]
---

# Ayrıştırma Kutuları (oyunun özgün katmanı)

Düşmanlar türlerine göre renkli malzeme düşürür. Topladığın her malzeme hem **XP** verir hem de **taşınan** stoka eklenir (her türden en fazla 30).

Aynı renkteki kutunun yanına geldiğinde o türün tamamı otomatik teslim edilir:

| Kutu | Renk | Düşüren düşman | Teslim bonusu |
|---|---|---|---|
| Plastik | 🟨 Sarı | Poşet Hayaleti | **Atış hızı +%30** (cooldown ×0.7) |
| Kağıt | 🟦 Mavi | Karton Canavar | **Hareket hızı +%30** |
| Cam | 🟩 Yeşil | Şişe Golemi | **Hasar +%40** |
| Organik | 🟫 Kahverengi | Çürük Yığın | **Can yenileme** (adet × 2, en fazla 50) |
| E-atık | ⬜ Gri | Pil Bombası | Hiçbir kutuya gitmez, sadece XP verir (mesaj: özel toplama noktası) |

- Buff süresi: `clamp(4 + adet × 0.6, 5, 25)` sn. Çok getiren daha uzun süre güçlenir.
- Bonus XP: `adet × 1.5`
- Teslimattan sonra kutu oyuncudan 18–32 birim uzağa taşınır, bu da oyuncuyu haritada gezmeye iter.
- HUD'da ekran dışındaki kutular için kenarda renkli ok ve taşınan adet gösterilir.
- Her teslimatta o malzemeyle ilgili bir **bilgi notu** çıkar.

## Tasarım Notu
Klasik VS akışı bozulmuyor: Kutuları hiç kullanmayan oyuncu da ilerleyebilir. Ama kullanan oyuncu belirgin şekilde güçlü olur ve böylece "doğru ayrıştırma = güç" mesajı ödüllendirilmiş olur.

İlgili notlar: [[Tema ve Mesaj]], [[Oynanış Döngüsü]]
