---
tags: [teknik]
---

# Teknik Mimari

## Genel
- **Godot 4.7.2**, GDScript, **GL Compatibility** renderer (Web export'ta en geniş uyumluluk için)
- Harici asset yok: Tüm mesh'ler primitive (Box/Sphere/Cylinder/Capsule/Torus/Prism), zemin ve deniz için küçük shader'lar
- **Sesler** çalışma anında kodla üretiliyor (`AudioStreamWAV`, sine/square/noise), yani dosya bağımlılığı yok
- Neredeyse her şey koddan kuruluyor; `.tscn` dosyaları sadece birer kök node

## Klasör Yapısı (`game/`)
```
project.godot
scenes/        main_menu.tscn, game.tscn
scripts/
  autoload/    loc.gd (TR/EN), game_data.gd (tüm veri + input map), sfx.gd
  game.gd      dünya, spawn, düşman yöneticisi, malzemeler, kutular, akış
  player.gd    hareket, statlar, XP, bufflar
  enemy.gd     düşman verisi + görsel + boss davranışı
  gem.gd       malzeme pickup
  recycle_bin.gd
  mesh_factory.gd  mesh/material cache
  weapons/     weapon.gd (base) + 6 silah
  ui/          ui_kit.gd, hud.gd, level_up.gd, pause_menu.gd, end_screen.gd
```

## Performans Kararları
- Düşmanlar **CharacterBody değil**, düz `Node3D`. Hepsi tek bir döngüde `game.gd` içinden güncelleniyor.
- **Uzamsal grid** (hücre = 2 birim): Ayrıştırma (separation) ve silah sorguları sadece komşu hücrelere bakıyor. Bosslar grid dışında tutulup ayrıca kontrol ediliyor.
- Mesh ve material'lar `mesh_factory.gd` içinde cache'leniyor ve paylaşılıyor.
- Ekranda en fazla 320 düşman, 400 malzeme var. Sınır aşılırsa en eski malzeme otomatik toplanıyor.
- Hasar sayıları 30'luk bir havuzdan (`Label3D`) dönüşümlü kullanılıyor.

## Duraklatma
`get_tree().paused`; UI katmanları ve `Sfx` için `PROCESS_MODE_ALWAYS`.

## Yerelleştirme
Basit sözlük tabanlı `Loc.t(key)` ve veri içi `{"tr":..,"en":..}` + `Loc.pick(dict)`. Dil değişince `language_changed` sinyali yayılıyor.

İlgili notlar: [[Görev Panosu]]
