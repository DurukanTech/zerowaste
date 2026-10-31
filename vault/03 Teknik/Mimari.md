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
  autoload/meta.gd  kalıcı puan + yükseltmeler (user://save.json)
  game.gd      run kontrolü: spawn, düşman yöneticisi, malzemeler, ultimate, akış
  sorting.gd   kutular, teslim, kombo serisi, E-Atık Noktası
  quests.gd    run içi görevler ve ödül sandıkları
  events.gd    zaman çizelgesi + harita olayları (plastik yağmuru, sel, hava kirliliği)
  hazards.gd   düşman mermileri (havuzlu) ve uyarılı zemin darbeleri
  player.gd    hareket, atılma, ultimate barı, statlar, XP, bufflar, dirilme
  enemy.gd     düşman verisi + görsel + boss davranışı
  gem.gd       malzeme pickup
  recycle_bin.gd
  mesh_factory.gd  mesh/material cache
  model_builder.gd birçok primitive'i vertex-color'lı TEK mesh'e birleştirir (1 draw call)
  enemy_models.gd  düşman/boss modelleri (opaque + alpha + glow katmanları, tür başına cache)
  fx.gd            zemin efekti shader'ı (halka/disk/girdap) + havuzlu partiküller, shockwave, flaş ışığı
  spinner.gd       sürekli dönen node (rüzgar türbini rotorları)
  world_builder.gd Antalya sahili haritası (oyun + menü ortak): çim/parke/kum/deniz shader'ları,
                   40 m'lik chunk'lara birleştirilmiş dekor, MultiMesh çim, ışık + glow ayarları
  menu_backdrop.gd ana menünün canlı 3D arka planı (dönen kamera, kahraman, kutular, canavarlar)
  main_menu.gd     sol menü kolonu, sağda ayrıştırma ve "Biliyor muydun?" kartları, Nasıl Oynanır penceresi
  weapons/     weapon.gd (base, Sv.1-5 + evolve() ile Sv.6) + 8 silah
  ui/          ui_kit.gd (ortak palet, kart, pill, ikon kutusu, menü butonu, pop_in animasyonu),
               icons.gd (kodla çizilen vektör ikonlar: silahlar, pasifler, bufflar),
               bar.gd (yuvarlak bar: yumuşak dolum, hasar "hayalet" izi, parlama),
               hud.gd, level_up.gd, pause_menu.gd, end_screen.gd
```

## Performans Kararları
- Düşmanlar **CharacterBody değil**, düz `Node3D`. Hepsi tek bir döngüde `game.gd` içinden güncelleniyor.
- **Uzamsal grid** (hücre = 2 birim): Ayrıştırma (separation) ve silah sorguları sadece komşu hücrelere bakıyor. Bosslar grid dışında tutulup ayrıca kontrol ediliyor.
- Mesh ve material'lar `mesh_factory.gd` içinde cache'leniyor ve paylaşılıyor.
- **Görsel overhaul:** Her model `ModelBuilder` ile tek mesh'e birleştiriliyor. Normal düşmanlar 1-2 draw call, oyuncu 6 parça (yürüme animasyonu için ayrı uzuvlar), harita dekoru chunk başına tek mesh, çim öbekleri tek MultiMesh.
- **Işık:** Güneş (2 split, yumuşak gölge), soğuk dolgu ışığı, rim'li materyaller, glow (bloom), hafif kontrast/doygunluk.
- **Efektler:** Vuruş kıvılcımları ve ölüm patlamaları havuzlu (sınırsız sayıda node üretmez). Vuruş parlaması boss'ları sürekli beyaz bırakmasın diye 0.16 sn'de bir sınırlı.
- Ekranda en fazla 320 düşman, 400 malzeme var. Sınır aşılırsa en eski malzeme otomatik toplanıyor.
- Hasar sayıları 30'luk bir havuzdan (`Label3D`) dönüşümlü kullanılıyor.

## Duraklatma
`get_tree().paused`; UI katmanları ve `Sfx` için `PROCESS_MODE_ALWAYS`.

## Yerelleştirme
Basit sözlük tabanlı `Loc.t(key)` ve veri içi `{"tr":..,"en":..}` + `Loc.pick(dict)`. Dil değişince `language_changed` sinyali yayılıyor.

> [!warning] Büyük harf
> `String.to_upper()` Türkçe kuralını bilmez ("Biliyor" → "BILIYOR"). Her zaman `Loc.upper()` kullan.

İlgili notlar: [[Görev Panosu]]
