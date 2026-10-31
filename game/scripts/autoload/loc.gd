extends Node
## Minimal dictionary-based localization (TR / EN).

signal language_changed

var lang := "tr"

const STRINGS := {
	"title": {"tr": "SIFIR ATIK SAVAŞÇISI", "en": "ZERO WASTE WARRIOR"},
	"subtitle": {"tr": "COP31 Türkiye • Game Hackathon", "en": "COP31 Türkiye • Game Hackathon"},
	"tagline": {"tr": "Atıkları topla, doğru kutuya at, aşırı tüketimi durdur!", "en": "Collect the waste, sort it right, stop overconsumption!"},
	"play": {"tr": "OYNA", "en": "PLAY"},
	"how_to": {"tr": "NASIL OYNANIR", "en": "HOW TO PLAY"},
	"language": {"tr": "DİL: TÜRKÇE", "en": "LANGUAGE: ENGLISH"},
	"quit": {"tr": "ÇIKIŞ", "en": "QUIT"},
	"back": {"tr": "GERİ", "en": "BACK"},
	"how_text": {
		"tr": "• WASD / Ok tuşları ile hareket et. Saldırılar otomatiktir.\n• Atık canavarlarından düşen renkli malzemeleri topla: XP kazanırsın.\n• Seviye atlayınca 3 yükseltmeden birini seç (fare veya 1-2-3).\n• Taşıdığın malzemeyi AYNI RENKTEKİ geri dönüşüm kutusuna götür:\n     SARI Plastik → Atış hızı     MAVİ Kağıt → Hareket hızı\n     YEŞİL Cam → Hasar            KAHVERENGİ Organik → Can\n• Gri e-atık (pil) hiçbir kutuya gitmez: özel toplama noktasına aittir!\n• 10. dakikada gelen Aşırı Tüketim Devi'ni yen. Esc: duraklat.",
		"en": "• Move with WASD / Arrow keys. Attacks are automatic.\n• Collect the colored materials dropped by waste monsters to earn XP.\n• On level up, pick 1 of 3 upgrades (mouse or 1-2-3).\n• Bring carried materials to the recycling bin of the SAME COLOR:\n     YELLOW Plastic → Fire rate     BLUE Paper → Move speed\n     GREEN Glass → Damage           BROWN Organic → Health\n• Grey e-waste (batteries) fits no bin: it belongs at special collection points!\n• Defeat the Overconsumption Giant at minute 10. Esc: pause.",
	},
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
	"credits": {"tr": "Godot 4 ile 48 saatte yapıldı • Tüm görseller ve sesler kodla üretildi", "en": "Made with Godot 4 in 48 hours • All visuals and sounds generated in code"},
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


func toggle() -> void:
	lang = "en" if lang == "tr" else "tr"
	language_changed.emit()
