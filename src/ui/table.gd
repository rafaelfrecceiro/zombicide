extends Node3D

const Session = preload("res://net/session.gd")
const Content = preload("res://core/content.gd")
const Art = preload("res://ui/comic_art.gd")
var session
var board = Content.board()
var defs = Content.weapons()
var colors = [Color("43bcc4"),Color("d2a040"),Color("cc6551"),Color("a087bd"),Color("91a36c"),Color("7099c5")]
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
var survivor_box: BoxContainer
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
var zoom = 8.4
var ip: LineEdit
var code: LineEdit
var status: Label
var panel: VBoxContainer
var capture_path = ""
var use_dual = false
var attack_dialog: ConfirmationDialog
var attack_candidate = {}
var skip_intro = false
var help_dialog: AcceptDialog
var inventory_dialog: AcceptDialog
var session_dialog: AcceptDialog
var guide_title: Label
var guide_body: Label
var actor_title: Label
var actor_stats: Label
var weapon_info: Label
var weapon_picker: OptionButton
var decision_section: VBoxContainer
var legal_zones: Array = []
var hints: Control
var last_actor = -1
var actor_portrait: TextureRect
var miniatures: Dictionary = {}
var piece_positions: Dictionary = {}
var piece_nodes: Dictionary = {}
var reduce_motion = false

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
	if not skip_intro:
		if not capture_path.is_empty():
			if "--capture-intro" in OS.get_cmdline_user_args(): help_dialog.popup_centered(Vector2i(640,440))
			capture.call_deferred()
		else: help_dialog.popup_centered(Vector2i(640,440))

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

func box_style(bg: Color,border: Color = Color("191c1d")) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(1)
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
	root.add_theme_stylebox_override("panel",box_style(Color("1c2021")))
	ui.add_child(root)
	var theme = Theme.new()
	theme.default_font_size = 16
	theme.set_stylebox("normal","Button",box_style(Art.PAPER))
	theme.set_stylebox("hover","Button",box_style(Color("fff2d7"),Color("42c8d4")))
	theme.set_stylebox("pressed","Button",box_style(Color("dbcaab")))
	theme.set_stylebox("disabled","Button",box_style(Color("494b46")))
	theme.set_stylebox("focus","Button",box_style(Color(0,0,0,0),Color("42c8d4")))
	theme.set_color("font_color","Button",Art.INK)
	theme.set_color("font_hover_color","Button",Art.INK)
	theme.set_color("font_pressed_color","Button",Art.INK)
	theme.set_color("font_disabled_color","Button",Color("afae9e"))
	theme.set_color("font_color","Label",Art.PAPER)
	root.theme = theme
	var layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation",9)
	root.add_child(layout)
	var header = HBoxContainer.new()
	layout.add_child(header)
	title = label("ZOMBICIDE / M0 · QUADRINHOS URBANOS",25)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	button("Como jogar",func(): help_dialog.popup_centered(Vector2i(640,440)),header)
	button("Partida / salvar",func(): session_dialog.popup_centered(Vector2i(520,510)),header)
	var warning = label("Direção B escolhida · amostra visual inicial · fichas e baralhos ainda de laboratório",13)
	warning.modulate = Color("d7b579")
	layout.add_child(warning)
	info = label("",16)
	layout.add_child(info)
	var main = HBoxContainer.new()
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation",14)
	layout.add_child(main)
	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation",6)
	main.add_child(left)
	var guide = PanelContainer.new()
	guide.add_theme_stylebox_override("panel",box_style(Art.TEAL))
	left.add_child(guide)
	var instruction = VBoxContainer.new()
	guide.add_child(instruction)
	guide_title = label("",21)
	instruction.add_child(guide_title)
	guide_body = label("",15)
	guide_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction.add_child(guide_body)
	var stack = Control.new()
	stack.custom_minimum_size = Vector2(420,280)
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(stack)
	field = SubViewportContainer.new()
	field.stretch = true
	field.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stack.add_child(field)
	viewport = SubViewport.new()
	viewport.size = Vector2i(920,560)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	field.add_child(viewport)
	field.gui_input.connect(board_input)
	field.resized.connect(func(): position_camera.call_deferred())
	hints = preload("res://ui/board_hints.gd").new()
	hints.table = self
	hints.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hints.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stack.add_child(hints)
	var camera_row = HBoxContainer.new()
	left.add_child(camera_row)
	button("Vista de mesa",func(): elevation = 0.94; position_camera(),camera_row)
	button("Vista superior",func(): elevation = 1.52; position_camera(),camera_row)
	button("Girar ↶",func(): angle -= 0.25; position_camera(),camera_row)
	button("Girar ↷",func(): angle += 0.25; position_camera(),camera_row)
	left.add_child(label("Números: sobreviventes   |   Vermelhos: Z comum · R corredor · B bruto   |   Roda: zoom",13))
	var card_panel = PanelContainer.new()
	card_panel.add_theme_stylebox_override("panel",box_style(Art.PAPER))
	card_panel.custom_minimum_size.x = 314
	var card_theme = theme.duplicate()
	card_theme.set_color("font_color","Label",Art.INK)
	card_panel.theme = card_theme
	main.add_child(card_panel)
	panel = VBoxContainer.new()
	panel.add_theme_constant_override("separation",7)
	card_panel.add_child(panel)
	var actor_header = HBoxContainer.new()
	panel.add_child(actor_header)
	actor_portrait = TextureRect.new()
	actor_portrait.texture = Art.portrait(0)
	actor_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	actor_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	actor_portrait.custom_minimum_size = Vector2(90,96)
	actor_header.add_child(actor_portrait)
	var actor_summary = VBoxContainer.new()
	actor_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actor_header.add_child(actor_summary)
	actor_title = label("ESCOLHA UMA PEÇA",18)
	actor_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	actor_summary.add_child(actor_title)
	actor_stats = label("",15)
	actor_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	actor_summary.add_child(actor_stats)
	decision_section = VBoxContainer.new()
	panel.add_child(decision_section)
	dice_label = label("Dados: —",23)
	decision_section.add_child(dice_label)
	decisions_box = VBoxContainer.new()
	decision_section.add_child(decisions_box)
	weapon_picker = OptionButton.new()
	weapon_picker.item_selected.connect(func(index): weapon_slot = index; refresh())
	panel.add_child(weapon_picker)
	weapon_info = label("",14)
	weapon_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(weapon_info)
	actions_box = GridContainer.new()
	actions_box.columns = 2
	actions_box.add_theme_constant_override("h_separation",7)
	actions_box.add_theme_constant_override("v_separation",7)
	panel.add_child(actions_box)
	button("Inventário / trocar",func(): inventory_dialog.popup_centered(Vector2i(630,550)),panel)
	status = label("",12)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(status)
	layout.add_child(label("SEUS SOBREVIVENTES · clique em uma peça disponível para ativar",14))
	survivor_box = HBoxContainer.new()
	survivor_box.add_theme_constant_override("separation",7)
	layout.add_child(survivor_box)
	message = label("",15)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.custom_minimum_size.y = 22
	layout.add_child(message)
	log_box = RichTextLabel.new()
	log_box.custom_minimum_size.y = 34
	log_box.scroll_following = true
	log_box.add_theme_font_size_override("normal_font_size",13)
	layout.add_child(log_box)
	attack_dialog = ConfirmationDialog.new()
	attack_dialog.title = "Confirmar ataque"
	attack_dialog.ok_button_text = "Confirmar e preparar dados"
	attack_dialog.cancel_button_text = "Voltar"
	attack_dialog.min_size = Vector2i(470,200)
	ui.add_child(attack_dialog)
	attack_dialog.confirmed.connect(func(): session.submit(attack_candidate); attack_candidate = {})
	attack_dialog.canceled.connect(func(): attack_candidate = {})
	help_dialog = AcceptDialog.new()
	help_dialog.title = "Como jogar este protótipo"
	help_dialog.ok_button_text = "Entendi, ir para a mesa"
	help_dialog.dialog_text = "OBJETIVO DA MISSÃO\nRecolha os 2 objetivos e as 2 caixas de armas. Depois, leve todos à SAÍDA.\n\n1. ESCOLHA UMA PEÇA\nClique em um dos seis cartões na parte inferior. Você ativa uma peça por vez.\n\n2. USE AS AÇÕES\nClique em Mover e depois em uma zona verde. Cada peça começa com 3 ações.\nPara entrar em edifícios, use Abrir porta com uma ferramenta equipada.\n\n3. ATAQUE E LANCE OS DADOS\nEscolha a arma, clique em Atacar e selecione uma zona destacada.\nConfira a prévia e clique em Lançar dados quando solicitado.\n\n4. ENCERRE A ATIVAÇÃO\nAo terminar, clique em Encerrar e escolha outra peça.\nDepois das seis peças, o jogo resolve a horda automaticamente.\n\nAs peças numeradas são suas. As peças vermelhas são os zumbis.\nEste laboratório ainda tem conteúdo e artes provisórios."
	ui.add_child(help_dialog)
	help_dialog.get_label().autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inventory_dialog = AcceptDialog.new()
	inventory_dialog.title = "Inventário da peça ativa"
	inventory_dialog.ok_button_text = "Voltar para a mesa"
	ui.add_child(inventory_dialog)
	inventory_box = VBoxContainer.new()
	inventory_dialog.add_child(inventory_box)
	session_dialog = AcceptDialog.new()
	session_dialog.title = "Partida, save e amigos"
	session_dialog.ok_button_text = "Voltar para a mesa"
	ui.add_child(session_dialog)
	var settings = VBoxContainer.new()
	settings.add_theme_constant_override("separation",8)
	session_dialog.add_child(settings)
	button("Salvar missão",func(): session.save_game(),settings)
	button("Continuar save",func(): session.load_game(); session_dialog.hide(),settings)
	button("Fazer ruído (gasta 1 ação)",func(): session.submit({"action":"noise"}); session_dialog.hide(),settings)
	var motion = CheckButton.new()
	motion.text = "Reduzir movimento das peças"
	motion.toggled.connect(func(enabled): reduce_motion = enabled)
	settings.add_child(motion)
	settings.add_child(label("Conexão privada de teste · 2 pessoas",17))
	ip = LineEdit.new()
	ip.text = "127.0.0.1"
	ip.placeholder_text = "Endereço do anfitrião"
	settings.add_child(ip)
	code = LineEdit.new()
	code.text = "mesa-amigos"
	code.placeholder_text = "Convite (mínimo 6 caracteres)"
	code.secret = true
	settings.add_child(code)
	button("Criar mesa online",func():
		var err = session.host(code.text)
		message.text = "Sala criada. Convide seu amigo." if err == OK else "Não foi possível criar sala (%d)." % err
		session_dialog.hide(),settings)
	button("Entrar / reconectar",func():
		var err = session.join(ip.text,code.text)
		message.text = "Conectando…" if err == OK else "Falha ao conectar (%d)." % err
		session_dialog.hide(),settings)
	button("Desconectar cliente",func(): session.disconnect_client(); session_dialog.hide(),settings)

func build_world() -> void:
	world = Node3D.new()
	viewport.add_child(world)
	var environment = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("202425")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("d0dbdf")
	env.ambient_light_energy = 0.45
	environment.environment = env
	world.add_child(environment)
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55,-32,0)
	light.light_energy = 0.8
	light.shadow_enabled = true
	world.add_child(light)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	world.add_child(camera)
	position_camera()
	mesh_box(Vector3(0,-0.35,0),Vector3(13,0.55,7),Color("272a28"),world)
	mesh_box(Vector3(0,-0.03,0),Vector3(12.15,0.12,6.15),Art.INK,world)
	var board_plane = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(12,6)
	board_plane.mesh = plane
	var printed = StandardMaterial3D.new()
	printed.albedo_texture = Art.BOARD
	printed.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	board_plane.material_override = printed
	board_plane.position.y = 0.132
	world.add_child(board_plane)
	for id in board.zones:
		var z = board.zones[id]
		var base = Color("686b5d") if z.inside else Color("46505b")
		if z.inside and z.dark: base = Color("3e514e")
		var floor_mesh = mesh_box(pos(id)+Vector3(0,0.06,0),Vector3(z.width*2-0.07,0.12,z.height*2-0.07),base,world)
		floors[id] = {"mesh":floor_mesh,"base":base}
	# Room and street boundaries use the same extents as the rules and hit testing.
	for a in board.zones:
		for b in board.zones:
			if a >= b: continue
			var edge = Content.border(board.zones[a],board.zones[b])
			if edge.is_empty(): continue
			var passage = false
			for pair in board.edges+board.doors:
				if a in pair and b in pair: passage = true; break
			if board.zones[a].inside or board.zones[b].inside:
				if passage:
					var center = (edge.from+edge.to)/2
					var opening = (edge.to-edge.from).normalized()*0.22
					wall_span(edge.from,center-opening)
					wall_span(center+opening,edge.to)
					if board.zones[a].inside and board.zones[b].inside:
						var vertical_wall = edge.direction.x != 0
						mesh_box(point_on_board(center)+Vector3(0,0.146,0),Vector3(0.16 if vertical_wall else 0.44,0.02,0.44 if vertical_wall else 0.16),Color("99886a"),world)
				else: wall_span(edge.from,edge.to)
			else:
				var p = point_on_board((edge.from+edge.to)/2)
				var size_ = (edge.to-edge.from)*2
				mesh_box(p+Vector3(0,0.135,0),Vector3(maxf(0.035,size_.x),0.014,maxf(0.035,size_.y)),Color("c4c3b5"),world)
		var r = Content.bounds(board.zones[a])
		if board.zones[a].inside:
			if r.position.x == 0: wall_span(r.position,Vector2(0,r.end.y))
			if r.position.y == 0: wall_span(r.position,Vector2(r.end.x,0))
			if r.end.x == 6: wall_span(Vector2(6,r.position.y),r.end)
			if r.end.y == 3: wall_span(Vector2(r.position.x,3),r.end)
	figures = Node3D.new()
	world.add_child(figures)

func material(color: Color) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.8
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
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

func point_on_board(point: Vector2) -> Vector3:
	return Vector3(point.x*2-6,0,point.y*2-3)

func wall_span(from: Vector2,to: Vector2) -> void:
	var size_ = (to-from).abs()*2
	mesh_box(point_on_board((from+to)/2)+Vector3(0,0.15,0),Vector3(maxf(0.055,size_.x),0.035,maxf(0.055,size_.y)),Art.INK,world)

func position_camera() -> void:
	if camera == null: return
	camera.position = Vector3(sin(angle)*cos(elevation),sin(elevation),cos(angle)*cos(elevation))*18
	camera.look_at(Vector3.ZERO,Vector3.FORWARD if elevation > 1.5 else Vector3.UP)
	camera.size = 1.0
	var projected = Rect2()
	var first = true
	for x in [-6.4,6.4]:
		for z in [-3.35,3.35]:
			for y in [0.0,1.20]:
				var point = camera.unproject_position(Vector3(x,y,z))
				if first: projected = Rect2(point,Vector2.ZERO); first = false
				else: projected = projected.expand(point)
	camera.size = maxf(projected.size.x/maxf(1.0,viewport.size.x*0.96),projected.size.y/maxf(1.0,viewport.size.y*0.94))*(zoom/8.4)

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
	for identity in piece_nodes:
		if is_instance_valid(piece_nodes[identity]): piece_positions[identity] = piece_nodes[identity].position
	clear(figures)
	miniatures.clear()
	piece_nodes.clear()
	var active = s.survivors[int(s.active)] if s.active >= 0 else {}
	var permitted = not active.is_empty() and active.owner == session.role and not s.paused and s.outcome == "" and s.pending.is_empty()
	var phase = "Partida pausada" if s.paused else ("Vitória" if s.outcome == "victory" else ("Derrota" if s.outcome == "defeat" else "Sua vez" if s.players[int(s.active_player)] == session.role else "Vez do amigo"))
	info.text = "Rodada %d · %s   |   Objetivos %d/2 · Caixas %d/2   →   Voltar à SAÍDA com todos" % [s.round,phase,2-s.objectives.size(),2-s.crates.size()]
	status.text = "Você controla os seis sobreviventes neste teste solo." if session.mode == "offline" else "Sala privada · você controla as peças de "+session.role
	for v in s.survivors:
		var action_count = str(v.actions)+(" ação" if v.actions == 1 else " ações")
		var text = v.name+"\n"+action_count
		if v.id == s.active: text = "▶ "+v.name+"\nATIVO · "+action_count
		elif v.escaped: text = v.name+"\nESCAPOU"
		elif v.id in s.done: text = v.name+"\nCONCLUÍDO"
		var locked = v.escaped or v.id in s.done or v.owner != session.role or s.paused or (s.active >= 0 and s.active != v.id)
		var b = button(text,func():
			equip_from = -1
			mode = "inspect"
			if session.view.active == -1: session.submit({"action":"activate","actor":v.id})
			else: message.text = "Esta é a peça ativa. Escolha uma ação à direita."
			,survivor_box,locked)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 84
		b.icon = Art.portrait(int(v.id))
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width",64)
		b.add_theme_color_override("icon_disabled_color",Color(0.60,0.60,0.60,1))
		b.add_theme_font_size_override("font_size",14)
		b.tooltip_text = "Ativar "+v.name if not locked else "Encerre a ativação atual antes de escolher outra peça."
		if v.id == s.active: b.add_theme_stylebox_override("normal",box_style(Art.PAPER,Color("42c8d4")))
	if s.active != last_actor:
		weapon_slot = 0
		equip_from = -1
		mode = "inspect"
		last_actor = s.active
	weapon_picker.clear()
	if active.is_empty():
		actor_portrait.modulate = Color(0.6,0.6,0.6,1)
		actor_title.text = "Nenhuma peça ativa"
		actor_stats.text = "Clique em um cartão abaixo do tabuleiro."
		weapon_info.text = ""
	else:
		actor_portrait.texture = Art.portrait(int(active.id))
		actor_portrait.modulate = Color.WHITE
		actor_title.text = active.name+" · ATIVO"
		actor_stats.text = "%d %s\nVIDA %d/3\nADRENALINA %d" % [active.actions,"AÇÃO" if active.actions == 1 else "AÇÕES",3-active.wounds,active.ap]
		if not defs.get(active.inventory[weapon_slot],{}).has("range"):
			for i in range(2):
				if defs.get(active.inventory[i],{}).has("range"): weapon_slot = i; break
		for i in range(2):
			var item = str(active.inventory[i])
			weapon_picker.add_item("Mão %d: %s" % [i+1,defs.get(item,{}).get("name","vazia")])
		weapon_picker.select(weapon_slot)
		var weapon = defs.get(active.inventory[weapon_slot],{})
		weapon_info.text = "%d dado(s) · acerta %d+ · dano %d" % [weapon.get("dice",0),weapon.get("accuracy",0),weapon.get("damage",0)] if weapon.has("range") else "Equipe uma arma em uma das mãos para atacar."
	var pending = not s.pending.is_empty()
	weapon_picker.visible = not active.is_empty() and not pending
	weapon_info.visible = not active.is_empty() and not pending
	weapon_picker.disabled = not permitted
	actions_box.visible = not pending
	var preview = preload("res://core/rules.gd").new()
	preview.s = s
	legal_zones = []
	if permitted and mode != "inspect": legal_zones = destinations(preview,active,mode)
	for entry in [["Mover","move"],["Atacar","attack"],["Abrir porta","open"],["Buscar","search"]]:
		var action = str(entry[1])
		var reason = action_reason(preview,active,action,permitted)
		var b = button(entry[0],func():
			if action == "search": session.submit({"action":"search"})
			else: set_mode(action),actions_box,not reason.is_empty())
		b.custom_minimum_size = Vector2(142,40)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.tooltip_text = reason if not reason.is_empty() else {"move":"Escolha uma zona verde no tabuleiro.","attack":"Escolha uma zona em alcance; depois confirme e lance os dados.","open":"Selecione uma porta destacada.","search":"Compre equipamento nesta sala; uma busca por ativação."}[action]
		if mode == action:
			b.add_theme_stylebox_override("normal",box_style(Art.RED))
			b.add_theme_color_override("font_color",Art.PAPER)
	if not active.is_empty():
		for entry in [["Coletar objetivo","objective",s.objectives],["Pegar arma especial","crate",s.crates]]:
			var action = str(entry[1])
			if active.zone in entry[2]: button(entry[0],func(): session.submit({"action":action}),actions_box,not permitted or active.actions <= 0)
		if active.zone == board.exit and s.objectives.is_empty() and s.crates.is_empty(): button("Fugir pela saída",func(): session.submit({"action":"escape"}),actions_box,not permitted)
	button("Encerrar",func(): mode = "inspect"; session.submit({"action":"end"}),actions_box,not permitted)
	render_inventory(active,permitted)
	decision_section.visible = pending or not s.dice.is_empty()
	dice_label.text = "Lance os dados" if pending and s.pending.kind == "roll" else "Dados: "+("—" if s.dice.is_empty() else "  ".join(s.dice.map(func(v): return str(v))))
	if pending:
		var p = s.pending
		var prompt = label(p.prompt,16)
		prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		decisions_box.add_child(prompt)
		if p.owner != session.role: decisions_box.add_child(label("Aguardando a escolha do amigo.",15))
		if p.kind == "roll":
			var roll_button = button("LANÇAR %d DADO(S)" % p.dice,func(): session.submit({"action":"roll"}),decisions_box,p.owner != session.role or s.paused)
			roll_button.custom_minimum_size.y = 54
			roll_button.add_theme_stylebox_override("normal",box_style(Art.RED))
			roll_button.add_theme_color_override("font_color",Art.PAPER)
		else:
			for value in s.get("choices",[]):
				var choice = str(value)
				var text = choice
				if p.kind == "loot": text = "Descartar carta" if choice == "discard" else (("Mão %d" % (int(choice)+1)) if int(choice) < 2 else ("Mochila %d" % (int(choice)-1)))
				elif p.kind == "wound": text = s.survivors[int(choice)].name
				elif p.kind in ["building","split"]: text = zone_name(choice)
				elif p.kind == "hit": text = "Zumbi #"+choice
				elif p.kind == "trade": text = "Aceitar" if choice == "yes" else "Recusar"
				button(text,func(): session.submit({"action":"choose","choice":choice}),decisions_box,p.owner != session.role or s.paused)
	update_guide(s,active)
	var messages = s.log.filter(func(line): return not str(line).begins_with("M0 em construção"))
	log_box.text = "\n".join(messages)
	var occupied = {}
	for v in s.survivors:
		if not v.escaped: draw_peg(v.zone,colors[int(v.id)],str(int(v.id)+1),occupied,v.id == s.active,0.8,"s"+str(v.id))
	for z in s.zombies:
		var color = {"walker":Color("bd6060"),"runner":Color("e78455"),"fatty":Color("9d4960"),"abomination":Color("713e58")}.get(z.type,Color.RED)
		draw_peg(z.zone,color,{"walker":"Z","runner":"R","fatty":"B","abomination":"A"}[z.type],occupied,false,0.95 if z.type == "fatty" else 0.72,"z"+str(z.id))
	for id in floors:
		var m = floors[id].mesh.material_override
		m.albedo_color = floors[id].base.lightened(0.13) if id == selected else floors[id].base
	for id in s.objectives: marker(id,Art.RED,"objective",Vector3(-0.55,0.18,-0.37))
	for id in s.crates: marker(id,Color("d2a040"),"crate",Vector3(-0.55,0.18,-0.37))
	marker(board.start,Art.TEAL,"exit",Vector3(1.30,0.18,-0.37))
	for id in board.spawns: marker(id,Art.RED,"spawn",Vector3(1.25,0.18,-0.37))
	for pair in board.doors:
		if not s.doors.get(door_key(pair[0],pair[1]),false):
			var edge = Content.border(board.zones[pair[0]],board.zones[pair[1]])
			var sideways = edge.direction.x != 0
			mesh_box(point_on_board((edge.from+edge.to)/2)+Vector3(0,0.27,0),Vector3(0.13 if sideways else 0.8,0.38,0.8 if sideways else 0.13),Color("cf9d58"),figures)

func zone_name(id: String) -> String:
	return board.zones[id].name

func destinations(preview,active: Dictionary,action: String) -> Array:
	if active.is_empty() or active.actions <= 0: return []
	var result = []
	if action == "move":
		if active.actions >= 1+preview.zombies_at(active.zone).size(): result = preview.neighbors(active.zone)
	elif action == "open":
		var tool = false
		for i in range(2): tool = tool or defs.get(active.inventory[i],{}).get("door",false)
		if tool:
			for pair in board.doors:
				if active.zone in pair and not preview.s.doors.get(door_key(pair[0],pair[1]),false): result.append(pair[1] if pair[0] == active.zone else pair[0])
	elif action == "attack":
		var weapon = defs.get(active.inventory[weapon_slot],{})
		if weapon.has("range"):
			for zone in board.zones:
				var d = preview.distance(active.zone,zone)
				if d >= weapon.range[0] and d <= weapon.range[1] and preview.visible(active.zone,zone): result.append(zone)
	return result

func action_reason(preview,active: Dictionary,action: String,permitted: bool) -> String:
	if active.is_empty(): return "Primeiro clique em um sobrevivente abaixo do tabuleiro."
	if not permitted: return "Aguarde a decisão pendente ou a sua vez."
	if active.actions <= 0: return "Sem ações restantes. Clique em Encerrar."
	if action in ["move","attack","open"] and destinations(preview,active,action).is_empty():
		return {"move":"Não há ações suficientes para sair desta zona com zumbis.","attack":"Equipe uma arma em uma das mãos para atacar.","open":"É preciso uma porta fechada adjacente e ferramenta equipada."}[action]
	if action == "search":
		if not board.zones[active.zone].inside: return "Buscar exige estar dentro de uma sala."
		if not preview.zombies_at(active.zone).is_empty(): return "Elimine os zumbis da sala antes de buscar."
		if active.searched: return "Esta peça já buscou nesta ativação."
	return ""

func set_mode(action: String) -> void:
	mode = action
	equip_from = -1
	message.text = ""
	refresh()

func update_guide(s: Dictionary,active: Dictionary) -> void:
	if not s.outcome.is_empty():
		guide_title.text = "Vitória!" if s.outcome == "victory" else "A missão terminou em derrota"
		guide_body.text = "Todos escaparam." if s.outcome == "victory" else "Um sobrevivente foi eliminado. O grupo perde junto."
	elif s.paused:
		guide_title.text = "Partida pausada"
		guide_body.text = s.pause_reason
	elif not s.pending.is_empty():
		guide_title.text = "3. Lance os dados" if s.pending.kind == "roll" else "Uma decisão precisa de você"
		guide_body.text = "Use o botão LANÇAR à direita. O jogo calcula e aplica o resultado." if s.pending.kind == "roll" else s.pending.prompt
		if s.pending.owner != session.role: guide_body.text = "Aguardando a decisão do amigo. Você pode acompanhar o tabuleiro."
	elif active.is_empty():
		guide_title.text = "1. Escolha um sobrevivente"
		guide_body.text = "Clique em um dos seis cartões abaixo do tabuleiro para começar sua ativação."
	elif active.actions <= 0:
		guide_title.text = "Encerre a ativação desta peça"
		guide_body.text = "Não há ações restantes. Clique em Encerrar à direita e escolha outra peça disponível."
	elif mode == "move":
		guide_title.text = "2. Clique em uma zona verde"
		guide_body.text = "As zonas destacadas são destinos legais. Esc cancela a seleção de movimento."
	elif mode == "attack":
		guide_title.text = "2. Escolha uma zona em alcance"
		guide_body.text = "As zonas em laranja podem ser atacadas. Clique, confira a prévia e confirme."
	elif mode == "open":
		guide_title.text = "2. Escolha a porta a abrir"
		guide_body.text = "Clique na sala destacada em laranja. Abrir pode revelar zumbis dentro do edifício."
	else:
		guide_title.text = active.name+" está ativo · "+str(active.actions)+" ações"
		guide_body.text = "Escolha Mover ou Atacar à direita. Na sala, você pode buscar equipamentos e coletar objetivos."

func render_inventory(active: Dictionary,permitted: bool) -> void:
	if active.is_empty():
		inventory_box.add_child(label("Primeiro ative uma peça na parte inferior da mesa.",17))
		return
	inventory_box.add_child(label("Reorganizar: clique no item e depois no destino (1 ação).",16))
	for i in range(5):
		var item = str(active.inventory[i])
		var text = ("Mão %d" % (i+1)) if i < 2 else ("Mochila %d" % (i-1))
		text += ": "+str(defs.get(item,{}).get("name","vazia"))
		if equip_from == i: text = "[MOVER ESTE ITEM] "+text
		var slot = i
		button(text,func():
			if equip_from < 0:
				equip_from = slot
				from_slot = slot
				refresh()
			else:
				var source = equip_from
				equip_from = -1
				session.submit({"action":"equip","from":source,"to":slot}),inventory_box,not permitted)
	var dual = CheckButton.new()
	dual.text = "Usar armas Dual no ataque (se permitido)"
	dual.button_pressed = use_dual
	dual.disabled = not permitted
	dual.toggled.connect(func(enabled): use_dual = enabled)
	inventory_box.add_child(dual)
	inventory_box.add_child(label("Para dar um item: selecione o slot acima e o destinatário.",15))
	var trade_row = HBoxContainer.new()
	inventory_box.add_child(trade_row)
	var options = OptionButton.new()
	for v in session.view.survivors: options.add_item(v.name,int(v.id))
	options.selected = trade_target
	options.item_selected.connect(func(i): trade_target = i)
	trade_row.add_child(options)
	button("Dar slot %d" % (from_slot+1),func(): session.submit({"action":"trade","other":trade_target,"slot":from_slot}); inventory_dialog.hide(),trade_row,not permitted)
	button("Descartar slot %d" % (from_slot+1),func(): session.submit({"action":"discard","actor":session.view.active,"slot":from_slot}),inventory_box,active.owner != session.role)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and mode != "inspect":
		mode = "inspect"
		message.text = "Seleção cancelada. Nenhuma ação foi gasta."
		refresh()

func max_ap(s: Dictionary) -> int:
	var result = 0
	for v in s.survivors: result = maxi(result,int(v.ap))
	return result

func door_key(a: String,b: String) -> String:
	return a+"|"+b if a < b else b+"|"+a

func draw_peg(zone: String,color: Color,text: String,occupied: Dictionary,active: bool,height: float,identity: String) -> void:
	var index = int(occupied.get(zone,0))
	occupied[zone] = index+1
	var columns = 4 if board.zones[zone].width >= 2 else 2
	if index >= columns*2: return # Further actors remain in authoritative state and decision lists.
	var p = pos(zone)+Vector3((index%columns-(columns-1)/2.0)*0.65,0.14,(index/columns-0.5)*0.58+0.35)
	if index >= 12: p.y += 0.15*floor(index/12.0)
	var piece = Node3D.new()
	piece.name = "Piece_"+identity
	figures.add_child(piece)
	piece.position = p
	piece_nodes[identity] = piece
	if piece_positions.has(identity) and not reduce_motion and piece_positions[identity].distance_to(p) > 0.01:
		piece.position = piece_positions[identity]+Vector3(0,0.12,0)
		piece.create_tween().tween_property(piece,"position",p,0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	piece_positions[identity] = p
	cylinder(Vector3(0,0.035,0),0.25,0.07,Art.INK,piece)
	cylinder(Vector3(0,0.08,0),0.235,0.045,Color("42d9e4") if active else color,piece)
	var model_id = "survivor_%02d" % int(text) if text.is_valid_int() else {"Z":"walker","R":"runner","B":"fatty","A":"fatty"}.get(text,"walker")
	var miniature = Art.miniature(model_id)
	miniature.position = Vector3(0,0.10,0)
	miniature.scale = Vector3.ONE*(0.88 if text.is_valid_int() else (0.95 if text == "B" else 0.87))
	miniature.rotation.y = 0.30
	piece.add_child(miniature)
	miniatures[model_id+"-"+str(index)] = miniature
	var l = Label3D.new()
	l.text = text
	l.font_size = 44
	l.pixel_size = 0.007
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = Vector3(0,1.13,0)
	l.modulate = Color("ffe6a4") if active else Color.WHITE
	piece.add_child(l)

func marker(zone: String,color: Color,text: String,offset: Vector3) -> void:
	var p = pos(zone)+offset
	mesh_box(p,Vector3(0.51,0.05,0.51),Art.INK,figures)
	var icon = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(0.48,0.48)
	icon.mesh = plane
	var m = material(color)
	m.albedo_color = Color.WHITE
	m.albedo_texture = load("res://assets/b/icons/"+text+".svg")
	icon.material_override = m
	icon.position = p+Vector3(0,0.027,0)
	figures.add_child(icon)

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
				var logical_point = Vector2((hit.x+6)/2,(hit.z+3)/2)
				if Content.bounds(board.zones[id]).has_point(logical_point):
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
	var lines = ["Zona: "+zone_name(zone),"Arma: "+str(weapon.get("name","nenhuma")),"Precisão: %d+ · Dano: %d · Dados base: %d" % [weapon.get("accuracy",0),weapon.get("damage",0),weapon.get("dice",0)]]
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
