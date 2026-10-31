---
tags: [plan, gorev]
---

# Görev Panosu

## ✅ Planlama
- [x] Tema seçimi: Sıfır Atık
- [x] GDD ve mekanik notları
- [x] Denge tabloları ilk sürüm

## 🧱 Çekirdek
- [x] Godot projesi (Compatibility renderer, input map)
- [x] Oyuncu hareketi + takip kamerası
- [x] Düşman yöneticisi + grid separation
- [x] Spawn zaman çizelgesi
- [x] Malzeme düşürme + mıknatıs toplama
- [x] XP / seviye atlama + 3 kart seçimi

## ⚔️ İçerik
- [x] 6 silah (Cam, Bumerang, Kompost, Türbin, Güneş, Bez Çanta)
- [x] 6 pasif
- [x] 6 düşman türü + 2 boss

## ♻️ Özgün Mekanik
- [x] 4 ayrıştırma kutusu + teslimat
- [x] Bufflar (atış hızı, hız, hasar, can)
- [x] Ekran kenarı yön okları
- [x] Bilgi notları (kart + teslimat + oyun sonu)

## 🎨 Juice
- [x] Prosedürel sesler
- [x] Hasar sayıları, vuruş flaşı, ekran sarsıntısı
- [x] Antalya sahili haritası (palmiye, deniz, binalar)
- [ ] Müzik (opsiyonel; CC0 bir parça eklenebilir)
- [ ] Ölüm partikülleri iyileştirme

## 🧪 Test ve Teslim
- [x] Headless autotest ile tam run (bkz. [[Test ve Autotest]])
- [x] XP eğrisi ve mini boss canı ilk ayarı
- [x] Export ayarları (Web thread'siz + Windows), `game/export_presets.cfg`
- [ ] Editörde insanla tam run testi (10 dk) ×3
- [ ] Denge ayarı ([[Silahlar]], [[Düşmanlar]])
- [ ] Web export + itch.io sayfası
- [ ] Mobil dokunmatik joystick (stretch)
- [ ] Silah evrimleri (stretch)
- [ ] Sunum ([[Sunum ve Teslim]])

## 🐞 Bilinen Sorunlar
- Ekran içindeki kutuların sayı balonu, kutu ekranın üst kenarına yakınsa sol üstteki HUD panelinin altında kalabiliyor.
- Dekor objelerinin (ağaç, bank) çarpışması yok; düşmanlar ve oyuncu içlerinden geçiyor (bilinçli tercih).
- Web build tarayıcıda henüz test edilmedi (export template'leri kurulmalı).
