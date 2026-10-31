---
tags: [mekanik]
---

# Oynanış Döngüsü

```mermaid
flowchart LR
  A[Hareket et / kaç] --> B[Silahlar otomatik vurur]
  B --> C[Atık canavarı ölür]
  C --> D[Renkli malzeme düşer]
  D --> E[Topla: XP + taşınan malzeme]
  E --> F{XP doldu mu?}
  F -- Evet --> G[Seviye atla: 3 karttan birini seç]
  G --> A
  F -- Hayır --> H{Doğru kutuya götür?}
  H -- Evet --> I[Bonus XP + geçici güç + bilgi notu]
  I --> A
  H -- Hayır --> A
```

## Mikro Döngü (saniyeler)
Kaç, düşmanlar saldırı menziline girsin, malzemeleri topla.

## Orta Döngü (30–60 sn)
Taşınan malzeme dolmaya başlar (her türden en fazla **30**). Ekrandaki renkli oklar kutuları gösterir. Riskli bir rota çizip **teslim et**, buff al. Kutu, teslimattan sonra başka bir yere taşınır.

## Makro Döngü (10 dk)
Build kurulur: 6 silah, 6 pasif, her biri 5 seviye. 5:00'te mini boss, 10:00'da final boss gelir.

## XP Eğrisi
`gereken = 5 + (sv-1)*8 + (sv-1)^1.9`. Autotest'te 2. dakikada sv 9, 5. dakikada sv 20, 10. dakikada sv 38 çıktı. İlk sürümde (`*6`, `^1.6`) 10. dakikada sv 55'e ulaşılıyordu ve her şey maksimuma çıkıyordu, bu yüzden eğri dikleştirildi.

İlgili notlar: [[Ayrıştırma Kutuları]], [[Dalga Zaman Çizelgesi]]
