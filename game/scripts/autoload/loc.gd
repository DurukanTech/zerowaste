extends Node
## Minimal dictionary-based localization (TR / EN).

signal language_changed

var lang := "tr"

const STRINGS := {
	"eyebrow": {"tr": "3D ROGUELITE  •  GERİ DÖNÜŞÜM", "en": "3D ROGUELITE  •  RECYCLING"},
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
	"how_s3": {"tr": "Malzemeyi aynı renkteki kutuya götür, geçici güç kazan. Gri pil (e-atık) hiçbir kutuya gitmez!", "en": "Bring materials to the bin of the same color for a temporary boost. Grey batteries (e-waste) fit no bin!"},
	"how_s4_t": {"tr": "DAYAN", "en": "SURVIVE"},
	"how_s4": {"tr": "5. dakikada Çöp Dağı, 10. dakikada Aşırı Tüketim Devi gelir. Devi yen, parkı kurtar!", "en": "Trash Mountain arrives at minute 5, the Overconsumption Giant at minute 10. Beat the Giant, save the park!"},
	"how_keys": {"tr": "Esc: Duraklat   •   1 / 2 / 3: Kart seç", "en": "Esc: Pause   •   1 / 2 / 3: Pick a card"},
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
	"credits": {"tr": "Godot 4 ile yapıldı • Tüm görseller ve sesler kodla üretildi", "en": "Made with Godot 4 • All visuals and sounds generated in code"},
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
