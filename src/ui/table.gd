extends Node3D

const Session = preload("res://net/session.gd")
const Content = preload("res://core/content.gd")
const Art = preload("res://ui/comic_art.gd")
const Kit = preload("res://ui/ui_kit.gd")
const Profiles = preload("res://core/survivors.gd")
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
var dice_tray: Control
var dice_summary: Label
var gallery: AcceptDialog
var zone_dialog: AcceptDialog
var zone_text: RichTextLabel
var attack_details: Dictionary = {}
var mission_labels: Dictionary = {}
var action_buttons: Dictionary = {}
var roster_buttons: Dictionary = {}
var guide_panel: PanelContainer
var side_card: PanelContainer
var action_meter: Label
var empty_hint: Label
var selection_hint: Label
var zone_context: Label
var hovered_zone = ""
var cancel_button: Button
var inventory_button: Button
var history_button: Button
var history_dialog: AcceptDialog
var guide_signature = ""
var guide_tween: Tween
var card_tween: Tween
var camera_tween: Tween
var camera_ready = false
var camera_goal: Dictionary = {}
var piece_signature = ""
var game_menu: CanvasLayer
var session_tabs: TabContainer
var session_feedback: Label
var new_dialog: ConfirmationDialog
var new_profiles: Array = []
var rule_preview

func _ready() -> void:
	build_ui()
	build_world()
	session = Session.new()
	session.name = "Session"
	add_child(session)
	session.changed.connect(func(): message.text = ""; refresh())
	session.rejected.connect(func(text):
		message.text = text
		session_feedback.text = text)
	refresh()
	game_menu = preload("res://ui/game_menu.gd").new()
	game_menu.table = self
	add_child(game_menu)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="): capture_path = arg.trim_prefix("--capture=")
	if not skip_intro:
		if not capture_path.is_empty():
			if "--capture-intro" in OS.get_cmdline_user_args(): help_dialog.popup_centered(Vector2i(640,440))
			capture.call_deferred()
		else: game_menu.show_menu.call_deferred()

func label(text: String,size: int = 16) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size",size)
	return l

func button(text: String,fn: Callable,parent: Node, disabled: bool = false) -> Button:
	var b = preload("res://ui/table_button.gd").new()
	b.reduce_motion_provider = func(): return reduce_motion
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
	var theme = preload("res://ui/table_layout.gd").build(self,ui)
	attack_dialog = ConfirmationDialog.new()
	attack_dialog.title = "Confirmar ataque"
	attack_dialog.ok_button_text = "Confirmar e preparar dados"
	attack_dialog.cancel_button_text = "Voltar"
	attack_dialog.min_size = Vector2i(470,200)
	ui.add_child(attack_dialog)
	attack_dialog.confirmed.connect(func(): session.submit(attack_candidate); attack_candidate = {})
	attack_dialog.canceled.connect(func(): attack_candidate = {})
	gallery = preload("res://ui/miniature_gallery.gd").new()
	ui.add_child(gallery)
	zone_dialog = AcceptDialog.new()
	zone_dialog.title = "Inspecionar zona"
	zone_dialog.ok_button_text = "Voltar à mesa"
	zone_dialog.min_size = Vector2i(510,360)
	ui.add_child(zone_dialog)
	zone_text = RichTextLabel.new()
	zone_text.custom_minimum_size = Vector2(510,330)
	zone_text.bbcode_enabled = false
	zone_text.add_theme_font_size_override("normal_font_size",17)
	zone_dialog.add_child(zone_text)
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
	session_dialog.title = "CENTRAL DA MISSÃO"
	session_dialog.ok_button_text = "Voltar"
	ui.add_child(session_dialog)
	new_dialog = ConfirmationDialog.new()
	new_dialog.title = "INICIAR OUTRA MISSÃO"
	new_dialog.dialog_text = "Substituir a mesa atual? O progresso que não foi salvo será perdido."
	new_dialog.ok_button_text = "Iniciar missão"
	new_dialog.cancel_button_text = "Voltar"
	new_dialog.confirmed.connect(begin_new_mission)
	ui.add_child(new_dialog)
	session_tabs = TabContainer.new()
	session_tabs.custom_minimum_size = Vector2(580,300)
	session_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var session_body = VBoxContainer.new()
	session_dialog.add_child(session_body)
	session_body.add_child(session_tabs)
	session_feedback = label("",14)
	session_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	session_body.add_child(session_feedback)
	var settings = VBoxContainer.new()
	settings.add_theme_constant_override("separation",8)
	settings.name = "MISSÃO"
	session_tabs.add_child(settings)
	button("Salvar missão",func():
		if session.save_game() == ERR_UNAUTHORIZED: session_feedback.text = "Só o anfitrião pode salvar a missão online.",settings)
	button("Continuar save",load_session_mission,settings)
	var friends = VBoxContainer.new()
	friends.name = "AMIGOS"
	friends.add_theme_constant_override("separation",12)
	session_tabs.add_child(friends)
	friends.add_child(label("Conexão privada de teste · 2 pessoas",17))
	friends.add_child(label("ENDEREÇO DO ANFITRIÃO",13))
	ip = LineEdit.new()
	ip.text = "127.0.0.1"
	ip.placeholder_text = "Endereço do anfitrião"
	friends.add_child(ip)
	friends.add_child(label("CONVITE PRIVADO",13))
	code = LineEdit.new()
	code.text = "mesa-amigos"
	code.placeholder_text = "Convite (mínimo 6 caracteres)"
	code.secret = true
	friends.add_child(code)
	button("Criar mesa online",func():
		var err = session.host(code.text)
		message.text = "Sala criada. Convide seu amigo." if err == OK else "Não foi possível criar sala (%d)." % err
		session_feedback.text = message.text
		if err == OK: close_session_to_table(),friends)
	button("Entrar / reconectar",func():
		var err = session.join(ip.text,code.text)
		message.text = "Conectando…" if err == OK else "Falha ao conectar (%d)." % err
		session_feedback.text = message.text
		if err == OK: close_session_to_table(),friends)
	button("Desconectar cliente",func(): session.disconnect_client(); session_dialog.hide(),friends)
	var options = VBoxContainer.new()
	options.name = "OPÇÕES"
	options.add_theme_constant_override("separation",14)
	session_tabs.add_child(options)
	var motion = CheckButton.new()
	motion.text = "Reduzir movimento da interface e peças"
	motion.toggled.connect(apply_reduce_motion)
	options.add_child(motion)
	options.add_child(label("Movimento reduzido afeta câmera, peças e feedback da interface.",14))
	button("Tela cheia / janela",func(): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN),options)
	settings.add_child(label("Salvar conserva a vez, o equipamento e as decisões pendentes.",15))
	settings.add_child(label("Laboratório M0 · duas fichas conferidas; decks ainda parciais.",14))
	var paper_theme = theme.duplicate()
	paper_theme.set_stylebox("panel","AcceptDialog",box_style(Art.PAPER))
	paper_theme.set_color("font_color","Label",Art.INK)
	paper_theme.set_color("default_color","RichTextLabel",Art.INK)
	Kit.game_windows(paper_theme)
	for dialog in [attack_dialog,help_dialog,inventory_dialog,session_dialog,zone_dialog,gallery,history_dialog,new_dialog]: dialog.theme = paper_theme
	for dialog in [attack_dialog,help_dialog,inventory_dialog,session_dialog,zone_dialog,gallery,history_dialog,new_dialog]: dialog.exclusive = true
	for dialog in [attack_dialog,help_dialog,inventory_dialog,session_dialog,zone_dialog,gallery,history_dialog,new_dialog]:
		dialog.add_theme_font_override("title_font",Art.HEADER_FONT)
		dialog.add_theme_font_size_override("title_font_size",26)

func build_world() -> void:
	world = Node3D.new()
	viewport.add_child(world)
	var environment = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("172125")
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
	var old_position = camera.position
	var old_rotation = camera.quaternion
	var old_size = camera.size
	if is_instance_valid(camera_tween): camera_tween.kill()
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
	camera_goal = {"position":camera.position,"quaternion":camera.quaternion,"size":camera.size}
	if camera_ready and not reduce_motion:
		camera.position = old_position
		camera.quaternion = old_rotation
		camera.size = old_size
		camera_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		camera_tween.tween_property(camera,"position",camera_goal.position,.22)
		camera_tween.tween_property(camera,"quaternion",camera_goal.quaternion,.22)
		camera_tween.tween_property(camera,"size",camera_goal.size,.22)
	camera_ready = true

func clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func refresh() -> void:
	if session == null or session.view.is_empty(): return
	var s = session.view
	ensure_controls()
	clear(inventory_box)
	clear(decisions_box)
	var active = s.survivors[int(s.active)] if s.active >= 0 else {}
	var permitted = not active.is_empty() and active.owner == session.role and not s.paused and s.outcome == "" and s.pending.is_empty()
	var phase = "Partida pausada" if s.paused else ("Vitória" if s.outcome == "victory" else ("Derrota" if s.outcome == "defeat" else "Sua vez" if s.players[int(s.active_player)] == session.role else "Vez do amigo"))
	info.text = "RODADA %02d   /   %s" % [s.round,phase.to_upper()]
	mission_labels.objective.text = "OBJETIVOS   %d / 2" % (2-s.objectives.size())
	mission_labels.crate.text = "CAIXAS   %d / 2" % (2-s.crates.size())
	var escaped = s.survivors.filter(func(v): return v.escaped).size()
	mission_labels.exit.text = "SAÍDA   %d / 6" % escaped
	status.text = "Solo · seis sobreviventes" if session.mode == "offline" else "Sala privada · "+session.role
	for v in s.survivors:
		var b = roster_buttons[int(v.id)]
		var action_count = str(v.actions)+(" ação" if v.actions == 1 else " ações")
		var state = "DISPONÍVEL"
		if v.id == s.active: state = "ATIVO"
		elif v.escaped: state = "ESCAPOU"
		elif v.id in s.done: state = "CONCLUÍDO"
		elif v.owner != session.role: state = "DO AMIGO"
		elif s.active >= 0 and s.active != v.id: state = "EM ESPERA"
		var locked = v.escaped or v.id in s.done or v.owner != session.role or s.paused or (s.active >= 0 and s.active != v.id)
		b.text = v.name+"  ·  "+action_count+"\n"+state
		b.disabled = locked
		b.mouse_default_cursor_shape = Control.CURSOR_ARROW if locked else Control.CURSOR_POINTING_HAND
		b.tooltip_text = ("Encerre a ativação atual antes de escolher outra peça." if s.active >= 0 and s.active != v.id else "Este sobrevivente já concluiu a ativação." if v.id in s.done else "Esta peça pertence ao amigo." if v.owner != session.role else "Partida pausada." if s.paused else "Ativar "+v.name+" · tecla "+str(int(v.id)+1))
		var selected_card = v.id == s.active
		var normal = Kit.surface(Color("d6f0e9") if selected_card else Art.PAPER,Color("52c7cc") if selected_card else colors[int(v.id)],10)
		normal.border_width_top = 4
		b.add_theme_stylebox_override("normal",normal)
		var locked_style = Kit.surface(Color("b2b4a7"),colors[int(v.id)].darkened(.25),10)
		locked_style.border_width_top = 4
		b.add_theme_stylebox_override("disabled",locked_style)
		b.add_theme_color_override("font_disabled_color",Color("475252"))
		b.add_theme_color_override("icon_disabled_color",Color(.8,.8,.8,1))
	if s.active != last_actor:
		weapon_slot = 0
		equip_from = -1
		mode = "inspect"
		last_actor = s.active
		if is_instance_valid(card_tween): card_tween.kill()
		if not reduce_motion:
			side_card.modulate = Color(.83,.91,.91,1)
			card_tween = create_tween()
			card_tween.tween_property(side_card,"modulate",Color.WHITE,.16)
		else: side_card.modulate = Color.WHITE
	weapon_picker.clear()
	if active.is_empty():
		actor_portrait.modulate = Color(0.6,0.6,0.6,1)
		actor_title.text = "SEU PRÓXIMO\nSOBREVIVENTE"
		actor_stats.text = "Escolha no grupo abaixo."
		weapon_info.text = ""
	else:
		actor_portrait.texture = Art.portrait(int(active.id))
		actor_portrait.modulate = Color.WHITE
		actor_title.text = active.name+" · ATIVO"
		actor_stats.text = "VIDA   %d / 3\nADRENALINA   %d" % [3-active.wounds,active.ap]
		var free_count = 0
		for value in active.free.values(): free_count += int(value)
		action_meter.text = "%d AÇÕES" % active.actions+(" + %d GRÁTIS" % free_count if free_count > 0 else "")
		action_meter.tooltip_text = "\n".join(active.skills.map(func(id): return Profiles.skill_name(id)))
		if not defs.get(active.inventory[weapon_slot],{}).has("range"):
			for i in range(2):
				if defs.get(active.inventory[i],{}).has("range"): weapon_slot = i; break
		for i in range(2):
			var item = str(active.inventory[i])
			weapon_picker.add_item("Mão %d: %s" % [i+1,defs.get(item,{}).get("name","vazia")])
		weapon_picker.select(weapon_slot)
		var weapon = defs.get(active.inventory[weapon_slot],{})
		weapon_info.text = "Base: %d dado(s) · acerta %d+ · dano %d" % [weapon.get("dice",0),weapon.get("accuracy",0),weapon.get("damage",0)] if weapon.has("range") else "Equipe uma arma em uma das mãos para atacar."
	action_meter.visible = not active.is_empty()
	empty_hint.visible = active.is_empty()
	inventory_button.visible = not active.is_empty()
	selection_hint.text = "M · mover    A · atacar    I · itens" if not active.is_empty() else "As regras são aplicadas pelo jogo. Você escolhe as ações e inicia os dados."
	selection_hint.tooltip_text = "Passe o mouse numa ação para ver sua condição."
	var pending = not s.pending.is_empty()
	if pending: selection_hint.text = "Espaço · lançar os dados" if s.pending.kind == "roll" else "Escolha uma opção para continuar."
	weapon_picker.visible = not active.is_empty() and not pending
	weapon_info.visible = not active.is_empty() and not pending
	weapon_picker.disabled = not permitted
	actions_box.visible = not pending and not active.is_empty()
	var preview = preload("res://core/rules.gd").new()
	preview.s = s
	rule_preview = preview
	legal_zones = []
	if permitted and mode != "inspect": legal_zones = destinations(preview,active,mode)
	for action in action_buttons:
		var b = action_buttons[action]
		var reason = action_reason(preview,active,action,permitted) if action in ["move","attack","open","search"] else "Aguarde sua vez ou a decisão pendente." if not permitted else ""
		b.visible = true
		if action == "objective": b.visible = not active.is_empty() and active.zone in s.objectives
		if action == "crate": b.visible = not active.is_empty() and active.zone in s.crates
		if action == "escape": b.visible = not active.is_empty() and active.zone == board.exit and s.objectives.is_empty() and s.crates.is_empty()
		b.disabled = not reason.is_empty() or (action in ["objective","crate","escape"] and not active.is_empty() and active.actions <= 0)
		var payment_type = defs.get(active.inventory[weapon_slot],{}).get("mode","ranged") if action == "attack" and not active.is_empty() else "move" if action == "move" else "generic"
		b.text = {"move":"Mover","attack":"Atacar","open":"Abrir porta","search":"Buscar","objective":"Coletar objetivo","crate":"Pegar arma especial","escape":"Fugir pela saída","end":"Encerrar"}[action]
		if not active.is_empty() and action in ["move","attack"] and preview.action_cost(active,payment_type) == 0: b.text += " · grátis"
		b.tooltip_text = reason if not reason.is_empty() else {"move":"M · Escolha uma zona verde. Custo: 1 ação + zumbis na origem.","attack":"A · Escolha uma zona em alcance. Confira a prévia antes de gastar a ação.","open":"Selecione uma porta destacada; requer ferramenta equipada.","search":"B · Busque equipamento nesta sala. Uma busca por ativação.","end":"Conclui esta ativação e libera o próximo sobrevivente.","objective":"Custa 1 ação; recebe 5 de adrenalina.","crate":"Custa 1 ação; recolhe uma arma especial.","escape":"Saia ao fim da ativação, com a zona livre."}[action]
		Kit.role(b,"primary" if mode == action else "paper")
	render_inventory(active,permitted)
	decision_section.visible = pending or not s.dice.is_empty()
	dice_label.text = "Lance os dados" if pending and s.pending.kind == "roll" else "Dados: "+("—" if s.dice.is_empty() else "  ".join(s.dice.map(func(v): return str(v))))
	dice_tray.display(s.dice,int(s.pending.get("dice",0)) if pending and s.pending.kind == "roll" else 0,reduce_motion)
	dice_tray.custom_minimum_size.y = 90 if pending and s.pending.kind == "roll" else 54
	dice_label.add_theme_font_size_override("font_size",24 if pending and s.pending.kind == "roll" else 18)
	dice_tray.visible = not s.dice.is_empty() or (pending and s.pending.kind == "roll")
	dice_summary.text = "Pronto para lançar. O jogo resolve os resultados." if pending and s.pending.kind == "roll" else last_roll_summary(s)
	dice_summary.visible = dice_tray.visible
	if pending:
		var p = s.pending
		var prompt = label(p.prompt,16)
		prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		decisions_box.add_child(prompt)
		if p.owner != session.role: decisions_box.add_child(label("Aguardando a escolha do amigo.",15))
		if p.kind == "roll":
			var roll_button = button("LANÇAR %d DADO(S)" % p.dice,func(): session.submit({"action":"roll"}),decisions_box,p.owner != session.role or s.paused)
			roll_button.custom_minimum_size.y = 54
			roll_button.icon = Kit.icon("dice")
			roll_button.tooltip_text = "Espaço · Lançar uma única vez e aplicar as regras."
			Kit.role(roll_button,"primary")
		else:
			var choices_parent: Node = decisions_box
			if s.get("choices",[]).size() > 4:
				var scroll = ScrollContainer.new()
				scroll.custom_minimum_size.y = 180
				scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
				decisions_box.add_child(scroll)
				var choices = VBoxContainer.new()
				choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				scroll.add_child(choices)
				choices_parent = choices
			for value in s.get("choices",[]):
				var choice = str(value)
				var text = choice
				if p.kind == "loot": text = "Descartar carta" if choice == "discard" else (("Mão %d" % (int(choice)+1)) if int(choice) < 2 else ("Mochila %d" % (int(choice)-1)))
				elif p.kind == "wound": text = s.survivors[int(choice)].name
				elif p.kind in ["building","split"]: text = zone_name(choice)
				elif p.kind == "hit": text = "Zumbi #"+choice
				elif p.kind == "trade": text = "Aceitar" if choice == "yes" else "Recusar"
				elif p.kind == "skill": text = Profiles.skill_label(choice)
				var choice_button = button(text,func(): session.submit({"action":"choose","choice":choice}),choices_parent,p.owner != session.role or s.paused)
				if p.kind == "skill": choice_button.tooltip_text = Profiles.skill_name(choice)
	update_guide(s,active)
	update_guide_motion()
	update_zone_context()
	if zone_dialog.visible: update_inspector()
	var messages = s.log.filter(func(line): return not str(line).begins_with("M0 em construção"))
	log_box.text = "\n\n".join(messages)
	if message.text.is_empty() and not messages.is_empty(): message.text = str(messages[-1])
	history_button.tooltip_text = str(messages[-1]) if not messages.is_empty() else "Nenhum evento na missão ainda."
	update_pieces(s)
	for id in floors:
		var m = floors[id].mesh.material_override
		m.albedo_color = floors[id].base.lightened(0.13) if id == selected else floors[id].base

func update_pieces(s: Dictionary) -> void:
	var signature = JSON.stringify([s.active,s.survivors.map(func(v): return [v.id,v.zone,v.inventory,v.escaped]),s.zombies,s.objectives,s.crates,s.doors,weapon_slot])
	if piece_signature == signature: return
	piece_signature = signature
	for identity in piece_nodes:
		if is_instance_valid(piece_nodes[identity]): piece_positions[identity] = piece_nodes[identity].position
	clear(figures)
	miniatures.clear()
	piece_nodes.clear()
	var occupied = {}
	for v in s.survivors:
		if not v.escaped: draw_peg(v.zone,colors[int(v.id)],str(int(v.id)+1),occupied,v.id == s.active,0.8,"s"+str(v.id))
	for z in s.zombies:
		var color = {"walker":Color("bd6060"),"runner":Color("e78455"),"fatty":Color("9d4960"),"abomination":Color("713e58")}.get(z.type,Color.RED)
		draw_peg(z.zone,color,{"walker":"Z","runner":"R","fatty":"B","abomination":"A"}[z.type],occupied,false,0.95 if z.type == "fatty" else 0.72,"z"+str(z.id))
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
	if active.is_empty(): return []
	var result = []
	if action == "move":
		if preview.can_pay(active,"move",preview.zombies_at(active.zone).size()): result = preview.neighbors(active.zone)
	elif action == "open":
		var tool = false
		for i in range(2): tool = tool or defs.get(active.inventory[i],{}).get("door",false)
		if tool:
			for pair in board.doors:
				if active.zone in pair and not preview.s.doors.get(door_key(pair[0],pair[1]),false): result.append(pair[1] if pair[0] == active.zone else pair[0])
	elif action == "attack":
		var weapon = defs.get(active.inventory[weapon_slot],{})
		if weapon.has("range") and preview.can_pay(active,weapon.mode):
			for zone in board.zones:
				var d = preview.distance(active.zone,zone)
				if d >= weapon.range[0] and d <= weapon.range[1] and preview.visible(active.zone,zone): result.append(zone)
	return result

func action_reason(preview,active: Dictionary,action: String,permitted: bool) -> String:
	if active.is_empty(): return "Primeiro clique em um sobrevivente abaixo do tabuleiro."
	if not permitted: return "Aguarde a decisão pendente ou a sua vez."
	var payment_type = defs.get(active.inventory[weapon_slot],{}).get("mode", "ranged") if action == "attack" else "move" if action == "move" else "search" if action == "search" else "generic"
	if not preview.can_pay(active,payment_type): return "Sem ações para esta ação. Use uma ação gratuita disponível ou encerre."
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
	elif active.actions <= 0 and active.free.values().all(func(value): return value <= 0):
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
	if not event is InputEventKey or not event.pressed or event.echo: return
	for dialog in [help_dialog,inventory_dialog,session_dialog,attack_dialog,gallery,zone_dialog,history_dialog,new_dialog]:
		if dialog.visible: return
	if game_menu != null and game_menu.open:
		if event.keycode == KEY_ESCAPE: game_menu.hide_menu()
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_ESCAPE and mode == "inspect": game_menu.show_menu(); get_viewport().set_input_as_handled(); return
	if get_viewport().gui_get_focus_owner() is LineEdit: return
	if event.keycode == KEY_ESCAPE and mode != "inspect": cancel_selection()
	elif event.keycode >= KEY_1 and event.keycode <= KEY_6:
		var b = roster_buttons.get(int(event.keycode-KEY_1))
		if b != null and not b.disabled: b.pressed.emit()
	elif event.keycode == KEY_I:
		if inventory_button.is_visible_in_tree(): inventory_button.pressed.emit()
	elif event.keycode == KEY_SPACE and session.view.pending.get("kind","") == "roll" and session.view.pending.owner == session.role:
		session.submit({"action":"roll"})
	elif event.keycode in [KEY_M,KEY_A,KEY_B]:
		var action = {KEY_M:"move",KEY_A:"attack",KEY_B:"search"}[event.keycode]
		var b = action_buttons[action]
		if b.is_visible_in_tree() and not b.disabled: b.pressed.emit()
	else: return
	get_viewport().set_input_as_handled()

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
		var motion_tween = piece.create_tween()
		piece.set_meta("motion_tween",motion_tween)
		motion_tween.tween_property(piece,"position",p,0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	piece_positions[identity] = p
	cylinder(Vector3(0,0.035,0),0.25,0.07,Art.INK,piece)
	cylinder(Vector3(0,0.08,0),0.235,0.045,Color("42d9e4") if active else color,piece)
	var model_id = "survivor_%02d" % int(text) if text.is_valid_int() else {"Z":"walker","R":"runner","B":"fatty","A":"fatty"}.get(text,"walker")
	var equipped = ""
	if text.is_valid_int():
		var id = int(text)-1
		equipped = session.view.survivors[id].inventory[weapon_slot if session.view.active == id else 0]
	var miniature = Art.miniature(model_id,equipped)
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
	if event is InputEventMouseMotion:
		var ray = camera.project_ray_origin(event.position)
		var hit = Plane(Vector3.UP,.12).intersects_ray(ray,camera.project_ray_normal(event.position))
		hovered_zone = ""
		if hit != null:
			for id in board.zones:
				if Content.bounds(board.zones[id]).has_point(Vector2((hit.x+6)/2,(hit.z+3)/2)): hovered_zone = id; break
		update_zone_context()
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
	var preview = preload("res://core/rules.gd").new()
	preview.s = s
	attack_details = preview.attack_info(attack_candidate,v,zone)
	if not attack_details.ok:
		message.text = attack_details.error
		attack_candidate = {}
		return
	var allies = s.survivors.filter(func(other): return not other.escaped and other.zone == zone and other.id != v.id)
	var targets = s.zombies.filter(func(z): return z.zone == zone)
	var lines = ["ALVO · "+zone_name(zone),"%d zumbi(s) · %d outro(s) sobrevivente(s)" % [targets.size(),allies.size()],"",str(attack_details.name).to_upper(),"Custo: %d ação · Distância: %d zona(s)" % [attack_details.cost,attack_details.distance],"%d dado(s) · Precisão %d+ · Dano por acerto %d" % [attack_details.dice,attack_details.accuracy,attack_details.damage],"Gera ruído" if attack_details.noise else "Ataque silencioso"]
	var resistant = targets.filter(func(z): return Content.threshold(z.type) > attack_details.damage).size()
	if resistant > 0: lines.append("%d alvo(s) exigem dano maior que %d por acerto." % [resistant,attack_details.damage])
	if not allies.is_empty() and weapon.get("mode","") == "ranged": lines.append("ATENÇÃO: há colegas na zona; erros podem causar fogo amigo.")
	if v.inventory[weapon_slot] == "molotov": lines.append("Molotov elimina todos os atores na zona, incluindo sobreviventes.")
	lines.append("\nConfirme para gastar a ação e preparar os dados." if attack_details.dice > 0 else "\nConfirme para gastar a ação e resolver o efeito.")
	attack_dialog.dialog_text = "\n".join(lines)
	attack_dialog.popup_centered()

func last_roll_summary(s: Dictionary) -> String:
	for i in range(s.log.size()-1,-1,-1):
		var entry = str(s.log[i])
		if entry.begins_with("Dados:") and entry.contains("→"):
			var count_ = entry.get_slice("→",1).strip_edges().get_slice(" ",0).to_int()
			return "%d %s · detalhes no Histórico" % [count_,"acerto" if count_ == 1 else "acertos"]
	return "Resultado da última rolagem."

func inspect_zone() -> void:
	update_inspector()
	zone_dialog.popup_centered_clamped(Vector2i(560,420),.90)

func update_inspector() -> void:
	if session == null or session.view.is_empty() or not board.zones.has(selected): return
	var s = session.view
	zone_dialog.title = zone_name(selected)+" · todos os atores"
	var lines = [zone_name(selected).to_upper(),"SALA" if board.zones[selected].inside else "RUA",""]
	var survivors = s.survivors.filter(func(v): return not v.escaped and v.zone == selected)
	var zombies = s.zombies.filter(func(z): return z.zone == selected)
	lines.append("SOBREVIVENTES · %d" % survivors.size())
	for v in survivors: lines.append("%s · vida %d/3 · %s%s" % [v.name,3-v.wounds,v.owner," · ATIVO" if v.id == s.active else ""])
	lines.append("\nZUMBIS · %d" % zombies.size())
	for z in zombies: lines.append("#%d · %s" % [z.id,{"walker":"Walker / comum","runner":"Runner / corredor","fatty":"Fatty / bruto","abomination":"Abominação"}.get(z.type,z.type)])
	if survivors.is_empty() and zombies.is_empty(): lines.append("Zona vazia.")
	lines.append("\nA contagem inclui peças resumidas visualmente no tabuleiro.")
	zone_text.text = "\n".join(lines)

func capture() -> void:
	for i in range(8): await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var err = get_viewport().get_texture().get_image().save_png(capture_path)
	print("CAPTURE ",err," ",capture_path)
	get_tree().quit(0 if err == OK else 1)

func ensure_controls() -> void:
	if not roster_buttons.is_empty(): return
	for i in range(6):
		var id = i
		var b = button("",func(): activate_actor(id),survivor_box)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0,88)
		b.icon = Art.portrait(i)
		b.expand_icon = true
		for state in ["icon_normal_color","icon_hover_color","icon_pressed_color","icon_focus_color"]: b.add_theme_color_override(state,Color.WHITE)
		b.add_theme_constant_override("icon_max_width",58)
		b.add_theme_font_size_override("font_size",18)
		roster_buttons[i] = b
	for entry in [["Mover","move"],["Atacar","attack"],["Abrir porta","open"],["Buscar","search"],["Coletar objetivo","objective"],["Pegar arma especial","crate"],["Fugir pela saída","escape"],["Encerrar","end"]]:
		var action = str(entry[1])
		var b = button(entry[0],func():
			if action in ["move","attack","open"]: set_mode(action)
			else:
				mode = "inspect"
				session.submit({"action":action}),actions_box)
		b.custom_minimum_size = Vector2(138,42)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.icon = Kit.icon(action)
		action_buttons[action] = b

func activate_actor(id: int) -> void:
	if roster_buttons[id].disabled: return
	equip_from = -1
	mode = "inspect"
	if session.view.active == -1: session.submit({"action":"activate","actor":id})
	else: message.text = "Esta é a peça ativa. Escolha uma ação à direita."

func cancel_selection() -> void:
	mode = "inspect"
	message.text = "Seleção cancelada. Nenhuma ação foi gasta."
	refresh()

func update_guide_motion() -> void:
	cancel_button.visible = mode != "inspect" and session.view.pending.is_empty()
	var signature = guide_title.text+guide_body.text
	if guide_signature == signature: return
	guide_signature = signature
	if is_instance_valid(guide_tween): guide_tween.kill()
	if reduce_motion: guide_panel.modulate = Color.WHITE; return
	guide_panel.modulate = Color(.72,.87,.88,1)
	guide_tween = create_tween()
	guide_tween.tween_property(guide_panel,"modulate",Color.WHITE,.14)

func update_zone_context() -> void:
	if session == null or session.view.is_empty(): return
	var id = hovered_zone if not hovered_zone.is_empty() else selected
	var s = session.view
	var count_ = s.zombies.filter(func(z): return z.zone == id).size()
	zone_context.text = zone_name(id)+" · %d zumbis" % count_
	zone_context.tooltip_text = "Zona selecionada · use Inspecionar zona para ver todos os atores. Roda do mouse: zoom."

func apply_reduce_motion(enabled: bool) -> void:
	reduce_motion = enabled
	if not enabled: return
	if is_instance_valid(guide_tween): guide_tween.kill()
	if is_instance_valid(card_tween): card_tween.kill()
	guide_panel.modulate = Color.WHITE
	side_card.modulate = Color.WHITE
	if is_instance_valid(camera_tween): camera_tween.kill()
	for property in camera_goal: camera.set(property,camera_goal[property])
	for id in piece_nodes:
		var piece = piece_nodes[id]
		var tween = piece.get_meta("motion_tween") if piece.has_meta("motion_tween") else null
		if is_instance_valid(tween): tween.kill()
		piece.position = piece_positions[id]
	for b in roster_buttons.values()+action_buttons.values(): b.reset_motion()
	dice_tray.reduce_motion = true
	dice_tray.queue_redraw()

func close_session_to_table() -> void:
	session_dialog.hide()
	game_menu.hide_menu()

func load_session_mission() -> void:
	if session.mode == "client":
		session_feedback.text = "Só o anfitrião pode restaurar a missão online."
		return
	if session.load_game(): close_session_to_table()

func request_new_mission(with_profiles: bool) -> void:
	if session.mode != "offline": return
	new_profiles = ["amy","","","elle","",""] if with_profiles else []
	if session.view.revision > 0: new_dialog.popup_centered()
	else: begin_new_mission()

func begin_new_mission() -> void:
	if session.mode != "offline": return
	session.chosen_profiles = new_profiles.duplicate()
	session.rules.start(0,false,new_profiles)
	mode = "inspect"
	last_actor = -1
	piece_signature = ""
	piece_positions.clear()
	session.refresh()
	game_menu.hide_menu()
