extends Node
## Minimal dictionary-based localization (TR / EN).

signal language_changed

var lang := "tr"


func _ready() -> void:
	# test hook: `-- --lang=en` starts in English
	if OS.get_cmdline_user_args().has("--lang=en"):
		lang = "en"

const STRINGS := {
	"title_1": {"tr": "SIFIR ATIK", "en": "ZERO WASTE"},
	"title_2": {"tr": "SAVAŞÇISI", "en": "WARRIOR"},
	"tagline": {"tr": "Atıkları topla, doğru kutuya at, aşırı tüketimi durdur!", "en": "Collect the waste, sort it right, stop overconsumption!"},
	"play": {"tr": "OYNA", "en": "PLAY"},
	"how_to": {"tr": "NASIL OYNANIR", "en": "HOW TO PLAY"},
	"language": {"tr": "DİL: TÜRKÇE", "en": "LANGUAGE: ENGLISH"},
	"quit": {"tr": "ÇIKIŞ", "en": "QUIT"},
	"back": {"tr": "GERİ", "en": "BACK"},
	"enter_hint": {"tr": "Enter ile hemen başla", "en": "Press Enter to start"},
	"sort_title": {"tr": "AYRIŞTIR, GÜÇLEN", "en": "SORT IT, POWER UP"},
	"perk_firerate": {"tr": "Atış hızı", "en": "Fire rate"},
	"perk_speed": {"tr": "Hareket hızı", "en": "Move speed"},
	"perk_damage": {"tr": "Hasar", "en": "Damage"},
	"perk_heal": {"tr": "Can", "en": "Health"},
	"how_s1_t": {"tr": "HAREKET ET", "en": "MOVE"},
	"how_s1": {"tr": "WASD veya ok tuşları. Saldırıların otomatik, sen sadece nerede duracağını seç.", "en": "WASD or arrow keys. Your attacks are automatic, you only choose where to stand."},
	"how_s2_t": {"tr": "TOPLA", "en": "COLLECT"},
	"how_s2": {"tr": "Atık canavarları renkli malzeme düşürür. Her biri XP verir; seviye atlayınca 3 yükseltmeden birini seç.", "en": "Waste monsters drop colored materials. Each gives XP; on level up pick 1 of 3 upgrades."},
	"how_s3_t": {"tr": "AYRIŞTIR", "en": "SORT"},
	"how_s3": {"tr": "Malzemeyi aynı renkteki kutuya götür, güç kazan. Art arda teslim kombo yapar! Piller (e-atık) yalnızca E-Atık Noktası'na.", "en": "Bring materials to the matching bin for a boost. Chain deposits for a combo! Batteries (e-waste) only go to the E-Waste Point."},
	"how_s4_t": {"tr": "DAYAN", "en": "SURVIVE"},
	"how_s4": {"tr": "Ayrıştırma Patlama barını doldurur. 5. dakikada Çöp Dağı, 10. dakikada Aşırı Tüketim Devi gelir!", "en": "Sorting fills your Blast meter. Trash Mountain arrives at minute 5, the Overconsumption Giant at minute 10!"},
	"how_keys": {"tr": "Shift: Atıl   •   Boşluk: Patlama   •   Esc: Duraklat   •   1/2/3: Kart seç   •   R: Yenile", "en": "Shift: Dash   •   Space: Blast   •   Esc: Pause   •   1/2/3: Pick a card   •   R: Reroll"},
	"level_up": {"tr": "SEVİYE ATLADIN!", "en": "LEVEL UP!"},
	"choose": {"tr": "Bir yükseltme seç (1 / 2 / 3)", "en": "Choose an upgrade (1 / 2 / 3)"},
	"new": {"tr": "YENİ!", "en": "NEW!"},
	"lv": {"tr": "Sv.", "en": "Lv."},
	"weapon": {"tr": "Silah", "en": "Weapon"},
	"passive": {"tr": "Pasif", "en": "Passive"},
	"did_you_know": {"tr": "Biliyor muydun?", "en": "Did you know?"},
	"heal_name": {"tr": "Su Molası", "en": "Water Break"},
	"heal_desc": {"tr": "+30 can yenile", "en": "Restore 30 HP"},
	"paused": {"tr": "DURAKLATILDI", "en": "PAUSED"},
	"resume": {"tr": "DEVAM ET", "en": "RESUME"},
	"main_menu": {"tr": "ANA MENÜ", "en": "MAIN MENU"},
	"retry": {"tr": "TEKRAR OYNA", "en": "PLAY AGAIN"},
	"build": {"tr": "Ekipmanın", "en": "Your build"},
	"victory": {"tr": "ZAFER!", "en": "VICTORY!"},
	"defeat": {"tr": "ATIKLARA YENİLDİN", "en": "BURIED IN WASTE"},
	"win_text": {"tr": "Aşırı Tüketim Devi durduruldu! Park yeniden nefes alıyor.", "en": "The Overconsumption Giant is stopped! The park can breathe again."},
	"lose_text": {"tr": "Bu sefer atıklar kazandı... Ama her doğru ayrıştırma bir adım!", "en": "The waste won this time... but every correct sort is a step forward!"},
	"time": {"tr": "Süre", "en": "Time"},
	"kills": {"tr": "Temizlenen atık", "en": "Waste cleared"},
	"level": {"tr": "Seviye", "en": "Level"},
	"recycled": {"tr": "Doğru ayrıştırılan", "en": "Correctly sorted"},
	"collected": {"tr": "Toplanan malzeme", "en": "Materials collected"},
	"ewaste_collected": {"tr": "Toplanan e-atık", "en": "E-waste collected"},
	"hp": {"tr": "CAN", "en": "HP"},
	"carried": {"tr": "Taşınan", "en": "Carried"},
	"warn_mini": {"tr": "⚠ ÇÖP DAĞI YAKLAŞIYOR!", "en": "⚠ TRASH MOUNTAIN APPROACHES!"},
	"warn_boss": {"tr": "⚠ AŞIRI TÜKETİM DEVİ GELİYOR!", "en": "⚠ THE OVERCONSUMPTION GIANT IS COMING!"},
	"warn_swarm": {"tr": "Poşet fırtınası!", "en": "Plastic bag storm!"},
	"warn_ring": {"tr": "Atık çemberi!", "en": "Ring of waste!"},
	"deposit": {"tr": "{n} {mat} geri dönüştürüldü!", "en": "{n} {mat} recycled!"},
	"buff_firerate": {"tr": "Atış hızı", "en": "Fire rate"},
	"buff_speed": {"tr": "Hız", "en": "Speed"},
	"buff_damage": {"tr": "Hasar", "en": "Damage"},
	"buff_heal": {"tr": "Can yenilendi", "en": "Healed"},
	"bin_hint": {"tr": "Malzemeyi aynı renkteki kutuya götür!", "en": "Bring materials to the matching bin!"},
	"ewaste_hint": {"tr": "Pil = e-atık: kutulara değil, özel toplama noktasına!", "en": "Battery = e-waste: special collection point, not the bins!"},
	"full": {"tr": "DOLU", "en": "FULL"},
	"boss_down": {"tr": "Çöp Dağı yıkıldı!", "en": "Trash Mountain collapsed!"},
	# abilities
	"dash": {"tr": "ATIL", "en": "DASH"},
	"key_space": {"tr": "Boşluk", "en": "Space"},
	"music_vol": {"tr": "MÜZİK", "en": "MUSIC"},
	"sfx_vol": {"tr": "EFEKTLER", "en": "EFFECTS"},
	"ultimate": {"tr": "PATLAMA", "en": "BLAST"},
	"ult_ready": {"tr": "Geri Dönüşüm Patlaması hazır! (Boşluk)", "en": "Recycling Blast ready! (Space)"},
	"revived": {"tr": "İKİNCİ ŞANS!", "en": "SECOND CHANCE!"},
	# sorting
	"combo": {"tr": "KOMBO", "en": "COMBO"},
	"combo_hint": {"tr": "5+ malzemeyle art arda teslim et", "en": "Chain deposits of 5+ materials"},
	"ewaste_point": {"tr": "E-Atık Noktası", "en": "E-Waste Point"},
	"ewaste_open": {"tr": "E-ATIK TOPLAMA NOKTASI AÇILDI!", "en": "E-WASTE COLLECTION POINT OPEN!"},
	"ewaste_done": {"tr": "{n} e-atık güvenle teslim edildi! Büyük ödül!", "en": "{n} e-waste safely delivered! Big reward!"},
	# quests
	"quest": {"tr": "GÖREV", "en": "QUEST"},
	"quest_sort": {"tr": "{n} {mat} ayrıştır", "en": "Sort {n} {mat}"},
	"quest_kills": {"tr": "{n} atık temizle", "en": "Clear {n} waste"},
	"quest_nohit": {"tr": "{n} sn hasar almadan dayan", "en": "Survive {n}s without a hit"},
	"quest_combo": {"tr": "x{n} komboya ulaş", "en": "Reach a x{n} combo"},
	"quest_ewaste": {"tr": "{n} e-atığı noktaya götür", "en": "Deliver {n} e-waste"},
	"quest_done": {"tr": "Görev tamamlandı! Ödül sandığı kazandın.", "en": "Quest complete! You earned a reward crate."},
	"quest_failed": {"tr": "Görev süresi doldu.", "en": "Quest timed out."},
	# map events
	"ev_plastic_rain": {"tr": "PLASTİK YAĞMURU!", "en": "PLASTIC RAIN!"},
	"ev_plastic_rain_hint": {"tr": "Gölgelerden kaç! Düşen plastikler yeni atıklara dönüşüyor.", "en": "Dodge the shadows! Falling plastic turns into new waste."},
	"ev_flood": {"tr": "SEL BASKINI!", "en": "FLASH FLOOD!"},
	"ev_flood_hint": {"tr": "Su birikintileri seni yavaşlatır, uzak dur!", "en": "Puddles slow you down, stay out of them!"},
	"ev_smog": {"tr": "HAVA KİRLİLİĞİ!", "en": "SMOG ALERT!"},
	"ev_smog_hint": {"tr": "Görüş azaldı ve atıklar hızlandı. Dikkatli ol!", "en": "Visibility dropped and waste moves faster. Careful!"},
	# bosses
	"phase_mini": {"tr": "ÇÖP DAĞI ÖFKELENDİ!", "en": "TRASH MOUNTAIN IS ENRAGED!"},
	"phase_2": {"tr": "DEV FATURA YAĞDIRIYOR!", "en": "THE GIANT RAINS BILLS!"},
	"phase_3": {"tr": "DEV ÇILDIRDI!", "en": "THE GIANT GOES BERSERK!"},
	# level up
	"chest_title": {"tr": "ÖDÜL SANDIĞI!", "en": "REWARD CRATE!"},
	"evolution": {"tr": "EVRİM", "en": "EVOLUTION"},
	"evolved": {"tr": "EVRİMLEŞTİ:", "en": "EVOLVED:"},
	"reroll": {"tr": "YENİLE", "en": "REROLL"},
	"slots_full": {"tr": "Yuva dolu", "en": "Slots full"},
	"weapon_mastery": {"tr": "+%18 hasar, -%6 bekleme süresi", "en": "+18% damage, -6% cooldown"},
	"stat_card": {"tr": "GELİŞİM", "en": "BOOST"},
	"elite_spawn": {"tr": "ELİT ATIK GELDİ! Yen, ödül sandığını kap!", "en": "AN ELITE APPEARS! Beat it for a reward crate!"},
	# meta
	"upgrades": {"tr": "GELİŞTİRMELER", "en": "UPGRADES"},
	"points": {"tr": "Geri Dönüşüm Puanı", "en": "Recycling Points"},
	"buy": {"tr": "AL", "en": "BUY"},
	"maxed": {"tr": "MAKS", "en": "MAX"},
	"shop_hint": {"tr": "Her run'da ayrıştırdığın malzeme, temizlediğin atık ve tamamladığın görevler puan kazandırır.", "en": "Every run, sorted materials, cleared waste and finished quests earn points."},
	"refund": {"tr": "SIFIRLA", "en": "REFUND"},
	"earned": {"tr": "Kazanılan puan", "en": "Points earned"},
	"total_points": {"tr": "Toplam", "en": "Total"},
	"best_run": {"tr": "En iyi", "en": "Best"},
}


func t(key: String) -> String:
	var entry = STRINGS.get(key)
	if entry == null:
		return key
	return entry.get(lang, key)


func pick(d) -> String:
	if d is Dictionary:
		return d.get(lang, d.get("en", ""))
	return str(d)


## Locale-aware uppercase: Turkish "i" must become "İ", not "I".
func upper(s: String) -> String:
	if lang == "tr":
		s = s.replace("i", "İ")
	return s.to_upper()


func toggle() -> void:
	lang = "en" if lang == "tr" else "tr"
	language_changed.emit()
