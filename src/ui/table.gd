extends Node3D

const Session = preload("res://net/session.gd")
const Content = preload("res://core/content.gd")
var session
var board = Content.board()
var defs = Content.weapons()
var colors = [Color("edb564"),Color("70bdc9"),Color("cf798f"),Color("9c99da"),Color("9ec47e"),Color("dd926b")]
var camera: Camera3D
var world: Node3D
var figures: Node3D
var floors = {}
var viewport: SubViewport
var field: SubViewportContainer
var title: Label
var info: Label
var message: Label
var log_box: RichTextLabel
var survivor_box: VBoxContainer
var actions_box: GridContainer
var inventory_box: VBoxContainer
var decisions_box: VBoxContainer
var dice_label: Label
var selected = "w0"
var mode = "inspect"
var weapon_slot = 0
var equip_from = -1
var from_slot = 0
var trade_target = 1
var angle = 0.0
var elevation = 0.94
var zoom = 10.5
var ip: LineEdit
var code: LineEdit
var status: Label
var panel: VBoxContainer
var capture_path = ""
var use_dual = false
var attack_dialog: ConfirmationDialog
var attack_candidate = {}

func _ready() -> void:
	build_ui()
	build_world()
	session = Session.new()
	session.name = "Session"
	add_child(session)
	session.changed.connect(refresh)
	session.rejected.connect(func(text): message.text = text)
	refresh()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="): capture_path = arg.trim_prefix("--capture=")
	if not capture_path.is_empty(): capture.call_deferred()

func label(text: String,size: int = 16) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size",size)
	return l

func button(text: String,fn: Callable,parent: Node, disabled: bool = false) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size.y = 34
	b.disabled = disabled
	b.pressed.connect(fn)
	parent.add_child(b)
	return b

func box_style(bg: Color,border: Color = Color("354653")) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style

func build_ui() -> void:
	var ui = CanvasLayer.new()
	add_child(ui)
	var root = PanelContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_stylebox_override("panel",box_style(Color("111923")))
	ui.add_child(root)
	attack_dialog = ConfirmationDialog.new()
	attack_dialog.title = "Confirmar ataque"
	attack_dialog.ok_button_text = "Confirmar e preparar dados"
	attack_dialog.cancel_button_text = "Voltar"
	attack_dialog.min_size = Vector2i(470,200)
	ui.add_child(attack_dialog)
	attack_dialog.confirmed.connect(func(): session.submit(attack_candidate); attack_candidate = {})
	attack_dialog.canceled.connect(func(): attack_candidate = {})
	var theme = Theme.new()
	theme.default_font_size = 15
	theme.set_stylebox("normal","Button",box_style(Color("253642")))
	theme.set_stylebox("hover","Button",box_style(Color("344e5c"),Color("7dbfc4")))
	theme.set_stylebox("pressed","Button",box_style(Color("456a76")))
	theme.set_stylebox("disabled","Button",box_style(Color("1c252f")))
	theme.set_color("font_color","Button",Color("eee8db"))
	theme.set_color("font_color","Label",Color("eee8db"))
	root.theme = theme
	var row = HBoxContainer.new()
	root.add_child(row)
	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	title = label("ZOMBICIDE  /  M0",28)
	left.add_child(title)
	var warning = label("MESA DE TESTE · fichas, decks e mapa ainda parciais",14)
	warning.modulate = Color("e6b96f")
	left.add_child(warning)
	info = label("",16)
	left.add_child(info)
	var cam_buttons = HBoxContainer.new()
	left.add_child(cam_buttons)
	button("Vista de mesa",func(): elevation = 0.94; position_camera(),cam_buttons)
	button("Vista superior",func(): elevation = 1.52; position_camera(),cam_buttons)
	button("↶",func(): angle -= 0.25; position_camera(),cam_buttons)
	button("↷",func(): angle += 0.25; position_camera(),cam_buttons)
	field = SubViewportContainer.new()
	field.stretch = true
	field.custom_minimum_size = Vector2(420,360)
	field.size_flags_vertical = Control.SIZE_EXPAND_FILL
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(field)
	viewport = SubViewport.new()
	viewport.size = Vector2i(920,560)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	field.add_child(viewport)
	field.gui_input.connect(board_input)
	message = label("Escolha sua peça, ative e selecione uma ação. Roda do mouse ajusta o zoom.",14)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.custom_minimum_size.y = 44
	left.add_child(message)
	log_box = RichTextLabel.new()
	log_box.custom_minimum_size.y = 116
	log_box.scroll_following = true
	log_box.add_theme_font_size_override("normal_font_size",14)
	left.add_child(log_box)
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.x = 350
	row.add_child(scroll)
	panel = VBoxContainer.new()
	panel.custom_minimum_size.x = 330
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(panel)
	panel.add_child(label("SOBREVIVENTES",18))
	survivor_box = VBoxContainer.new()
	panel.add_child(survivor_box)
	panel.add_child(label("ZONA E AÇÕES",18))
	actions_box = GridContainer.new()
	actions_box.columns = 2
	panel.add_child(actions_box)
	panel.add_child(label("EQUIPAMENTO",18))
	inventory_box = VBoxContainer.new()
	panel.add_child(inventory_box)
	var decision_heading = label("DADOS E DECISÕES",18)
	panel.add_child(decision_heading)
	dice_label = label("Dados: —",21)
	panel.add_child(dice_label)
	decisions_box = VBoxContainer.new()
	panel.add_child(decisions_box)
	panel.add_child(label("MISSÃO / CONTINUIDADE",18))
	button("Salvar missão",func(): session.save_game(),panel)
	button("Continuar save",func(): session.load_game(),panel)
	panel.add_child(label("SESSÃO PRIVADA · TESTE LOCAL",16))
	ip = LineEdit.new()
	ip.text = "127.0.0.1"
	ip.placeholder_text = "Endereço do anfitrião"
	panel.add_child(ip)
	code = LineEdit.new()
	code.text = "mesa-amigos"
	code.placeholder_text = "Convite (mínimo 6 caracteres)"
	code.secret = true
	panel.add_child(code)
	button("Criar mesa online (2 pessoas)",func():
		var err = session.host(code.text)
		message.text = "Sala criada; compartilhe endereço e convite com seu amigo." if err == OK else "Não foi possível criar sala (%d)." % err,panel)
	button("Entrar / reconectar",func():
		var err = session.join(ip.text,code.text)
		message.text = "Conectando…" if err == OK else "Falha ao iniciar conexão (%d)." % err,panel)
	button("Desconectar cliente",func(): session.disconnect_client(),panel)
	status = label("Solo local",13)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(status)
	# Required choices and roll control remain visible instead of below the inventory.
	panel.move_child(decision_heading,0)
	panel.move_child(dice_label,1)
	panel.move_child(decisions_box,2)

func build_world() -> void:
	world = Node3D.new()
	viewport.add_child(world)
	var environment = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("1b2532")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("d0dbdf")
	env.ambient_light_energy = 0.65
	environment.environment = env
	world.add_child(environment)
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55,-32,0)
	light.light_energy = 1.5
	light.shadow_enabled = true
	world.add_child(light)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	world.add_child(camera)
	position_camera()
	mesh_box(Vector3(0,-0.35,0),Vector3(14,0.55,8),Color("624a37"),world)
	mesh_box(Vector3(0,-0.03,0),Vector3(12.15,0.12,6.15),Color("171c21"),world)
	for id in board.zones:
		var z = board.zones[id]
		var base = Color("686b5d") if z.inside else Color("46505b")
		if z.inside and z.dark: base = Color("3e514e")
		var floor_mesh = mesh_box(pos(id)+Vector3(0,0.06,0),Vector3(1.93,0.12,1.93),base,world)
		floors[id] = {"mesh":floor_mesh,"base":base}
		var l = Label3D.new()
		l.text = z.name
		l.font_size = 40
		l.pixel_size = 0.008
		l.position = pos(id)+Vector3(0,0.15,0.69)
		l.rotation_degrees.x = -90
		l.modulate = Color("e0e1d8")
		world.add_child(l)
		if not z.inside:
			for dx in [-0.57,-0.19,0.19,0.57]: mesh_box(pos(id)+Vector3(dx,0.131,0.08),Vector3(0.17,0.012,0.55),Color("b4b2a4"),world)
	figures = Node3D.new()
	world.add_child(figures)

func material(color: Color) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.8
	return m

func mesh_box(p: Vector3,size: Vector3,color: Color,parent: Node) -> MeshInstance3D:
	var mesh = BoxMesh.new()
	mesh.size = size
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material(color)
	parent.add_child(node)
	node.position = p
	return node

func cylinder(p: Vector3,radius: float,height: float,color: Color,parent: Node, top: float = -1) -> void:
	var mesh = CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top < 0 else top
	mesh.height = height
	mesh.radial_segments = 20
	var node = MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material(color)
	parent.add_child(node)
	node.position = p

func pos(id: String) -> Vector3:
	var z = board.zones[id]
	return Vector3(float(z.x)*2.0-5.0,0,float(z.y)*2.0-2.0)

func position_camera() -> void:
	if camera == null: return
	camera.size = zoom
	camera.position = Vector3(sin(angle)*cos(elevation),sin(elevation),cos(angle)*cos(elevation))*18
	camera.look_at(Vector3.ZERO,Vector3.FORWARD if elevation > 1.5 else Vector3.UP)

func clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func refresh() -> void:
	if session == null or session.view.is_empty(): return
	var s = session.view
	clear(survivor_box)
	clear(actions_box)
	clear(inventory_box)
	clear(decisions_box)
	clear(figures)
	var remaining = s.objectives.size()+s.crates.size()
	var phase = "PAUSA" if s.paused else ("VITÓRIA" if s.outcome == "victory" else ("DERROTA" if s.outcome == "defeat" else "JOGADORES"))
	info.text = "Rodada %d · %s · Perigo %s · Coletas restantes %d/4" % [s.round,phase,["AZUL","AMARELO","LARANJA","VERMELHO"][Content.danger(max_ap(s))],remaining]
	status.text = "Você: %s · modo %s · porta %d" % [session.role,session.mode,session.port]
	if s.paused: message.text = s.pause_reason
	for v in s.survivors:
		var text = "%s  %s · %d ações · %d/3 fer. · %d AD" % ["▶" if s.active == v.id else "○",v.name,v.actions,v.wounds,v.ap]
		if v.escaped: text = v.name+" · ESCAPOU"
		elif v.id in s.done: text += " · concluído"
		text += " · "+v.owner
		var b = button(text,func():
			if session.view.active == -1: session.submit({"action":"activate","actor":v.id})
			else: message.text = "Encerre a ativação atual para ativar outra peça."
			equip_from = -1,survivor_box,v.escaped or v.id in s.done or v.owner != session.role)
		b.add_theme_color_override("font_color",colors[int(v.id)])
		b.add_theme_font_size_override("font_size",12)
	var active = s.survivors[int(s.active)] if s.active >= 0 else {}
	var permitted = not active.is_empty() and active.owner == session.role and not s.paused and s.outcome == "" and s.pending.is_empty()
	var chosen = label("Selecionada: "+board.zones[selected].name,14)
	chosen.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	actions_box.add_child(chosen)
	actions_box.add_child(label("",14))
	for item in [["Mover","move"],["Atacar","attack"],["Abrir porta","open"]]:
		var action = item[1]
		button(item[0],func(): mode = action; message.text = "Clique na zona para "+action+".",actions_box,not permitted)
	for item in [["Buscar","search"],["Objetivo","objective"],["Caixa","crate"],["Fazer ruído","noise"],["Encerrar","end"],["Fugir","escape"]]:
		var action = item[1]
		button(item[0],func(): session.submit({"action":action}),actions_box,not permitted)
	if not active.is_empty():
		inventory_box.add_child(label("Clique em dois slots para reorganizar (1 ação).",13))
		for i in range(5):
			var item = str(active.inventory[i])
			var text = ("Mão %d" % (i+1)) if i < 2 else ("Mochila %d" % (i-1))
			text += ": "+str(defs.get(item,{}).get("name","vazio"))
			if equip_from == i: text = "[ORIGEM] "+text
			var slot = i
			button(text,func():
				if equip_from < 0:
					equip_from = slot
					from_slot = slot
					if slot < 2: weapon_slot = slot
					refresh()
				else:
					var source = equip_from
					equip_from = -1
					session.submit({"action":"equip","from":source,"to":slot}),inventory_box,not permitted)
		var hands = HBoxContainer.new()
		inventory_box.add_child(hands)
		for i in range(2):
			var slot = i
			button("Arma: mão %d" % (i+1),func(): weapon_slot = slot; message.text = "Ataque usará mão %d." % (slot+1),hands,not permitted)
		var dual = CheckButton.new()
		dual.text = "Usar Dual (se permitido)"
		dual.button_pressed = use_dual
		dual.disabled = not permitted
		dual.toggled.connect(func(enabled): use_dual = enabled)
		inventory_box.add_child(dual)
		var trade_row = HBoxContainer.new()
		inventory_box.add_child(trade_row)
		var options = OptionButton.new()
		for v in s.survivors: options.add_item(v.name,int(v.id))
		options.selected = trade_target
		options.item_selected.connect(func(i): trade_target = i)
		trade_row.add_child(options)
		button("Dar slot %d" % (from_slot+1),func(): session.submit({"action":"trade","other":trade_target,"slot":from_slot}),trade_row,not permitted)
		button("Descartar slot %d" % (from_slot+1),func(): session.submit({"action":"discard","actor":s.active,"slot":from_slot}),inventory_box,active.owner != session.role)
	dice_label.text = "Dados: "+("—" if s.dice.is_empty() else "  ".join(s.dice.map(func(v): return str(v))))
	if not s.pending.is_empty():
		var p = s.pending
		var prompt = label(p.prompt,15)
		prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		decisions_box.add_child(prompt)
		decisions_box.add_child(label("Decisão de: "+p.owner,13))
		if p.kind == "roll":
			button("LANÇAR %d DADO(S)" % p.dice,func(): session.submit({"action":"roll"}),decisions_box,p.owner != session.role or s.paused)
		else:
			for value in s.get("choices",[]):
				var choice = str(value)
				var text = choice
				if p.kind == "loot": text = "Descartar" if choice == "discard" else "Colocar no slot %d" % (int(choice)+1)
				elif p.kind == "wound": text = s.survivors[int(choice)].name
				elif p.kind in ["building","split"]: text = board.zones[choice].name
				elif p.kind == "hit": text = "Zumbi #"+choice
				elif p.kind == "trade": text = "Aceitar" if choice == "yes" else "Recusar"
				button(text,func(): session.submit({"action":"choose","choice":choice}),decisions_box,p.owner != session.role or s.paused)
	else: decisions_box.add_child(label("Nenhuma decisão pendente.",14))
	log_box.text = "\n".join(s.log)
	var occupied = {}
	for v in s.survivors:
		if not v.escaped: draw_peg(v.zone,colors[int(v.id)],str(int(v.id)+1),occupied,v.id == s.active,0.8)
	for z in s.zombies:
		var color = {"walker":Color("a2ac94"),"runner":Color("d7ac6d"),"fatty":Color("9b8499"),"abomination":Color("9f5459")}.get(z.type,Color.GRAY)
		draw_peg(z.zone,color,{"walker":"W","runner":"R","fatty":"F","abomination":"A"}[z.type],occupied,false,0.95 if z.type == "fatty" else 0.72)
	for id in floors:
		var m = floors[id].mesh.material_override
		m.albedo_color = floors[id].base.lightened(0.28) if id == selected else floors[id].base
	for id in s.objectives: marker(id,Color("ca6260"),"OBJ",Vector3(-0.55,0.18,-0.57))
	for id in s.crates: marker(id,Color("d5b36a"),"CAIXA",Vector3(-0.55,0.18,-0.57))
	marker(board.start,Color("6bb8b5"),"SAÍDA",Vector3(-0.55,0.18,-0.57))
	for id in board.spawns: marker(id,Color("b75857"),"SPAWN",Vector3(-0.55,0.18,-0.57))
	for pair in board.doors:
		if not s.doors.get(door_key(pair[0],pair[1]),false):
			var delta = pos(pair[1])-pos(pair[0])
			mesh_box((pos(pair[0])+pos(pair[1]))/2+Vector3(0,0.23,0),Vector3(0.13 if delta.x != 0 else 0.8,0.3,0.8 if delta.x != 0 else 0.13),Color("b18355"),figures)

func max_ap(s: Dictionary) -> int:
	var result = 0
	for v in s.survivors: result = maxi(result,int(v.ap))
	return result

func door_key(a: String,b: String) -> String:
	return a+"|"+b if a < b else b+"|"+a

func draw_peg(zone: String,color: Color,text: String,occupied: Dictionary,active: bool,height: float) -> void:
	var index = int(occupied.get(zone,0))
	occupied[zone] = index+1
	var p = pos(zone)+Vector3((index%3-1)*0.48,0.14,(index/3-1)*0.43)
	if index >= 12: p.y += 0.15*floor(index/12.0)
	cylinder(p+Vector3(0,0.07,0),0.22,0.14,Color("f5df9d") if active else color.darkened(0.35),figures)
	cylinder(p+Vector3(0,height*0.43,0),0.14,height*0.6,color,figures,0.09)
	var sphere = SphereMesh.new()
	sphere.radius = 0.16
	sphere.height = 0.32
	var head = MeshInstance3D.new()
	head.mesh = sphere
	head.material_override = material(color.lightened(0.12))
	figures.add_child(head)
	head.position = p+Vector3(0,height*0.8,0)
	var l = Label3D.new()
	l.text = text
	l.font_size = 44
	l.pixel_size = 0.007
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = p+Vector3(0,height+0.08,0)
	l.modulate = Color.WHITE
	figures.add_child(l)

func marker(zone: String,color: Color,text: String,offset: Vector3) -> void:
	var p = pos(zone)+offset
	mesh_box(p,Vector3(0.75,0.10,0.42),color,figures)
	var l = Label3D.new()
	l.text = text
	l.font_size = 40
	l.pixel_size = 0.006
	l.rotation_degrees.x = -90
	l.position = p+Vector3(0,0.06,0)
	figures.add_child(l)

func board_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = maxf(8,zoom-1)
			position_camera()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = minf(28,zoom+1)
			position_camera()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			var origin = camera.project_ray_origin(event.position)
			var direction = camera.project_ray_normal(event.position)
			var hit = Plane(Vector3.UP,0.12).intersects_ray(origin,direction)
			if hit == null: return
			for id in board.zones:
				var p = pos(id)
				if absf(hit.x-p.x) <= 0.98 and absf(hit.z-p.z) <= 0.98:
					selected = id
					if mode != "inspect":
						var action = mode
						mode = "inspect"
						if action == "attack": confirm_attack(id)
						else: session.submit({"action":action,"zone":id,"slot":weapon_slot})
					refresh()
					return

func confirm_attack(zone: String) -> void:
	var s = session.view
	if s.active < 0: return
	var v = s.survivors[int(s.active)]
	var weapon = defs.get(v.inventory[weapon_slot],{})
	attack_candidate = {"action":"attack","zone":zone,"slot":weapon_slot,"dual":use_dual}
	var allies = s.survivors.filter(func(other): return not other.escaped and other.zone == zone and other.id != v.id)
	var lines = ["Zona: "+board.zones[zone].name,"Arma: "+str(weapon.get("name","nenhuma")),"Precisão: %d+ · Dano: %d · Dados base: %d" % [weapon.get("accuracy",0),weapon.get("damage",0),weapon.get("dice",0)]]
	if not allies.is_empty() and weapon.get("mode","") == "ranged": lines.append("ATENÇÃO: há colegas na zona; erros podem causar fogo amigo.")
	if v.inventory[weapon_slot] == "molotov": lines.append("Molotov elimina todos os atores na zona, incluindo sobreviventes.")
	lines.append("O sistema valida alcance, visão, custo e equipamento ao confirmar.")
	attack_dialog.dialog_text = "\n".join(lines)
	attack_dialog.popup_centered()

func capture() -> void:
	for i in range(8): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var err = get_viewport().get_texture().get_image().save_png(capture_path)
	print("CAPTURE ",err," ",capture_path)
	get_tree().quit(0 if err == OK else 1)
