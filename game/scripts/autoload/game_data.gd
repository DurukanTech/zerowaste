extends Node
## All static game data: materials, enemies, weapons, passives, facts.
## Balance tables mirror vault/02 Mekanikler.

const BIN_TYPES := ["plastic", "paper", "glass", "organic"]
const CARRY_CAP := 30
const RUN_TIME := 600.0
# Playable area: park on the Antalya coast, sea to the south (+Z).
const ARENA_X := 78.0
const ARENA_Z_MIN := -78.0
const ARENA_Z_MAX := 58.0

const MATERIALS := {
	"plastic": {"name": {"tr": "Plastik", "en": "Plastic"}, "color": Color(1.0, 0.82, 0.1), "buff": "firerate"},
	"paper": {"name": {"tr": "Kağıt", "en": "Paper"}, "color": Color(0.2, 0.5, 1.0), "buff": "speed"},
	"glass": {"name": {"tr": "Cam", "en": "Glass"}, "color": Color(0.2, 0.8, 0.35), "buff": "damage"},
	"organic": {"name": {"tr": "Organik", "en": "Organic"}, "color": Color(0.6, 0.38, 0.16), "buff": "heal"},
	"ewaste": {"name": {"tr": "E-Atık", "en": "E-Waste"}, "color": Color(0.62, 0.62, 0.68), "buff": ""},
	"heal": {"name": {"tr": "Su", "en": "Water"}, "color": Color(0.4, 0.9, 1.0), "buff": ""},
}

const ENEMIES := {
	"bag": {"name": {"tr": "Poşet Hayaleti", "en": "Bag Ghost"}, "hp": 6.0, "speed": 4.0, "damage": 6.0, "xp": 1, "material": "plastic", "radius": 0.45, "knock": 1.0},
	"bottle": {"name": {"tr": "Şişe Golemi", "en": "Bottle Golem"}, "hp": 14.0, "speed": 3.0, "damage": 9.0, "xp": 2, "material": "glass", "radius": 0.45, "knock": 0.9},
	"rot": {"name": {"tr": "Çürük Yığın", "en": "Rot Heap"}, "hp": 20.0, "speed": 2.6, "damage": 9.0, "xp": 2, "material": "organic", "radius": 0.6, "knock": 0.8},
	"rot_small": {"name": {"tr": "Küçük Yığın", "en": "Small Heap"}, "hp": 6.0, "speed": 3.6, "damage": 5.0, "xp": 1, "material": "organic", "radius": 0.35, "knock": 1.0},
	"box": {"name": {"tr": "Karton Canavar", "en": "Cardboard Brute"}, "hp": 34.0, "speed": 2.1, "damage": 12.0, "xp": 3, "material": "paper", "radius": 0.65, "knock": 0.4},
	"battery": {"name": {"tr": "Pil Bombası", "en": "Battery Bomb"}, "hp": 10.0, "speed": 5.0, "damage": 22.0, "xp": 3, "material": "ewaste", "radius": 0.4, "knock": 1.0},
	"miniboss": {"name": {"tr": "Çöp Dağı", "en": "Trash Mountain"}, "hp": 1800.0, "speed": 1.9, "damage": 25.0, "xp": 0, "material": "mixed", "radius": 1.8, "knock": 0.0},
	"spray": {"name": {"tr": "Sprey Kutusu", "en": "Aerosol Can"}, "hp": 16.0, "speed": 3.2, "damage": 8.0, "xp": 3, "material": "ewaste", "radius": 0.4, "knock": 0.9},
	"foam": {"name": {"tr": "Strafor Sürüsü", "en": "Foam Pack"}, "hp": 5.0, "speed": 5.4, "damage": 5.0, "xp": 1, "material": "plastic", "radius": 0.35, "knock": 1.1},
	"boss": {"name": {"tr": "Aşırı Tüketim Devi", "en": "Overconsumption Giant"}, "hp": 14000.0, "speed": 2.3, "damage": 35.0, "xp": 0, "material": "mixed", "radius": 2.5, "knock": 0.0},
}

const WEAPONS := {
	"glass": {
		"name": {"tr": "Cam Kırığı", "en": "Glass Shards"},
		"desc": {"tr": "En yakın atığa keskin cam kırıkları fırlatır.", "en": "Fires sharp glass shards at the nearest waste."},
		"up": [
			{"tr": "+1 kırık", "en": "+1 shard"},
			{"tr": "Kırıklar 2 düşmanı deler", "en": "Shards pierce 2 enemies"},
			{"tr": "+1 kırık, +%45 hasar", "en": "+1 shard, +45% damage"},
			{"tr": "Çok daha hızlı atış, 3 delme", "en": "Much faster fire, pierce 3"},
		],
		"fact": 1, "color": Color(0.55, 1.0, 0.75),
	},
	"boomerang": {
		"name": {"tr": "Yeniden Kullan Bumerangı", "en": "Reuse Boomerang"},
		"desc": {"tr": "Gider ve geri döner; yolundaki herkesi deler. Yeniden kullanım tekrar tekrar vurur!", "en": "Flies out and comes back, piercing everything. Reuse hits again and again!"},
		"up": [
			{"tr": "+%50 hasar", "en": "+50% damage"},
			{"tr": "+1 bumerang", "en": "+1 boomerang"},
			{"tr": "+%40 hasar, daha uzun menzil", "en": "+40% damage, longer range"},
			{"tr": "+1 bumerang, +%25 hasar", "en": "+1 boomerang, +25% damage"},
		],
		"fact": 12, "color": Color(1.0, 0.55, 0.2),
	},
	"compost": {
		"name": {"tr": "Kompost Halkası", "en": "Compost Ring"},
		"desc": {"tr": "Etrafında atıkları yavaşlatan ve çürüten bir kompost alanı oluşturur.", "en": "Creates a compost field that slows and breaks down nearby waste."},
		"up": [
			{"tr": "Daha geniş alan, +hasar", "en": "Larger area, +damage"},
			{"tr": "Daha geniş alan, daha sık hasar", "en": "Larger area, faster ticks"},
			{"tr": "Daha geniş alan, +hasar", "en": "Larger area, +damage"},
			{"tr": "Çok geniş alan, yüksek hasar", "en": "Huge area, high damage"},
		],
		"fact": 5, "color": Color(0.45, 0.6, 0.2),
	},
	"turbine": {
		"name": {"tr": "Rüzgar Türbini", "en": "Wind Turbine"},
		"desc": {"tr": "Etrafında dönen türbin kanatları atıkları biçer.", "en": "Turbine blades orbit you and slice through waste."},
		"up": [
			{"tr": "+1 kanat", "en": "+1 blade"},
			{"tr": "+%50 hasar", "en": "+50% damage"},
			{"tr": "+1 kanat, daha geniş yörünge", "en": "+1 blade, wider orbit"},
			{"tr": "+1 kanat, +%45 hasar", "en": "+1 blade, +45% damage"},
		],
		"fact": 14, "color": Color(0.95, 0.97, 1.0),
	},
	"solar": {
		"name": {"tr": "Güneş Işını", "en": "Solar Beam"},
		"desc": {"tr": "Gökyüzünden rastgele atıklara güneş ışını indirir.", "en": "Calls down beams of sunlight on random waste."},
		"up": [
			{"tr": "+1 ışın", "en": "+1 beam"},
			{"tr": "+%40 hasar, daha sık", "en": "+40% damage, more often"},
			{"tr": "+1 ışın", "en": "+1 beam"},
			{"tr": "+1 ışın, +%35 hasar, geniş alan", "en": "+1 beam, +35% damage, wider area"},
		],
		"fact": 15, "color": Color(1.0, 0.9, 0.3),
	},
	"tote": {
		"name": {"tr": "Bez Çanta Dalgası", "en": "Tote Bag Wave"},
		"desc": {"tr": "Düzenli aralıklarla atıkları geri iten bir şok dalgası yayar.", "en": "Periodically releases a shockwave that pushes waste back."},
		"up": [
			{"tr": "+hasar, +alan", "en": "+damage, +area"},
			{"tr": "+hasar, +alan, daha sık", "en": "+damage, +area, more often"},
			{"tr": "+hasar, +alan, daha sık", "en": "+damage, +area, more often"},
			{"tr": "Dev dalga", "en": "Giant wave"},
		],
		"fact": 12, "color": Color(0.93, 0.86, 0.7),
	},
	"tree": {
		"name": {"tr": "Fidan Dikici", "en": "Sapling Planter"},
		"desc": {"tr": "Yere fidan diker; fidanlar büyür ve yakındaki atıklara yaprak fırlatır.", "en": "Plants saplings that grow and shoot leaves at nearby waste."},
		"up": [
			{"tr": "+1 fidan", "en": "+1 sapling"},
			{"tr": "+%40 hasar, daha uzun ömür", "en": "+40% damage, longer life"},
			{"tr": "+1 fidan, daha hızlı atış", "en": "+1 sapling, faster fire"},
			{"tr": "+1 fidan, +%35 hasar", "en": "+1 sapling, +35% damage"},
		],
		"fact": 21, "color": Color(0.35, 0.8, 0.3),
	},
	"water": {
		"name": {"tr": "Su Fıskiyesi", "en": "Water Jet"},
		"desc": {"tr": "Baktığın yöne basınçlı su püskürtür; atıkları iter ve hasar verir.", "en": "Sprays pressurized water where you face, pushing and damaging waste."},
		"up": [
			{"tr": "+%35 hasar", "en": "+35% damage"},
			{"tr": "Daha uzun ve geniş püskürtme", "en": "Longer, wider spray"},
			{"tr": "+%35 hasar, daha sık", "en": "+35% damage, more often"},
			{"tr": "Arkaya da püskürtür", "en": "Also sprays backwards"},
		],
		"fact": 22, "color": Color(0.35, 0.75, 1.0),
	},
}

## A max-level weapon plus its partner passive unlocks an evolution card.
const EVOLUTIONS := {
	"glass": {"passive": "efficiency", "name": {"tr": "Cam Fırtınası", "en": "Glass Storm"}, "desc": {"tr": "Her yöne delici cam yağmuru. Cam sonsuz kez dönüşür, fırtına hiç dinmez!", "en": "Piercing glass in every direction. Glass recycles forever, so does the storm!"}},
	"boomerang": {"passive": "bike", "name": {"tr": "Döngüsel Ekonomi", "en": "Circular Economy"}, "desc": {"tr": "Bumeranglar etrafında sonsuz döngüde döner ve hiç geri dönmez.", "en": "Boomerangs circle you in an endless loop and never stop."}},
	"compost": {"passive": "canteen", "name": {"tr": "Canlı Toprak", "en": "Living Soil"}, "desc": {"tr": "Dev kompost alanı; çürüttüğü her atık seni iyileştirir.", "en": "A huge compost field; every bit of waste it breaks down heals you."}},
	"turbine": {"passive": "power", "name": {"tr": "Rüzgar Çiftliği", "en": "Wind Farm"}, "desc": {"tr": "İki halka türbin, ters yönlerde döner.", "en": "Two rings of turbines spinning in opposite directions."}},
	"solar": {"passive": "awareness", "name": {"tr": "Güneş Tarlası", "en": "Solar Farm"}, "desc": {"tr": "Gökyüzünden ışın yağmuru; her ışın yerde yanan bir alan bırakır.", "en": "A rain of beams, each leaving a burning patch of light."}},
	"tote": {"passive": "net", "name": {"tr": "Sıfır Atık Dalgası", "en": "Zero Waste Wave"}, "desc": {"tr": "Dev dalga ekrandaki tüm malzemeleri sana çeker.", "en": "A giant wave that pulls every material on screen to you."}},
	"tree": {"passive": "seeds", "name": {"tr": "Kent Ormanı", "en": "Urban Forest"}, "desc": {"tr": "Fidanlar ulu ağaçlara dönüşür ve yaprak fırtınası estirir.", "en": "Saplings become great trees that unleash leaf storms."}},
	"water": {"passive": "repair", "name": {"tr": "Arıtma Tesisi", "en": "Treatment Plant"}, "desc": {"tr": "Dönen dört fıskiye her yönü arıtır.", "en": "Four rotating jets clean up every direction."}},
}

const EVOLVE_AFTER := 300.0  # evolutions unlock after the miniboss
const MAX_WEAPONS := 6
# elite variants: tougher, bigger, glowing, always drop a reward crate
const ELITE_HP := 7.0
const ELITE_DMG := 1.5
const ELITE_SCALE := 1.45
const MAX_PASSIVES := 6

const PASSIVES := {
	"bike": {"name": {"tr": "Bisiklet", "en": "Bicycle"}, "desc": {"tr": "+%10 hareket hızı", "en": "+10% move speed"}, "fact": 16, "color": Color(0.3, 0.85, 0.95)},
	"canteen": {"name": {"tr": "Matara", "en": "Refillable Bottle"}, "desc": {"tr": "+20 maks. can, +0.3 can/sn", "en": "+20 max HP, +0.3 HP/s"}, "fact": 17, "color": Color(0.4, 0.75, 1.0)},
	"net": {"name": {"tr": "Toplama Ağı", "en": "Collection Net"}, "desc": {"tr": "+%30 toplama yarıçapı", "en": "+30% pickup radius"}, "fact": 18, "color": Color(0.9, 0.9, 0.5)},
	"awareness": {"name": {"tr": "Çevre Bilinci", "en": "Eco Awareness"}, "desc": {"tr": "+%10 XP kazanımı", "en": "+10% XP gain"}, "fact": 11, "color": Color(0.5, 1.0, 0.5)},
	"efficiency": {"name": {"tr": "Enerji Verimliliği", "en": "Energy Efficiency"}, "desc": {"tr": "-%8 bekleme süresi", "en": "-8% cooldowns"}, "fact": 19, "color": Color(1.0, 0.85, 0.3)},
	"power": {"name": {"tr": "Topluluk Gücü", "en": "Community Power"}, "desc": {"tr": "+%10 hasar", "en": "+10% damage"}, "fact": 20, "color": Color(1.0, 0.45, 0.45)},
	"repair": {"name": {"tr": "Tamir Kiti", "en": "Repair Kit"}, "desc": {"tr": "-%7 alınan hasar", "en": "-7% damage taken"}, "fact": 23, "color": Color(0.75, 0.75, 0.82)},
	"seeds": {"name": {"tr": "Tohum Bankası", "en": "Seed Bank"}, "desc": {"tr": "+%10 silah alanı", "en": "+10% weapon area"}, "fact": 24, "color": Color(0.8, 0.65, 0.35)},
}

## Persistent upgrades bought in the main menu with recycling points.
const META := {
	"hp": {"name": {"tr": "Sağlıklı Yaşam", "en": "Healthy Living"}, "desc": {"tr": "+10 maks. can", "en": "+10 max HP"}, "max": 5, "base": 40, "icon": "heart", "color": Color(0.95, 0.35, 0.35)},
	"dmg": {"name": {"tr": "Kararlılık", "en": "Determination"}, "desc": {"tr": "+%5 hasar", "en": "+5% damage"}, "max": 5, "base": 50, "icon": "damage", "color": Color(1.0, 0.55, 0.3)},
	"speed": {"name": {"tr": "Spor Ayakkabı", "en": "Running Shoes"}, "desc": {"tr": "+%4 hareket hızı", "en": "+4% move speed"}, "max": 5, "base": 40, "icon": "speed", "color": Color(0.3, 0.6, 1.0)},
	"xp": {"name": {"tr": "Eğitim", "en": "Education"}, "desc": {"tr": "+%6 XP kazanımı", "en": "+6% XP gain"}, "max": 5, "base": 45, "icon": "awareness", "color": Color(0.5, 1.0, 0.5)},
	"pickup": {"name": {"tr": "Uzun Maşa", "en": "Long Grabber"}, "desc": {"tr": "+%12 toplama yarıçapı", "en": "+12% pickup radius"}, "max": 3, "base": 35, "icon": "net", "color": Color(0.9, 0.9, 0.5)},
	"carry": {"name": {"tr": "Büyük Çuval", "en": "Big Sack"}, "desc": {"tr": "+5 taşıma kapasitesi", "en": "+5 carry capacity"}, "max": 3, "base": 35, "icon": "tote", "color": Color(0.93, 0.86, 0.7)},
	"dash": {"name": {"tr": "Çeviklik", "en": "Agility"}, "desc": {"tr": "-%12 atılma bekleme süresi", "en": "-12% dash cooldown"}, "max": 3, "base": 45, "icon": "bike", "color": Color(0.3, 0.85, 0.95)},
	"ult": {"name": {"tr": "Gönüllü Ağı", "en": "Volunteer Network"}, "desc": {"tr": "+%15 ultimate dolum hızı", "en": "+15% ultimate charge rate"}, "max": 3, "base": 55, "icon": "recycle", "color": Color(0.62, 1.0, 0.7)},
	"reroll": {"name": {"tr": "Yeniden Düşün", "en": "Rethink"}, "desc": {"tr": "Her run'da +1 kart yenileme hakkı", "en": "+1 card reroll per run"}, "max": 3, "base": 60, "icon": "clock", "color": Color(1.0, 0.85, 0.3)},
	"revive": {"name": {"tr": "İkinci Şans", "en": "Second Chance"}, "desc": {"tr": "Bir kez %50 canla dirilirsin", "en": "Revive once with 50% HP"}, "max": 1, "base": 300, "icon": "canteen", "color": Color(0.4, 0.9, 1.0)},
}


static func meta_cost(id: String, level: int) -> int:
	return int(round(META[id].base * pow(level + 1, 1.5) / 5.0) * 5)

const FACTS := [
	{"tr": "Türkiye'de atıklar renklerine göre ayrıştırılır: sarı plastik, mavi kağıt, yeşil cam, gri metal, kahverengi organik.", "en": "In Türkiye, waste is sorted by color: yellow plastic, blue paper, green glass, grey metal, brown organic."},
	{"tr": "Cam, kalitesini kaybetmeden sonsuz kez geri dönüştürülebilir.", "en": "Glass can be recycled endlessly without losing quality."},
	{"tr": "Dünyada plastik atıkların yalnızca yaklaşık %9'u geri dönüştürülüyor (OECD, 2022).", "en": "Only about 9% of the world's plastic waste is recycled (OECD, 2022)."},
	{"tr": "Dünyada üretilen gıdanın yaklaşık üçte biri kaybediliyor ya da israf ediliyor (FAO).", "en": "Roughly one third of all food produced is lost or wasted (FAO)."},
	{"tr": "Gıda israfı, küresel sera gazı emisyonlarının yaklaşık %8-10'undan sorumlu (UNEP, 2021).", "en": "Food waste causes about 8-10% of global greenhouse gas emissions (UNEP, 2021)."},
	{"tr": "Çöplükteki organik atıklar metan üretir. Kompost yapmak onları verimli toprağa dönüştürür.", "en": "Organic waste in landfills releases methane. Composting turns it into fertile soil."},
	{"tr": "Alüminyumu geri dönüştürmek, sıfırdan üretmeye göre yaklaşık %95 daha az enerji harcar.", "en": "Recycling aluminium uses about 95% less energy than making it from scratch."},
	{"tr": "Bir kağıt lifi 5-7 kez geri dönüştürülebilir; bu ağaç, su ve enerji tasarrufu demektir.", "en": "A paper fibre can be recycled 5-7 times, saving trees, water and energy."},
	{"tr": "30 Mart, Türkiye'nin önerisiyle BM tarafından Uluslararası Sıfır Atık Günü ilan edildi.", "en": "At Türkiye's proposal, the UN declared 30 March the International Day of Zero Waste."},
	{"tr": "2022'de dünyada 62 milyon ton e-atık oluştu; yalnızca %22,3'ü belgeli olarak geri dönüştürüldü.", "en": "62 million tonnes of e-waste were generated in 2022; only 22.3% was documented as recycled."},
	{"tr": "Piller ve elektronik atıklar normal çöpe değil, özel toplama noktalarına atılmalıdır.", "en": "Batteries and electronics belong in special collection points, not in regular bins."},
	{"tr": "Sıfır atık sırası: Reddet, Azalt, Yeniden Kullan, Geri Dönüştür, Kompost Yap.", "en": "The zero waste order: Refuse, Reduce, Reuse, Recycle, Rot (compost)."},
	{"tr": "Bez çantayı, matarayı ve kutuları ne kadar çok yeniden kullanırsan çevresel ayak izleri o kadar azalır.", "en": "The more you reuse tote bags, bottles and boxes, the smaller their footprint becomes."},
	{"tr": "Türkiye'de Sıfır Atık Projesi 2017'de başlatıldı.", "en": "Türkiye's Zero Waste Project was launched in 2017."},
	{"tr": "Rüzgar ve güneş, dünyada en hızlı büyüyen elektrik kaynakları arasında.", "en": "Wind and solar are among the fastest-growing sources of electricity worldwide."},
	{"tr": "Dünya'ya yaklaşık 1,5 saatte ulaşan güneş enerjisi, insanlığın bir yıllık enerji tüketimine denk.", "en": "The sunlight reaching Earth in about 1.5 hours equals humanity's energy use for a whole year."},
	{"tr": "Kısa mesafelerde bisiklet ya da yürüyüş, ulaşım kaynaklı karbon ayak izini neredeyse sıfırlar.", "en": "Cycling or walking short distances cuts transport emissions to almost zero."},
	{"tr": "Yeniden doldurulabilir bir matara, yılda yüzlerce tek kullanımlık şişeden tasarruf sağlayabilir.", "en": "A refillable bottle can replace hundreds of single-use bottles a year."},
	{"tr": "Kıyı temizliği gönüllüleri, denize ulaşmadan önce her yıl tonlarca atığı topluyor.", "en": "Coastal clean-up volunteers collect tonnes of waste every year before it reaches the sea."},
	{"tr": "LED ampuller, akkor ampullere göre en az %75 daha az enerji harcar.", "en": "LED bulbs use at least 75% less energy than incandescent bulbs."},
	{"tr": "Sıfır atık; bireyler, belediyeler ve işletmeler birlikte çalıştığında mümkün olur.", "en": "Zero waste works when individuals, municipalities and businesses act together."},
	{"tr": "Kent ağaçları gölge ve buharlaşmayla sokakları serinletir, havayı temizler ve karbon depolar.", "en": "City trees cool streets with shade and evaporation, clean the air and store carbon."},
	{"tr": "Dünyadaki suyun yalnızca yaklaşık %2,5'i tatlı su; her damlası değerli.", "en": "Only about 2.5% of the world's water is fresh water, so every drop counts."},
	{"tr": "Bir eşyayı tamir edip daha uzun kullanmak, yenisinin üretim ayak izini tamamen önler.", "en": "Repairing an item and using it longer avoids the footprint of making a new one."},
	{"tr": "Yerel tohumlar bölgenin iklimine uyumludur ve biyoçeşitliliği korur.", "en": "Local seeds are adapted to the regional climate and protect biodiversity."},
	{"tr": "DSÖ'ye göre hava kirliliği her yıl yaklaşık 7 milyon erken ölüme yol açıyor.", "en": "According to the WHO, air pollution causes about 7 million premature deaths every year."},
	{"tr": "Mikroplastikler artık yağmur suyunda bile ölçülebiliyor; plastik atık rüzgarla çok uzaklara taşınıyor.", "en": "Microplastics can now be measured even in rainwater; plastic waste travels far on the wind."},
	{"tr": "İklim değişikliği, birçok bölgede aşırı yağışları ve taşkın riskini artırıyor (IPCC).", "en": "Climate change is increasing heavy rainfall and flood risk in many regions (IPCC)."},
]

## Facts shown when a material type is deposited.
const MATERIAL_FACTS := {
	"plastic": [2, 0, 12],
	"paper": [7, 0, 13],
	"glass": [1, 0, 12],
	"organic": [3, 4, 5],
	"ewaste": [9, 10],
}


func _ready() -> void:
	_setup_input()


func _setup_input() -> void:
	var map := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"pause": [KEY_ESCAPE, KEY_P],
		"pick_1": [KEY_1, KEY_KP_1],
		"pick_2": [KEY_2, KEY_KP_2],
		"pick_3": [KEY_3, KEY_KP_3],
		"dash": [KEY_SHIFT, KEY_K],
		"ultimate": [KEY_SPACE, KEY_Q],
		"reroll": [KEY_R],
	}
	for action in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
	# Gamepad support
	var pad := {"move_left": [JOY_AXIS_LEFT_X, -1.0], "move_right": [JOY_AXIS_LEFT_X, 1.0], "move_up": [JOY_AXIS_LEFT_Y, -1.0], "move_down": [JOY_AXIS_LEFT_Y, 1.0]}
	for action in pad:
		var jm := InputEventJoypadMotion.new()
		jm.axis = pad[action][0]
		jm.axis_value = pad[action][1]
		InputMap.action_add_event(action, jm)
	for b in [["pause", JOY_BUTTON_START], ["dash", JOY_BUTTON_A], ["ultimate", JOY_BUTTON_Y]]:
		var jb := InputEventJoypadButton.new()
		jb.button_index = b[1]
		InputMap.action_add_event(b[0], jb)


func fact_text(index: int) -> String:
	return Loc.pick(FACTS[clampi(index, 0, FACTS.size() - 1)])


func random_fact() -> String:
	return Loc.pick(FACTS.pick_random())


func material_fact(mat: String) -> String:
	var list: Array = MATERIAL_FACTS.get(mat, [0])
	return fact_text(list.pick_random())
