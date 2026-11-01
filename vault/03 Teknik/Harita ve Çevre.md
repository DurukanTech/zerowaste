---
tags: [teknik, gorsel]
---

# Harita ve Çevre

Oyun alanı Antalya sahilinde bir park: x ±78, z −78…58. Güneyde kum ve deniz var, kuzeyde evler, doğuda ve batıda çam sıraları, arka sırtta rüzgar türbinleri. Kod: `world_builder.gd` (zemin, shader'lar, genel dekor) ve `world_zones.gd` (temalı bölgeler).

## Bölgeler
| Bölge | Konum | İçerik |
|---|---|---|
| Çeşme meydanı | merkez (0, −10), r 13 | Dairesel taş döşeme, 4 saksı, 4 bank |
| Topluluk bostanı | KB (−70…−24, −72…−34) | Malç zemin, 16 sebze yatağı (marul, domates, kabak, havuç, çiçek), 3 kompost kutusu, yağmur suyu varilleri, sera, korkuluk, alet kulübesi, kapılı çit |
| Pazar meydanı | KD (24…70, −72…−34) | Parke zemin, tenteli 5 tezgah, şemsiyeli kafe masaları, renkli **geri dönüşüm istasyonu**, bisiklet parkı, dondurmacı, ışık zinciri |
| Gölet | B (−46, 8) | Elips su, kıyı kayaları, sazlıklar, nilüferler, ahşap iskele, ördekler |
| Spor sahası + oyun parkı | D (24…70, −6…30) | Çizgili basketbol sahası ve potalar, kauçuk zemin, kaydırak, salıncak, tahterevalli, kum havuzu |
| Promenat | G (z ≈ 50.5) | Ahşap tahta yol, ip korkuluk, denize bakan banklar; kumda cankurtaran kulesi, voleybol filesi |
| Sınır | x = ±79.6, z = −79.6 | Her 30 m'de bir boşluk bırakılmış budanmış çit sıraları |

Bölgelerin arası çimen. Burada ağaç, çalı, kaya, çiçeklik, bank ve **geri dönüşüm + genel atık kovası** çiftleri rastgele dağılıyor (140 deneme, bölgelere düşenler atlanıyor).

## Zemin shader'ları (`world_builder.gd`)
- Ortak kütüphane `LIB`: değer gürültüsü, yuvarlak benek (`dots`) ve **kayan bulut gölgeleri** (`clouds`). Tüm zeminlerde %17 karartma uygulanıyor.
- **Çim:**
  - 3 ölçekli ton, yonca öbekleri, minik beyaz/sarı çiçekler
  - Toprak/çakıl yol ağı: 28 segment, uniform dizi olarak veriliyor (`world_zones.path_segments()`)
  - Yolların dalgalı kenarı ve aşınmış çim halesi
- **Diğer zeminler:** Parke (kenar şeridi), dairesel meydan, malç/kauçuk (genel zemin), basketbol sahası, ahşap tahta, kum (deniz kabukları), gölet, deniz.

## Ortam canlıları (`ambient.gd`)
Her tür tek bir MultiMesh ve kare başına sadece birkaç düzine dönüşüm (transform) güncelleniyor:
- 26 kelebek (5 renk): bostan, meydan, gölet ve çimen alanlarında kanat çırpıyor.
- 6 martı: sahilin üstünde süzülüyor.
- 3 ördek: gölette yüzüyor.

## Toplu çizim
- Dekor, 40 m'lik bölgeler halinde birleştirilmiş mesh'ler; her bölge tek draw call.
- Çim öbekleri (4500) ve kır çiçekleri (2600, düşük poligonlu) birer MultiMesh.

| | Overhaul öncesi | Sonrası |
|---|---|---|
| Draw call (oyun başı) | ~300 | 250–325 |
| Üçgen (oyun başı) | ~0.4–0.6 M | 0.45–0.48 M |

> [!note] İlk denemede kır çiçeklerinin başları küreydi ve üçgen sayısı 0.9 M'ye çıkmıştı. Başları düşük poligonlu şekillerle değiştirince sayı tekrar 0.48 M'ye indi.

## Test
`--tour` modu düşman doğurmaz. Oyuncuyu haritadaki 8 noktaya sırayla ışınlar ve `tour_0..7.png` ekran görüntülerini kaydeder:

```powershell
& $g --fixed-fps 60 --path game res://scenes/game.tscn -- --autotest --tour --shots=C:/klasor
```

İlgili notlar: [[Mimari]]
