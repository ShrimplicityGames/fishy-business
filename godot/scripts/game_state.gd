extends Node

signal state_changed
signal toast(message: String)
const SAVE_PATH := "user://fishy_business_save_v2.json"
const OFFLINE_CAP := 28800.0
var current_world := "earth"
var current_page := "businesses"
var purchase_amount := 1
var golden_tickets := 0
var lifetime_cash := 0.0
var manual_taps := 0
var tickets_bought := 0
var upgrade_max_unlocked := false
var worlds: Dictionary = {}
var unlocked := {"earth":true,"moon":false,"different":false,"fish":false}

func _ready()->void:_new_game();load_game()
func _filled(n:int,v:Variant)->Array:
	var a:=[]
	for _i in n:a.append(v)
	return a
func _new_game()->void:
	for id in GameData.WORLD_IDS:
		var n:int=GameData.world(id).names.size()
		worlds[id]={"cash":0.0,"lifetime":0.0,"owned":_filled(n,0),"managers":_filled(n,false),"running":_filled(n,false),"progress":_filled(n,0.0),"gilded":_filled(n,false),"fish":0,"upgrade_level":0,"completed":false}
func _process(delta:float)->void:
	for id in GameData.WORLD_IDS:
		if not unlocked.get(id,false):continue
		var d:=GameData.world(id);var s:Dictionary=worlds[id]
		for i in d.names.size():
			if not s.running[i] or s.owned[i]<=0:continue
			s.progress[i]+=delta*speed_multiplier(id,i)
			if s.progress[i]>=d.timers[i]:
				var cycles:float=floor(float(s.progress[i])/float(d.timers[i]));s.progress[i]=fmod(float(s.progress[i]),float(d.timers[i]));_add_cash(id,payout(id,i)*cycles);s.running[i]=s.managers[i]
func _add_cash(id:String,v:float)->void:worlds[id].cash+=v;worlds[id].lifetime+=v;lifetime_cash+=v
func unit_cost(id:String,i:int,n:int)->float:
	var d:=GameData.world(id)
	if i==0 and n==0:return 0.0
	var base:float=d.costs[i] if d.costs[i]>0 else 4.0
	return base*pow(d.growth[i],max(0,n-(1 if i==0 else 0)))
func bulk_cost(id:String,i:int,amount:int)->float:
	var total:=0.0
	for o in amount:total+=unit_cost(id,i,worlds[id].owned[i]+o)
	return total
func affordable_amount(id:String,i:int,limit:=10000)->int:
	var total:=0.0;var amount:=0
	while amount<limit:
		var next:=unit_cost(id,i,worlds[id].owned[i]+amount)
		if total+next>worlds[id].cash+0.000001:break
		total+=next;amount+=1
	return amount
func selected_amount(id:String,i:int)->int:return affordable_amount(id,i) if purchase_amount==-1 else purchase_amount
func purchase(id:String,i:int)->void:
	var amount:=selected_amount(id,i);var cost:=bulk_cost(id,i,amount)
	if amount<=0 or cost>worlds[id].cash+0.000001:return
	worlds[id].cash=max(0.0,worlds[id].cash-cost);worlds[id].owned[i]+=amount
	if worlds[id].managers[i]:worlds[id].running[i]=true
	_check_completion(id);save_game();state_changed.emit()
func start_business(id:String,i:int)->void:
	if worlds[id].owned[i]<=0 or worlds[id].running[i]:return
	worlds[id].progress[i]=0.0;worlds[id].running[i]=true;manual_taps+=1;state_changed.emit()
func hire_manager(id:String,i:int)->void:
	var d:=GameData.world(id);var cost:float=d.manager_costs[i]
	if worlds[id].managers[i] or worlds[id].cash<cost:return
	worlds[id].cash-=cost;worlds[id].managers[i]=true
	if worlds[id].owned[i]>0:worlds[id].running[i]=true
	toast.emit("%s hired — automated!"%d.managers[i]);save_game();state_changed.emit()
func payout(id:String,i:int)->float:return GameData.world(id).payouts[i]*worlds[id].owned[i]*profit_multiplier(id,i)
func profit_multiplier(id:String,i:int)->float:
	var s:Dictionary=worlds[id];var m:=1.0+float(s.fish)*0.02
	for x in GameData.MILESTONES:
		if s.owned[i]>=x:m*=milestone_multiplier(x)
	if s.gilded[i]:m*=25.0
	return m*pow(2.0,upgrade_effect_count(id,i,true))
func speed_multiplier(id:String,i:int)->float:
	var s:Dictionary=worlds[id];var m:=1.0
	if s.owned[i]>=500:m*=2.0
	if s.owned[i]>=1000:m*=2.0
	if s.owned[i]>=5000:m*=2.0
	return m*pow(1.1,upgrade_effect_count(id,i,false))
func upgrade_effect_count(id:String,i:int,profit:bool)->int:
	var count:int=GameData.world(id).names.size();var level:int=worlds[id].upgrade_level
	if level<=i:return 0
	var targeted:int=((level-1-i)/count)+1
	return (targeted+1)/2 if profit else targeted/2
func milestone_multiplier(x:int)->float:
	var map={25:2.0,50:2.0,100:3.0,200:4.0,300:5.0,400:6.0,500:8.0,750:10.0,1000:12.0,1500:15.0,2000:20.0,3000:25.0,4000:30.0,5000:40.0,7500:50.0,10000:100.0}
	return map.get(x,1.0)
func rate_per_second(id:String)->float:
	var total:=0.0;var d:=GameData.world(id)
	for i in d.names.size():
		if worlds[id].managers[i] and worlds[id].owned[i]>0:total+=payout(id,i)*speed_multiplier(id,i)/d.timers[i]
	return total
func unlock_cost(id:String)->float:return 1.0e15 if id=="moon" else 1.0e24 if id=="different" else INF
func unlock_world(id:String)->void:
	if unlocked.get(id,false):switch_world(id);return
	var source:="earth" if id=="moon" else "moon";var cost:=unlock_cost(id)
	if worlds[source].cash<cost:return
	worlds[source].cash-=cost;unlocked[id]=true;current_world=id;toast.emit("%s unlocked!"%GameData.world(id).name);save_game();state_changed.emit()
func switch_world(id:String)->void:
	if unlocked.get(id,false):current_world=id;current_page="businesses";state_changed.emit()
func set_page(p:String)->void:current_page=p;state_changed.emit()
func set_purchase_amount(v:int)->void:
	purchase_amount=v;state_changed.emit()
func upgrade_max_fish_cost()->int:return 5
func unlock_upgrade_max(id:String)->void:
	var cost:=upgrade_max_fish_cost()
	if upgrade_max_unlocked or worlds[id].fish<cost:return
	worlds[id].fish-=cost;upgrade_max_unlocked=true;toast.emit("Buy Max Upgrades unlocked forever. The fish signed the paperwork.");save_game();state_changed.emit()
func buy_max_upgrades(id:String)->void:
	if not upgrade_max_unlocked:return
	var d:=GameData.world(id);var s:Dictionary=worlds[id];var bought:=0
	while s.upgrade_level<d.upgrade_count:
		var cost:=upgrade_cost(id)
		if s.cash<cost:break
		s.cash-=cost;s.upgrade_level+=1;bought+=1
	if bought>0:toast.emit("Purchased %d upgrades. Maximum paperwork achieved."%bought);save_game();state_changed.emit()
func upgrade_cost_at(id:String,index:int)->float:
	var d:=GameData.world(id);return max(100.0,d.costs[min(1,d.costs.size()-1)])*pow(1.38,index)
func upgrade_cost(id:String)->float:return upgrade_cost_at(id,worlds[id].upgrade_level)
func buy_upgrade(id:String)->void:
	var d:=GameData.world(id);var s:Dictionary=worlds[id]
	if s.upgrade_level>=d.upgrade_count:return
	var cost:=upgrade_cost(id);if s.cash<cost:return
	s.cash-=cost;s.upgrade_level+=1;save_game();state_changed.emit()
func fish_available(id:String)->int:return maxi(0,int(floor(sqrt(worlds[id].lifetime/GameData.world(id).prestige_scale)))-worlds[id].fish)
func prestige(id:String)->void:
	var gain:=fish_available(id);if gain<=0:return
	var s:Dictionary=worlds[id];s.fish+=gain;s.cash=0.0;s.owned=_filled(s.owned.size(),0);s.managers=_filled(s.managers.size(),false);s.running=_filled(s.running.size(),false);s.progress=_filled(s.progress.size(),0.0);s.upgrade_level=0;toast.emit("Reset complete: +%d Fish"%gain);save_game();state_changed.emit()
func ticket_cost(id:String)->float:return max(1.0e12,GameData.world(id).costs[-1]*10.0)*pow(10.0,tickets_bought)
func buy_ticket(id:String)->void:
	var cost:=ticket_cost(id)
	if worlds[id].cash<cost:return
	worlds[id].cash-=cost;golden_tickets+=1;tickets_bought+=1;save_game();state_changed.emit()
func gild(id:String,i:int)->void:
	if golden_tickets<=0 or worlds[id].gilded[i]:return
	golden_tickets-=1;worlds[id].gilded[i]=true;_check_completion(id);save_game();state_changed.emit()
func _check_completion(id:String)->void:
	if id=="fish":return
	var s:Dictionary=worlds[id];var d:=GameData.world(id);var done:bool=s.upgrade_level>=d.upgrade_count
	for i in d.names.size():done=done and s.owned[i]>=10000 and s.gilded[i]
	if done and not s.completed:s.completed=true;toast.emit("%s complete!"%d.name)
	if worlds.earth.completed and worlds.moon.completed and worlds.different.completed:unlocked.fish=true
func completion_percent(id:String)->float:
	if id=="fish":return 0.0
	var s:Dictionary=worlds[id];var d:=GameData.world(id);var points:float=float(s.upgrade_level)/float(d.upgrade_count)
	for i in d.names.size():points+=min(1.0,float(s.owned[i])/10000.0)+(1.0 if s.gilded[i] else 0.0)
	return points/21.0
func save_game()->void:
	var f:=FileAccess.open(SAVE_PATH,FileAccess.WRITE)
	if f:f.store_string(JSON.stringify({"saved_at":Time.get_unix_time_from_system(),"current_world":current_world,"purchase_amount":purchase_amount,"golden_tickets":golden_tickets,"tickets_bought":tickets_bought,"upgrade_max_unlocked":upgrade_max_unlocked,"lifetime_cash":lifetime_cash,"manual_taps":manual_taps,"unlocked":unlocked,"worlds":worlds}))
func load_game()->void:
	if not FileAccess.file_exists(SAVE_PATH):return
	var f:=FileAccess.open(SAVE_PATH,FileAccess.READ);if not f:return
	var d=JSON.parse_string(f.get_as_text());if typeof(d)!=TYPE_DICTIONARY:return
	current_world=str(d.get("current_world","earth"));purchase_amount=int(d.get("purchase_amount",1));golden_tickets=int(d.get("golden_tickets",0));tickets_bought=int(d.get("tickets_bought",0));upgrade_max_unlocked=bool(d.get("upgrade_max_unlocked",false));lifetime_cash=float(d.get("lifetime_cash",0));manual_taps=int(d.get("manual_taps",0));unlocked=d.get("unlocked",unlocked)
	var sw:Dictionary=d.get("worlds",{})
	for id in worlds:
		if sw.has(id):
			for key in worlds[id]:
				if sw[id].has(key):worlds[id][key]=sw[id][key]
	var elapsed:=clampf(Time.get_unix_time_from_system()-float(d.get("saved_at",0.0)),0.0,OFFLINE_CAP);var earned:=0.0
	for id in worlds:
		if not unlocked.get(id,false):continue
		var data:=GameData.world(id)
		for i in data.names.size():
			if worlds[id].managers[i] and worlds[id].owned[i]>0:
				var v:float=floor(elapsed*speed_multiplier(id,i)/float(data.timers[i]))*payout(id,i);_add_cash(id,v);earned+=v;worlds[id].running[i]=true
	if earned>0:toast.emit("Welcome back! Offline earnings: $%s"%format_number(earned))
func format_number(v:float)->String:
	if is_inf(v):return "∞"
	if v<1000:return str(int(floor(v)))
	var suffixes:=["K","M","B","T","Qa","Qi","Sx","Sp","Oc","No","Dc","Ud","Dd","Td","Qad","Qid","Sxd","Spd","Ocd","Nod","Vg"]
	var tier:=clampi(int(floor(log(v)/log(1000.0))),1,suffixes.size())
	return "%.3f%s"%[v/pow(1000.0,tier),suffixes[tier-1]]
