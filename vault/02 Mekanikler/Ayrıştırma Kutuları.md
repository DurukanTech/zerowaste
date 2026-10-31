---
tags: [mekanik, ozgun]
---

# Ayrıştırma Kutuları (oyunun özgün katmanı)

Düşmanlar türlerine göre renkli malzeme düşürür. Topladığın her malzeme hem **XP** verir hem de **taşınan** stoka eklenir (her türden en fazla 30; "Büyük Çuval" kalıcı yükseltmesiyle +5/seviye).

Aynı renkteki kutunun yanına geldiğinde o türün tamamı otomatik teslim edilir:

| Kutu | Renk | Düşüren düşman | Teslim bonusu |
|---|---|---|---|
| Plastik | 🟨 Sarı | Poşet Hayaleti | **Atış hızı +%30** (cooldown ×0.7) |
| Kağıt | 🟦 Mavi | Karton Canavar | **Hareket hızı +%30** |
| Cam | 🟩 Yeşil | Şişe Golemi | **Hasar +%40** |
| Organik | 🟫 Kahverengi | Çürük Yığın | **Can yenileme** (adet × 2, en fazla 50) |
| E-atık | ⬜ Gri | Pil Bombası, Sprey Kutusu | Hiçbir kutuya gitmez. Ayrı taşınır (en fazla 20) ve sadece **E-Atık Noktası**na teslim edilir |

- Buff süresi: `clamp(4 + adet × 0.6, 5, 25) × (0.8 + 0.2 × kombo çarpanı)` sn. Çok getiren daha uzun süre güçlenir.
- Bonus XP: `adet × 1.2 × kombo çarpanı`
- Ultimate dolumu: `adet × 1.6 × kombo çarpanı` ([[Yetenekler]])

## Kombo Serisi
- **5 veya daha fazla** malzemeyle yapılan teslimat seriyi başlatır ya da 1 artırır. Pencere 25 sn: bu süre içinde yeni bir 5+ teslimat yapılmazsa seri sıfırlanır.
- Çarpan: `1 + 0.2 × (kombo − 1)`, en fazla kombo 6'da ×2.0.
- HUD'da "KOMBO xN +%" kartı ve kalan süre barı gösterilir.

## E-Atık Noktası
- İlk olarak 1:35'te, sonra 105 sn'de bir oyuncudan 16–26 birim uzakta açılır ve 45 sn açık kalır. Final boss geldikten sonra açılmaz.
- Teslimatta adet başına 4 XP, 4 ultimate dolumu ve 1.5 can verir. 4 veya daha fazla teslimatta **ödül sandığı** da verilir.
- HUD'da turuncu kenar oku ve bir bilgi notu (e-atık istatistiği) gösterilir.
- Teslimattan sonra kutu oyuncudan 18–32 birim uzağa taşınır, bu da oyuncuyu haritada gezmeye iter.
- HUD'da ekran dışındaki kutular için kenarda renkli ok ve taşınan adet gösterilir.
- Her teslimatta o malzemeyle ilgili bir **bilgi notu** çıkar.

## Tasarım Notu
Klasik VS akışı bozulmuyor: Kutuları hiç kullanmayan oyuncu da ilerleyebilir. Ama kullanan oyuncu belirgin şekilde güçlü olur ve böylece "doğru ayrıştırma = güç" mesajı ödüllendirilmiş olur.

İlgili notlar: [[Tema ve Mesaj]], [[Oynanış Döngüsü]]
