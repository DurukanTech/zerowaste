---
tags: [mekanik, denge]
---

# Görevler ve Harita Olayları

## Görevler (`scripts/quests.gd`)
- İlk görev 1:00'de gelir. Her görevden 32 sn sonra yenisi başlar. Son 15 sn'de görev çıkmaz.
- Aynı tür art arda gelmez. HUD'da sağ üstte başlık, ilerleme barı ve kalan süre gösterilir.
- **Ödül:** Ödül sandığı (seviye atlamadan ekstra kart seçimi) ve +25 ultimate dolumu. Süre dolarsa ceza yoktur.

| Tür | Hedef | Süre |
|---|---|---|
| `sort` | Rastgele bir malzemeden `10 + dk × 2.5` adet ayrıştır | 75 sn |
| `kills` | `50 + dk × 45` atık temizle (10'a yuvarlanır) | 40 sn |
| `nohit` | 20 sn hasar almadan dayan (hasar alınca sayaç sıfırlanır) | 60 sn |
| `combo` | x3 komboya ulaş | 100 sn |
| `ewaste` | E-Atık Noktası'na 4 e-atık götür (sadece nokta açıkken, 2 kat olasılıkla) | noktanın kalan süresi |

## Harita Olayları (`scripts/events.gd`)
Her olay bir uyarı yazısı ve iklimle ilgili bir bilgi notuyla başlar.

| Olay | Zaman | Süre | Etki | Bilgi notu |
|---|---|---|---|---|
| **Plastik Yağmuru** | 3:35 | 18 sn | 0.45 sn'de bir oyuncunun 10 birim çevresine uyarılı darbe düşer (r 1.5, 10 hasar). Düşen plastik %40 ihtimalle poşet canavarına, %60 ihtimalle plastik malzemeye dönüşür. | Yağmur suyunda mikroplastik |
| **Sel Baskını** | 6:25 | 30 sn | Oyuncunun 3–11 birim çevresinde 7 su birikintisi oluşur. İçlerinde oyuncu %45 yavaşlar. | Aşırı yağış ve taşkın riski (IPCC) |
| **Hava Kirliliği** | 8:35 | 24 sn | Sis yoğunlaşır, renkler soluklaşır, ekran grileşir. Düşmanlar %25 hızlanır. | Hava kirliliği, DSÖ |

Uyarılı darbeler ve düşman mermileri `scripts/hazards.gd` içinde havuzlanıyor (90 mermi). Atılma (dash) sırasında hasar alınmaz.

İlgili notlar: [[Dalga Zaman Çizelgesi]], [[Yetenekler]]
