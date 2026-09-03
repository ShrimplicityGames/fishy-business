class_name GameData

const EARTH_NAMES := ["Guppy Bowl","Shrimp Tank","Betta Boutique","Aquascape Shop","Tropical Fish Store","Fish Breeding Facility","Aquarium Warehouse","Public Aquarium","Commercial Fishery","The Ocean"]
const EARTH_MANAGERS := ["Ima Nota Fish","Shrimothy Bottoms","Betty Betta","Plantony Soprano","Gillbert Salesman","Barry McHatcherson","Forklift Finnegan","Otto Von Tentacle","Rodney Reeler","Gilliam H. Seaworth III"]
const MOON_NAMES := ["Lunar Bait Stand","Crater Crawdad Ranch","Zero-G Eel Rodeo","Alien Fish Market","Lunar Lobster Ranch","Fish Rocket Factory","Moon Bass Pro Shop","Interstellar Fish Exchange","Crater Sea Corporation","The Flopping Moon"]
const MOON_MANAGERS := ["Neil Baitstrong","Crawford McPinchy","Eelon Musk","Glorp Fishman","Clawrence Armstrong","Buzz Lightyearfish","Bass Aldrin","Warren Bubblett","Marina Trenchcoat","Moon Moon"]
const DIFFERENT_NAMES := ["Goldfish Pond","Crayfish Farm","Eel Emporium","Koi Casino","Catfish Factory","The Fish Mall","Industrial Fish Complex","National Aquarium Corporation","The Other Ocean","Earth But Wetter"]
const DIFFERENT_MANAGERS := ["Ima Definitelya Fish","Crayg","Eelectric Larry","Koi Capone","Meowchael Finnegan","Mallory Gills","OSHAsha Banks","Chairman Blub","Other Dave","Moistopher Columbus"]
const BASE_COSTS := [0.0,250.0,4000.0,60000.0,900000.0,15000000.0,250000000.0,5000000000.0,100000000000.0,2500000000000.0]
const BASE_PAYOUTS := [10.0,75.0,600.0,4500.0,35000.0,300000.0,3000000.0,40000000.0,650000000.0,12000000000.0]
const BASE_TIMERS := [1.0,3.0,6.0,12.0,25.0,45.0,75.0,120.0,240.0,480.0]
const MANAGER_COSTS := [1000.0,7500.0,60000.0,450000.0,3500000.0,30000000.0,300000000.0,4000000000.0,65000000000.0,1200000000000.0]
const MILESTONES := [25,50,100,200,300,400,500,750,1000,1500,2000,3000,4000,5000,7500,10000]
const WORLD_IDS := ["earth","moon","different","fish"]
const UPGRADE_OPENERS := ["Executive","Deluxe","Questionably Legal","Patent-Pending","Artisanal","Aggressively Synergized","Boardroom-Approved","Moist","Industrial-Grade","Suspiciously Efficient","Premium","Intern-Calibrated"]
const PROFIT_NOUNS := ["Revenue Bubbles","Cash Current","Profit Pellets","Dividend Diver","Money Barnacles","Coin-Operated Coral","Fiscal Fins","Quarterly Kelp"]
const SPEED_NOUNS := ["Turbo Bubbler","Hurry-Up Current","Espresso Filter","Unionized Stopwatch","Zoomy Gravel","Hyperactive Air Pump","Deadline Eel","Fast-Forward Flakes"]
const UPGRADE_SUBJECTS := ["a caffeinated shrimp accountant","three raccoons in a wetsuit","an unlicensed coral consultant","the night-shift guppy union","a suspiciously damp intern","Professor Bubblesworth","an emotionally available lobster","the Department of Moist Revenue","a tiny executive in a diving bell","an eel with a clipboard","the aquarium's least haunted printer","a committee of judgmental clams","one extremely confident sardine","the emergency kelp task force","a freelance barnacle","an overqualified sea cucumber","the quarterly-report octopus","a goldfish who remembers everything"]
const UPGRADE_VERBS := ["recalibrates","aggressively compliments","laminates","reverse-engineers","politely threatens","puts tiny wheels under","audits","sprinkles motivational glitter on","files paperwork against","teaches jazz hands to","declares eminent domain over","replaces the batteries in","whispers quarterly targets to","duct-tapes a necktie onto","challenges to a dance-off","optimizes the vibes around","certifies the buoyancy of","adds an unnecessary subscription to"]
const UPGRADE_REASONS := ["the bubbles demanded representation","nobody read the warranty","Tuesday was legally declared optional","the board confused synergy with seafood","the spreadsheet achieved sentience","a coupon expired during the meeting","the moon looked judgmental","the break room was out of normal ideas","an audit found too much dry land","the tiny briefcase finally opened","the forecast called for scattered dividends","the office eel said it was fine","the emergency conch would not stop ringing","someone checked the box marked probably","the coral passed a surprise inspection","the shareholders requested more splashing","the printer jammed in a profitable way","common sense was on vacation"]

static func world(id: String) -> Dictionary:
	match id:
		"earth": return _make_world("Earth", EARTH_NAMES, EARTH_MANAGERS, "earth", 1.0, 1.0e9, 1500, Color("163a3a"), Color("45c4c8"))
		"moon": return _make_world("Moon", MOON_NAMES, MOON_MANAGERS, "moon", 1.0e15, 1.0e27, 1000, Color("111b35"), Color("b8a6df"))
		"different": return _make_world("Earth But Different", DIFFERENT_NAMES, DIFFERENT_MANAGERS, "different", 1.0e24, 1.0e45, 750, Color("302846"), Color("b7ce55"))
		"fish":
			return {"id":"fish","name":"FISH","names":["FISH"],"managers":["Ima Nota Fish"],"icon_paths":["res://assets/businesses/fish/01-fish.png"],"manager_paths":["res://assets/managers/fish/01-ima-nota-fish.png"],"costs":[1.0],"payouts":[1.0e12],"timers":[1.0],"manager_costs":[1.0e15],"growth":[1.09],"prestige_scale":1.0e60,"upgrade_count":250,"bg":Color("163a3a"),"accent":Color("ffd447")}
	return {}

static func upgrade(id:String,index:int)->Dictionary:
	var d:=world(id);var count:int=d.names.size();var target:int=index%count;var round:int=index/count;var profit:bool=round%2==0
	var opener:String=UPGRADE_OPENERS[(index+target*3)%UPGRADE_OPENERS.size()]
	var noun_list:Array=PROFIT_NOUNS if profit else SPEED_NOUNS
	var noun:String=noun_list[(round+target)%noun_list.size()]
	var serial:="#%04d"%(index+1)
	var subject:String=UPGRADE_SUBJECTS[index%UPGRADE_SUBJECTS.size()];var verb:String=UPGRADE_VERBS[(index*5+index/UPGRADE_SUBJECTS.size())%UPGRADE_VERBS.size()];var reason:String=UPGRADE_REASONS[(index*11+index/(UPGRADE_SUBJECTS.size()*UPGRADE_VERBS.size()))%UPGRADE_REASONS.size()]
	var description:String
	if profit:description="%s %s %s's revenue stream because %s. Exact result: profit ×2."%[subject.capitalize(),verb,d.names[target],reason]
	else:description="%s %s %s's production cycle because %s. Exact result: speed +10%%."%[subject.capitalize(),verb,d.names[target],reason]
	return {"index":index,"target":target,"icon":d.icon_paths[target],"name":"%s %s %s"%[opener,noun,serial],"description":description,"effect":"PROFIT ×2" if profit else "SPEED +10%","kind":"profit" if profit else "speed"}

static func _make_world(label: String, names: Array, managers: Array, folder: String, scale: float, prestige: float, upgrades: int, bg: Color, accent: Color) -> Dictionary:
	var icons: Array[String] = []
	var portraits: Array[String] = []
	var costs: Array[float] = []
	var payouts: Array[float] = []
	var manager_costs: Array[float] = []
	var growth: Array[float] = []
	for i in names.size():
		var prefix := "%02d" % (i + 1)
		var slug: String = str(names[i]).to_lower().replace(" ","-").replace(".","")
		icons.append("res://assets/businesses/%s/%s-%s.png" % [folder,prefix,slug])
		var manager_slug: String = str(managers[i]).to_lower().replace(" ","-").replace(".","")
		portraits.append("res://assets/managers/%s/%s-%s.png" % [folder,prefix,manager_slug])
		costs.append(BASE_COSTS[i] * scale)
		payouts.append(BASE_PAYOUTS[i] * scale)
		manager_costs.append(MANAGER_COSTS[i] * scale)
		growth.append(1.12 - min(i, 8) * 0.004)
	return {"id":folder,"name":label,"names":names,"managers":managers,"icon_paths":icons,"manager_paths":portraits,"costs":costs,"payouts":payouts,"timers":BASE_TIMERS,"manager_costs":manager_costs,"growth":growth,"prestige_scale":prestige,"upgrade_count":upgrades,"bg":bg,"accent":accent}
