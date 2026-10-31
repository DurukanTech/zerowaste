---
tags: [mekanik, denge]
---

# Silahlar (8 adet, 5 seviye + evrim)

Başlangıç silahı: **Cam Kırığı**. Aynı anda en fazla **6 silah** taşınır. Tüm hasarlar oyuncunun hasar çarpanıyla, bekleme süreleri cooldown çarpanıyla, yarıçap/menziller de **alan çarpanıyla** (Tohum Bankası) çarpılır. Tablolardaki **E** satırı evrimleşmiş hâldir (seviye 6).

## 1. Cam Kırığı (Glass Shards), `glass`
En yakın düşmana keskin kırık fırlatır.
| Sv | Adet | Hasar | Delme | CD |
|---|---|---|---|---|
| 1 | 1 | 9 | 1 | 0.9 |
| 2 | 2 | 9 | 1 | 0.9 |
| 3 | 2 | 9 | 2 | 0.85 |
| 4 | 3 | 13 | 2 | 0.8 |
| 5 | 3 | 13 | 3 | 0.6 |
| E | 5 | 18 | 5 | 0.45 + her 1.4 sn 14 kırıklık halka |

## 2. Yeniden Kullan Bumerangı (Reuse Boomerang), `boomerang`
Gidip geri döner, yolundaki herkesi deler. *Yeniden kullanım = tekrar tekrar vurur.*
| Sv | Adet | Hasar | Menzil | CD |
|---|---|---|---|---|
| 1 | 1 | 10 | 8 | 1.8 |
| 2 | 1 | 15 | 8.5 | 1.7 |
| 3 | 2 | 15 | 9 | 1.6 |
| 4 | 2 | 21 | 9.5 | 1.5 |
| 5 | 3 | 26 | 10 | 1.3 |
| E | 4 | 30 | 3.2–5.8 | sürekli yörünge, düşman başına 0.3 sn |

## 3. Kompost Halkası (Compost Ring), `compost`
Oyuncunun etrafında sürekli hasar veren ve **yavaşlatan** alan.
| Sv | Yarıçap | Hasar | Tick |
|---|---|---|---|
| 1 | 2.6 | 5 | 0.5 |
| 2 | 3.0 | 7 | 0.5 |
| 3 | 3.4 | 9 | 0.45 |
| 4 | 3.8 | 11 | 0.4 |
| 5 | 4.4 | 14 | 0.35 |
| E | 5.8 | 20 | 0.3, vurulan her düşman 0.35 can (tick başına en fazla 6) |

## 4. Rüzgar Türbini (Wind Turbine), `turbine`
Etrafta dönen kanatlar.
| Sv | Kanat | Hasar | Yarıçap |
|---|---|---|---|
| 1 | 2 | 10 | 3.0 |
| 2 | 3 | 10 | 3.0 |
| 3 | 3 | 15 | 3.2 |
| 4 | 4 | 15 | 3.4 |
| 5 | 5 | 22 | 3.8 |
| E | 6 + 6 | 28 | 3.8 ve 6.3 (ters yönde ikinci halka) |

## 5. Güneş Işını (Solar Beam), `solar`
Rastgele düşmanlara gökten ışın indirir, alan hasarı verir.
| Sv | Işın | Hasar | CD | Alan |
|---|---|---|---|---|
| 1 | 1 | 25 | 2.2 | 1.4 |
| 2 | 2 | 25 | 2.0 | 1.4 |
| 3 | 2 | 35 | 1.8 | 1.6 |
| 4 | 3 | 35 | 1.6 | 1.6 |
| 5 | 4 | 48 | 1.3 | 1.9 |
| E | 6 | 60 | 1.0 | 2.2, yerde 2.6 sn yanan alan (0.4 sn'de 9 hasar) |

## 6. Bez Çanta Dalgası (Tote Bag Wave), `tote`
Periyodik şok dalgası, düşmanları **geri iter**.
| Sv | Yarıçap | Hasar | CD |
|---|---|---|---|
| 1 | 4.5 | 14 | 3.2 |
| 2 | 5 | 18 | 3.0 |
| 3 | 5.5 | 24 | 2.8 |
| 4 | 6 | 30 | 2.5 |
| 5 | 7 | 40 | 2.1 |
| E | 9 | 55 | 1.9, 30 birim içindeki tüm malzemeleri oyuncuya çeker |

## 7. Fidan Dikici (Sapling Planter), `tree`
3.2 sn'de bir oyuncunun 2–4 birim yakınına fidan diker. Fidanlar büyür, menzildeki en yakın atığa yaprak fırlatır ve ömrü bitince solar.
| Sv | Fidan | Yaprak hasarı | Atış aralığı | Ömür | Menzil |
|---|---|---|---|---|---|
| 1 | 1 | 8 | 0.9 | 7 | 7 |
| 2 | 2 | 8 | 0.9 | 7 | 7 |
| 3 | 2 | 11 | 0.9 | 9 | 7.5 |
| 4 | 3 | 11 | 0.7 | 9 | 8 |
| 5 | 4 | 15 | 0.7 | 10 | 8.5 |
| E | 5 ulu ağaç | 20 ×3 yaprak | 0.45 | 12 | 10 |

## 8. Su Fıskiyesi (Water Jet), `water`
Oyuncunun baktığı yöne koni şeklinde su püskürtür (0.15 sn'de bir hasar, geri itme 5).
| Sv | Hasar | Uzunluk | Yarım açı | CD | Süre |
|---|---|---|---|---|---|
| 1 | 6 | 5 | 0.35 | 1.6 | 0.8 |
| 2 | 8 | 5 | 0.35 | 1.6 | 0.8 |
| 3 | 8 | 6.2 | 0.45 | 1.6 | 0.9 |
| 4 | 11 | 6.2 | 0.45 | 1.3 | 0.9 |
| 5 | 11 | 6.5 | 0.45 | 1.3 | 0.9, arkaya da püskürtür |
| E | 15 | 7.5 | 0.42 | sürekli, dönen 4 fıskiye |
## Evrimler
Koşul: silah **Sv.5** + eşleşen pasif (herhangi bir seviye) + oyun süresi **5:00 sonrası** (mini boss'tan sonra). Hazır evrim, seviye atlama ya da ödül sandığı ekranında **her zaman ilk kart** olarak çıkar.

| Silah | + Pasif | Evrim |
|---|---|---|
| Cam Kırığı | Enerji Verimliliği | **Cam Fırtınası** |
| Bumerang | Bisiklet | **Döngüsel Ekonomi** |
| Kompost Halkası | Matara | **Canlı Toprak** |
| Rüzgar Türbini | Topluluk Gücü | **Rüzgar Çiftliği** |
| Güneş Işını | Çevre Bilinci | **Güneş Tarlası** |
| Bez Çanta Dalgası | Toplama Ağı | **Sıfır Atık Dalgası** |
| Fidan Dikici | Tohum Bankası | **Kent Ormanı** |
| Su Fıskiyesi | Tamir Kiti | **Arıtma Tesisi** |

> [!note] Denge
> İlk denemede evrimler 2:00'de geliyordu ve mini boss 4 sn'de ölüyordu. Bu yüzden evrimler 5:00'e kilitlendi.

İlgili notlar: [[Pasif Yükseltmeler]], [[Düşmanlar]]
