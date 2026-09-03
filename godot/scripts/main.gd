extends Control

const PAPER:=Color("f4f0e6");const INK:=Color("102f31");const GOLD:=Color("e7b84b");const MINT:=Color("71d69e");const AQUA:=Color("45c4c8");const CORAL:=Color("f0805a");const MUTED:=Color("afc8c5");const LOCKED:=Color("687c7a")
var page_root:VBoxContainer;var header_cash:Label;var header_rate:Label;var world_button:Button;var ticket_label:Label;var toast_label:Label;var active_scroll:ScrollContainer;var progress_bars:Dictionary={};var run_buttons:Dictionary={};var nav_buttons:Dictionary={};var cash_buttons:Array=[];var rebuilding:=false;var upgrade_page_start:=0

func _ready()->void:
	GameState.state_changed.connect(_queue_rebuild);GameState.toast.connect(_show_toast);_build_shell();_rebuild_page()
func box(color:Color,r:=12,border_color:=Color.TRANSPARENT,border:=0)->StyleBoxFlat:
	var s:=StyleBoxFlat.new();s.bg_color=color;s.corner_radius_top_left=r;s.corner_radius_top_right=r;s.corner_radius_bottom_left=r;s.corner_radius_bottom_right=r;s.border_width_left=border;s.border_width_top=border;s.border_width_right=border;s.border_width_bottom=border;s.border_color=border_color;s.content_margin_left=10;s.content_margin_right=10;s.content_margin_top=8;s.content_margin_bottom=8;return s
func label(text:String,size:int,color:=INK)->Label:
	var l:=Label.new();l.text=text;l.set_meta("fit_base_size",size);l.add_theme_font_size_override("font_size",size);l.add_theme_color_override("font_color",color);l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;return l
func button(text:String,color:Color,call:Callable,min_h:=46)->Button:
	var b:=Button.new();b.text=text;b.set_meta("fit_base_size",15);b.custom_minimum_size.y=min_h;b.add_theme_font_size_override("font_size",15);b.add_theme_color_override("font_color",INK);_style_button_color(b,color);b.pressed.connect(call);return b
func _style_button_color(b:Button,color:Color)->void:
	b.add_theme_stylebox_override("normal",box(color,9,INK,2));b.add_theme_stylebox_override("hover",box(color.lightened(.08),9,INK,2));b.add_theme_stylebox_override("pressed",box(color.darkened(.12),9,INK,2))
func panel(color:Color)->PanelContainer:
	var p:=PanelContainer.new();p.add_theme_stylebox_override("panel",box(color,12,INK,2));return p
func _build_shell()->void:
	var bg:=ColorRect.new();bg.color=GameData.world(GameState.current_world).bg;bg.name="Background";bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(bg)
	var safe:=MarginContainer.new();safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);safe.add_theme_constant_override("margin_left",8);safe.add_theme_constant_override("margin_right",8);safe.add_theme_constant_override("margin_top",18);safe.add_theme_constant_override("margin_bottom",8);add_child(safe)
	var layout:=VBoxContainer.new();layout.add_theme_constant_override("separation",7);safe.add_child(layout)
	var top:=HBoxContainer.new();top.add_theme_constant_override("separation",7);layout.add_child(top)
	world_button=button("WORLD\nEARTH",AQUA,_show_world_menu,72);world_button.custom_minimum_size.x=94;top.add_child(world_button)
	var money:=panel(PAPER);money.size_flags_horizontal=Control.SIZE_EXPAND_FILL;top.add_child(money);var money_v:=VBoxContainer.new();money.add_child(money_v);header_cash=label("$0",33,INK);money_v.add_child(header_cash);header_rate=label("$0 / SEC",14,Color("1d7773"));money_v.add_child(header_rate)
	var ticket:=panel(Color("fff0c7"));ticket.custom_minimum_size.x=92;top.add_child(ticket);var tv:=VBoxContainer.new();ticket.add_child(tv);tv.add_child(label("GOLDEN\nTICKETS",10,INK));ticket_label=label("0",24,INK);ticket_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;tv.add_child(ticket_label)
	toast_label=label("",13,PAPER);toast_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;toast_label.custom_minimum_size.y=18;layout.add_child(toast_label)
	var page_holder:=PanelContainer.new();page_holder.size_flags_vertical=Control.SIZE_EXPAND_FILL;page_holder.add_theme_stylebox_override("panel",box(Color("f7efd9"),12,INK,2));layout.add_child(page_holder);page_root=VBoxContainer.new();page_root.add_theme_constant_override("separation",6);page_holder.add_child(page_root)
	var nav:=HBoxContainer.new();nav.add_theme_constant_override("separation",3);layout.add_child(nav)
	for entry in [["BUSINESS","businesses"],["MANAGERS","managers"],["UPGRADES","upgrades"],["FISH","fish"],["STATS","stats"],["MORE","more"]]:
		var b:=button(entry[0],GOLD if GameState.current_page==entry[1] else PAPER,func():GameState.set_page(entry[1]),55);b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.set_meta("fit_base_size",10);b.add_theme_font_size_override("font_size",10);nav.add_child(b);nav_buttons[entry[1]]=b
func _queue_rebuild()->void:
	if rebuilding:return
	rebuilding=true;call_deferred("_rebuild_page")
func _rebuild_page()->void:
	rebuilding=false;active_scroll=null;progress_bars.clear();run_buttons.clear();cash_buttons.clear()
	for c in page_root.get_children():c.queue_free()
	var d:=GameData.world(GameState.current_world);var s:Dictionary=GameState.worlds[GameState.current_world]
	header_cash.text="$"+GameState.format_number(s.cash);header_rate.text="$"+GameState.format_number(GameState.rate_per_second(GameState.current_world))+" / SEC";world_button.text="WORLD\n"+d.name.to_upper();ticket_label.text=str(GameState.golden_tickets)
	for page in nav_buttons:
		if is_instance_valid(nav_buttons[page]):
			var selected:bool=GameState.current_page==page;_style_button_color(nav_buttons[page],GOLD if selected else PAPER);nav_buttons[page].set_meta("fit_base_size",12 if selected else 10);nav_buttons[page].add_theme_constant_override("outline_size",1 if selected else 0);nav_buttons[page].add_theme_color_override("font_outline_color",INK)
	var bg:=get_node_or_null("Background") as ColorRect;if bg:bg.color=d.bg
	match GameState.current_page:
		"businesses":_build_businesses(d,s)
		"managers":_build_managers(d,s)
		"upgrades":_build_upgrades(d,s)
		"fish":_build_fish(d,s)
		"stats":_build_stats(d,s)
		"more":_build_more(d,s)
	call_deferred("_fit_all_text")
func _fit_all_text()->void:
	_fit_text_branch(self)
func _fit_text_branch(node:Node)->void:
	if node.has_meta("fit_base_size") and (node is Label or node is Button):
		var text_value:String=node.text;var should_fit:bool=node is Button or text_value.length()<=34 or (node is Label and node.autowrap_mode==TextServer.AUTOWRAP_OFF)
		var base:int=int(node.get_meta("fit_base_size"));var window_height:float=maxf(1.0,float(DisplayServer.window_get_size().y));var compensation:float=clampf(get_viewport_rect().size.y/window_height,0.85,1.7);var target:int=maxi(8,int(round(base*compensation)));var fitted:=target
		if should_fit and node.size.x>8.0:
			var font:Font=node.get_theme_font("font");var available:float=maxf(8.0,node.size.x-(22.0 if node is Button else 2.0))
			for line in text_value.split("\n"):
				var width:float=font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,target).x
				if width>available:fitted=mini(fitted,maxi(8,int(floor(float(target)*available/width))))
		node.add_theme_font_size_override("font_size",fitted)
	for child in node.get_children():_fit_text_branch(child)
func _notification(what:int)->void:
	if what==NOTIFICATION_RESIZED and is_node_ready():call_deferred("_fit_all_text")
func _title(text:String,sub:String="")->void:
	var row:=HBoxContainer.new();var l:=label(text,22,INK);l.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(l)
	if sub!="":
		var small:=label(sub,11,LOCKED);small.autowrap_mode=TextServer.AUTOWRAP_OFF;small.custom_minimum_size.x=100;small.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;row.add_child(small)
	page_root.add_child(row)
func _scroll_list()->VBoxContainer:
	var scroll:=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.scroll_deadzone=6;page_root.add_child(scroll);active_scroll=scroll;var list:=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list.add_theme_constant_override("separation",6);scroll.add_child(list);return list
func _texture(path:String)->TextureRect:
	var t:=TextureRect.new()
	if ResourceLoader.exists(path):t.texture=load(path)
	t.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size=Vector2(82,82)
	return t
func _business_icon(path:String,call:Callable)->TextureButton:
	var t:=TextureButton.new()
	if ResourceLoader.exists(path):t.texture_normal=load(path)
	t.ignore_texture_size=true
	t.stretch_mode=TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size=Vector2(82,82)
	t.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	t.pressed.connect(call)
	return t
func _build_businesses(d:Dictionary,s:Dictionary)->void:
	_title(d.name.to_upper(),"%d%% COMPLETE"%int(GameState.completion_percent(GameState.current_world)*100.0))
	var amounts:=HBoxContainer.new();amounts.add_theme_constant_override("separation",3);page_root.add_child(amounts)
	for e in [["x1",1],["x10",10],["x100",100],["MAX",-1]]:
		var b:=button(e[0],GOLD if GameState.purchase_amount==e[1] else Color("d8e7e3"),func():GameState.set_purchase_amount(e[1]),38);b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;amounts.add_child(b)
	var list:=_scroll_list()
	for i in d.names.size():list.add_child(_business_row(d,s,i))
func _business_row(d:Dictionary,s:Dictionary,i:int)->Control:
	var p:=panel(Color("fff8e8"));var row:=HBoxContainer.new();row.custom_minimum_size.y=132;row.add_theme_constant_override("separation",6);p.add_child(row);var icon:=_business_icon(d.icon_paths[i],func():GameState.start_business(GameState.current_world,i));icon.disabled=s.owned[i]<=0 or s.running[i];row.add_child(icon)
	var info:=VBoxContainer.new();info.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(info);info.add_child(label(d.names[i].to_upper(),16,INK));info.add_child(label("%d OWNED"%s.owned[i],11,Color("2c7180")));info.add_child(label("$%s / CYCLE"%GameState.format_number(GameState.payout(GameState.current_world,i)),14,Color("2a7d4f")))
	var bar:=ProgressBar.new();bar.show_percentage=false;bar.max_value=d.timers[i];bar.value=s.progress[i];bar.custom_minimum_size.y=17;bar.add_theme_stylebox_override("background",box(Color("c7d8d5"),6));bar.add_theme_stylebox_override("fill",box(AQUA,6));info.add_child(bar);progress_bars[i]=bar
	var actions:=HBoxContainer.new();info.add_child(actions);var start:=button("RUN" if not s.running[i] else "RUNNING",AQUA,func():GameState.start_business(GameState.current_world,i),36);start.disabled=s.owned[i]<=0 or s.running[i];start.size_flags_horizontal=Control.SIZE_EXPAND_FILL;actions.add_child(start);run_buttons[i]={"button":start,"icon":icon}
	var amount:=GameState.selected_amount(GameState.current_world,i);var cost:=GameState.bulk_cost(GameState.current_world,i,amount);var buy:=button("BUY %s\n$%s"%[("MAX" if GameState.purchase_amount==-1 else "x%d"%amount),GameState.format_number(cost)],CORAL,func():GameState.purchase(GameState.current_world,i),48);buy.disabled=amount<=0 or cost>s.cash;buy.custom_minimum_size.x=102;row.add_child(buy);cash_buttons.append({"button":buy,"cost":cost,"allowed":amount>0})
	if s.gilded[i]:var star:=label("★",24,Color("d89c00"));row.add_child(star)
	return p
func _build_managers(d:Dictionary,s:Dictionary)->void:
	_title("MANAGERS","AUTOMATION ONLY");var list:=_scroll_list()
	for i in d.managers.size():
		var p:=panel(Color("fff8e8"));var row:=HBoxContainer.new();row.custom_minimum_size.y=104;p.add_child(row);var portrait:=_texture(d.manager_paths[i]);portrait.custom_minimum_size=Vector2(86,86);row.add_child(portrait);var v:=VBoxContainer.new();v.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(v);v.add_child(label(d.managers[i],17,INK));v.add_child(label("Runs %s"%d.names[i],11,LOCKED));var b:=button("HIRED" if s.managers[i] else "HIRE\n$%s"%GameState.format_number(d.manager_costs[i]),CORAL,func():GameState.hire_manager(GameState.current_world,i),48);b.disabled=s.managers[i] or s.cash<d.manager_costs[i];b.custom_minimum_size.x=105;row.add_child(b);cash_buttons.append({"button":b,"cost":d.manager_costs[i],"allowed":not s.managers[i]});list.add_child(p)
func _build_upgrades(d:Dictionary,s:Dictionary)->void:
	_title("UPGRADES","%d / %d OWNED"%[s.upgrade_level,d.upgrade_count])
	var max_panel:=panel(Color("fff0c7"));page_root.add_child(max_panel);var max_row:=HBoxContainer.new();max_row.custom_minimum_size.y=78;max_panel.add_child(max_row);var fish_icon:=_texture("res://assets/businesses/fish/01-fish.png");fish_icon.custom_minimum_size=Vector2(62,62);max_row.add_child(fish_icon);var max_text:=VBoxContainer.new();max_text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;max_row.add_child(max_text);max_text.add_child(label("BUY MAX UPGRADES",15,INK));max_text.add_child(label("Buys every currently affordable upgrade at once. Fish are excellent lawyers.",11,LOCKED));var max_buy:=button("BUY MAX\nUPGRADES" if GameState.upgrade_max_unlocked else "UNLOCK\n%d FISH"%GameState.upgrade_max_fish_cost(),CORAL,_upgrade_max_action,48);max_buy.disabled=(not GameState.upgrade_max_unlocked and s.fish<GameState.upgrade_max_fish_cost()) or (GameState.upgrade_max_unlocked and (s.upgrade_level>=d.upgrade_count or s.cash<GameState.upgrade_cost(GameState.current_world)));max_buy.custom_minimum_size.x=104;max_row.add_child(max_buy);if GameState.upgrade_max_unlocked:cash_buttons.append({"button":max_buy,"cost":GameState.upgrade_cost(GameState.current_world),"allowed":s.upgrade_level<d.upgrade_count})
	upgrade_page_start=maxi(upgrade_page_start,s.upgrade_level)
	var paging:=HBoxContainer.new();paging.add_theme_constant_override("separation",4);page_root.add_child(paging)
	var previous:=button("◀ PREVIOUS",Color("d8e7e3"),func():upgrade_page_start=maxi(s.upgrade_level,upgrade_page_start-12);_queue_rebuild(),36);previous.disabled=upgrade_page_start<=s.upgrade_level;previous.size_flags_horizontal=Control.SIZE_EXPAND_FILL;paging.add_child(previous)
	var end:int=mini(d.upgrade_count,upgrade_page_start+12);var range_label:=label("%d–%d OF %d"%[upgrade_page_start+1,end,d.upgrade_count],11,LOCKED);range_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;range_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;paging.add_child(range_label)
	var next:=button("NEXT ▶",Color("d8e7e3"),func():upgrade_page_start=mini(d.upgrade_count-1,upgrade_page_start+12);_queue_rebuild(),36);next.disabled=end>=d.upgrade_count;next.size_flags_horizontal=Control.SIZE_EXPAND_FILL;paging.add_child(next)
	var list:=_scroll_list()
	for index in range(upgrade_page_start,end):
		var u:=GameData.upgrade(GameState.current_world,index);var available:bool=index==s.upgrade_level;var p:=panel(Color("fff8e8"));var row:=HBoxContainer.new();row.custom_minimum_size.y=112;row.add_theme_constant_override("separation",7);p.add_child(row);var icon:=_texture(u.icon);icon.custom_minimum_size=Vector2(74,74);row.add_child(icon)
		var details:=VBoxContainer.new();details.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(details);details.add_child(label(u.name,15,INK));details.add_child(label("AFFECTS: %s — %s"%[d.names[u.target],u.effect],11,Color("2a7d4f")));details.add_child(label(u.description,11,LOCKED))
		var cost:=GameState.upgrade_cost_at(GameState.current_world,index);var buy_text:="BUY\n$%s"%GameState.format_number(cost) if available else "LOCKED";var buy:=button(buy_text,CORAL,func():GameState.buy_upgrade(GameState.current_world),48);buy.disabled=not available or s.cash<cost;buy.custom_minimum_size.x=92;row.add_child(buy);cash_buttons.append({"button":buy,"cost":cost,"allowed":available});list.add_child(p)
func _build_fish(d:Dictionary,s:Dictionary)->void:
	_title("FISH PRESTIGE","PERSISTENT");var p:=panel(Color("fff8e8"));page_root.add_child(p);var v:=VBoxContainer.new();p.add_child(v);v.add_child(label("%d FISH"%s.fish,34,Color("2a7d4f")));v.add_child(label("Each Fish adds +2% profit on %s."%d.name,14,LOCKED));var gain:=GameState.fish_available(GameState.current_world);var b:=button("RESET WORLD FOR +%d FISH"%gain,CORAL,func():GameState.prestige(GameState.current_world),60);b.disabled=gain<=0;v.add_child(b);var t:=panel(Color("fff0c7"));page_root.add_child(t);var tv:=VBoxContainer.new();t.add_child(tv);tv.add_child(label("GOLDEN TICKETS: %d"%GameState.golden_tickets,22,INK));var tb:=button("BUY TICKET — $%s"%GameState.format_number(GameState.ticket_cost(GameState.current_world)),GOLD,func():GameState.buy_ticket(GameState.current_world),52);tb.disabled=s.cash<GameState.ticket_cost(GameState.current_world);tv.add_child(tb);var list:=_scroll_list()
	for i in d.names.size():var gb:=button(("★ GILDED" if s.gilded[i] else "GILD %s — 1 TICKET"%d.names[i]),GOLD,func():GameState.gild(GameState.current_world,i),42);gb.disabled=s.gilded[i] or GameState.golden_tickets<1;list.add_child(gb)
func _upgrade_max_action()->void:
	if GameState.upgrade_max_unlocked:GameState.buy_max_upgrades(GameState.current_world)
	else:GameState.unlock_upgrade_max(GameState.current_world)
func _build_stats(d:Dictionary,s:Dictionary)->void:
	_title("STATISTICS","SAVED LOCALLY");var list:=_scroll_list();var stats=[["Lifetime Cash","$"+GameState.format_number(GameState.lifetime_cash)],["World Lifetime","$"+GameState.format_number(s.lifetime)],["Businesses Purchased",str(_sum(s.owned))],["Managers Hired",str(_count_true(s.managers))],["Businesses Gilded",str(_count_true(s.gilded))],["Manual Business Taps",str(GameState.manual_taps)],["Times Ima Nota Fish Has Helped","0"],["Times Player Read This Statistic","1"]]
	for e in stats:
		var p:=panel(Color("fff8e8"));p.custom_minimum_size.y=68;var v:=VBoxContainer.new();v.add_theme_constant_override("separation",2);p.add_child(v);var n:=label(e[0],13,LOCKED);n.autowrap_mode=TextServer.AUTOWRAP_OFF;v.add_child(n);var value:=label(e[1],20,Color("2a7d4f"));value.autowrap_mode=TextServer.AUTOWRAP_OFF;v.add_child(value);list.add_child(p)
func _build_more(_d:Dictionary,_s:Dictionary)->void:
	_title("WORLDS & COMPLETION");var list:=_scroll_list()
	for id in GameData.WORLD_IDS:
		var wd:=GameData.world(id);var open:bool=GameState.unlocked.get(id,false);var text:String=str(wd.name).to_upper()
		if open:text+="\n$"+GameState.format_number(GameState.worlds[id].cash)
		elif id=="moon":text+="\nUNLOCK $1Qa EARTH"
		elif id=="different":text+="\nUNLOCK $1Sp MOON"
		else:text+="\nCOMPLETE ALL 3 WORLDS"
		var b:=button(text,wd.accent,func():GameState.unlock_world(id),62);b.disabled=(not open and id=="fish") or (not open and id=="moon" and GameState.worlds.earth.cash<GameState.unlock_cost(id)) or (not open and id=="different" and GameState.worlds.moon.cash<GameState.unlock_cost(id));list.add_child(b)
	var reset:=button("RESET SAVE DATA",Color("c7d0ce"),_reset_warning,45);list.add_child(reset)
func _show_world_menu()->void:GameState.set_page("more")
func _show_toast(text:String)->void:toast_label.text=text;var timer:=get_tree().create_timer(4.0);timer.timeout.connect(func():if toast_label:toast_label.text="")
func _reset_warning()->void:_show_toast("Save reset is intentionally protected. Clear browser storage to start over.")
func _sum(a:Array)->int:
	var n:=0
	for x in a:n+=int(x)
	return n
func _count_true(a:Array)->int:
	var n:=0
	for x in a:
		if x:n+=1
	return n
func _process(_delta:float)->void:
	if header_cash:
		var current:Dictionary=GameState.worlds[GameState.current_world]
		header_cash.text="$"+GameState.format_number(current.cash)
		header_rate.text="$"+GameState.format_number(GameState.rate_per_second(GameState.current_world))+" / SEC"
	if progress_bars.is_empty():return
	var d:=GameData.world(GameState.current_world);var s:Dictionary=GameState.worlds[GameState.current_world]
	for i in progress_bars:
		if is_instance_valid(progress_bars[i]):progress_bars[i].max_value=d.timers[i];progress_bars[i].value=s.progress[i]
	for i in run_buttons:
		var controls:Dictionary=run_buttons[i];var running:bool=s.running[i];var available:bool=s.owned[i]>0 and not running
		if is_instance_valid(controls.button):controls.button.text="RUNNING" if running else "RUN";controls.button.disabled=not available
		if is_instance_valid(controls.icon):controls.icon.disabled=not available
	for entry in cash_buttons:
		if is_instance_valid(entry.button):entry.button.disabled=not entry.allowed or s.cash<float(entry.cost)
func _input(event:InputEvent)->void:
	if not is_instance_valid(active_scroll):return
	if event is InputEventScreenDrag:
		active_scroll.scroll_vertical-=int(event.relative.y);get_viewport().set_input_as_handled()
	elif event is InputEventPanGesture:
		active_scroll.scroll_vertical+=int(event.delta.y*42.0);get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		active_scroll.scroll_vertical-=int(event.relative.y)
