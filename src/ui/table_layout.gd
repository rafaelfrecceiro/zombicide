extends RefCounted
const Art = preload("res://ui/comic_art.gd")
const Kit = preload("res://ui/ui_kit.gd")

static func heading(t,text: String,size_: int = 22) -> Label:
	var l = t.label(text,size_)
	l.add_theme_font_override("font",Art.HEADER_FONT)
	return l

static func quiet(t,text: String,fn: Callable,parent: Node,icon_id: String = "") -> Button:
	var b = t.button(text,fn,parent)
	Kit.role(b,"quiet")
	b.icon = Kit.icon(icon_id)
	return b

static func build(t,ui: CanvasLayer) -> Theme:
	var root = PanelContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_stylebox_override("panel",Kit.surface(Color("11191c"),Color("11191c"),14))
	ui.add_child(root)
	var theme = Kit.theme()
	root.theme = theme
	var layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation",8)
	root.add_child(layout)
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation",12)
	layout.add_child(header)
	var brand = VBoxContainer.new()
	brand.add_theme_constant_override("separation",-3)
	header.add_child(brand)
	t.title = heading(t,"ZOMBICIDE",32)
	brand.add_child(t.title)
	var subtitle = t.label("2ª EDIÇÃO   /   QUADRINHOS URBANOS",11)
	subtitle.modulate = Color("a0b2b5")
	brand.add_child(subtitle)
	t.info = heading(t,"",20)
	t.info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(t.info)
	quiet(t,"Como jogar",func(): t.help_dialog.popup_centered(Vector2i(640,440)),header,"help")
	quiet(t,"Miniaturas",func(): t.gallery.popup_centered_clamped(Vector2i(980,540),.92),header)
	quiet(t,"Partida",func(): t.session_dialog.popup_centered(Vector2i(520,510)),header,"settings")
	var mission = HBoxContainer.new()
	mission.add_theme_constant_override("separation",8)
	layout.add_child(mission)
	for id in ["objective","crate","exit"]:
		var tile = PanelContainer.new()
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.add_theme_stylebox_override("panel",Kit.surface(Color("1d292c"),Color("304043"),8))
		mission.add_child(tile)
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation",10)
		tile.add_child(row)
		var icon = TextureRect.new()
		icon.texture = Kit.icon(id)
		icon.custom_minimum_size = Vector2(20,20)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.modulate = Color("edb97a") if id == "crate" else Color("ed9488") if id == "objective" else Color("79c6cb")
		row.add_child(icon)
		var text = heading(t,"",18)
		row.add_child(text)
		t.mission_labels[id] = text
	var badge = quiet(t,"M0 · LAB",func(): t.help_dialog.popup_centered(Vector2i(640,440)),mission)
	badge.tooltip_text = "Amostra em desenvolvimento: fichas, habilidades e baralhos ainda incompletos."
	badge.add_theme_font_size_override("font_size",16)
	var main = HBoxContainer.new()
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation",14)
	layout.add_child(main)
	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation",8)
	main.add_child(left)
	t.guide_panel = PanelContainer.new()
	var guide_style = Kit.surface(Color("18383d"),Color("30636a"),8)
	guide_style.border_width_left = 4
	t.guide_panel.add_theme_stylebox_override("panel",guide_style)
	left.add_child(t.guide_panel)
	var guide_row = HBoxContainer.new()
	guide_row.add_theme_constant_override("separation",14)
	t.guide_panel.add_child(guide_row)
	var instruction = VBoxContainer.new()
	instruction.add_theme_constant_override("separation",2)
	instruction.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	guide_row.add_child(instruction)
	t.guide_title = heading(t,"",24)
	instruction.add_child(t.guide_title)
	t.guide_body = t.label("",14)
	t.guide_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.guide_body.modulate = Color("bcd7d6")
	instruction.add_child(t.guide_body)
	t.cancel_button = quiet(t,"Cancelar · Esc",func(): t.cancel_selection(),guide_row)
	t.cancel_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var stack = Control.new()
	stack.custom_minimum_size = Vector2(420,260)
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(stack)
	t.field = SubViewportContainer.new()
	t.field.stretch = true
	t.field.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stack.add_child(t.field)
	t.viewport = SubViewport.new()
	t.viewport.size = Vector2i(920,560)
	t.viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	t.field.add_child(t.viewport)
	t.field.gui_input.connect(t.board_input)
	t.field.mouse_exited.connect(func(): t.hovered_zone = ""; t.update_zone_context())
	t.field.resized.connect(func(): t.position_camera.call_deferred())
	t.hints = preload("res://ui/board_hints.gd").new()
	t.hints.table = t
	t.hints.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.hints.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stack.add_child(t.hints)
	var camera_row = HBoxContainer.new()
	camera_row.add_theme_constant_override("separation",6)
	left.add_child(camera_row)
	quiet(t,"Vista de mesa",func(): t.elevation = .94; t.position_camera(),camera_row)
	quiet(t,"Vista superior",func(): t.elevation = 1.52; t.position_camera(),camera_row)
	quiet(t,"↶",func(): t.angle -= .25; t.position_camera(),camera_row).tooltip_text = "Girar a mesa para a esquerda"
	quiet(t,"↷",func(): t.angle += .25; t.position_camera(),camera_row).tooltip_text = "Girar a mesa para a direita"
	quiet(t,"Inspecionar zona",func(): t.inspect_zone(),camera_row)
	for child in camera_row.get_children(): child.add_theme_font_size_override("font_size",17)
	t.zone_context = t.label("",13)
	t.zone_context.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	t.zone_context.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.zone_context.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	t.zone_context.modulate = Color("a0b9bb")
	camera_row.add_child(t.zone_context)
	var side = VBoxContainer.new()
	side.custom_minimum_size.x = 310
	side.add_theme_constant_override("separation",10)
	main.add_child(side)
	t.side_card = PanelContainer.new()
	t.side_card.add_theme_stylebox_override("panel",Kit.surface(Art.PAPER,Color("b7ab90"),12))
	var card_theme = theme.duplicate()
	card_theme.set_color("font_color","Label",Art.INK)
	t.side_card.theme = card_theme
	side.add_child(t.side_card)
	t.panel = VBoxContainer.new()
	t.panel.add_theme_constant_override("separation",8)
	t.side_card.add_child(t.panel)
	var actor_header = HBoxContainer.new()
	actor_header.add_theme_constant_override("separation",12)
	t.panel.add_child(actor_header)
	t.actor_portrait = TextureRect.new()
	t.actor_portrait.texture = Art.portrait(0)
	t.actor_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.actor_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	t.actor_portrait.custom_minimum_size = Vector2(76,88)
	actor_header.add_child(t.actor_portrait)
	var actor_summary = VBoxContainer.new()
	actor_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actor_header.add_child(actor_summary)
	t.actor_title = heading(t,"",24)
	t.actor_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	actor_summary.add_child(t.actor_title)
	t.actor_stats = t.label("",14)
	t.actor_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	actor_summary.add_child(t.actor_stats)
	t.action_meter = heading(t,"",23)
	t.action_meter.add_theme_color_override("font_color",Color("277e86"))
	t.panel.add_child(t.action_meter)
	t.empty_hint = t.label("1   Escolha um sobrevivente abaixo.\n\n2   Use as ações da peça.\n\n3   Encerre e passe à próxima.",15)
	t.panel.add_child(t.empty_hint)
	t.decision_section = VBoxContainer.new()
	t.decision_section.add_theme_constant_override("separation",6)
	t.panel.add_child(t.decision_section)
	t.dice_label = heading(t,"",24)
	t.decision_section.add_child(t.dice_label)
	t.dice_tray = preload("res://ui/dice_tray.gd").new()
	t.decision_section.add_child(t.dice_tray)
	t.dice_summary = t.label("",14)
	t.dice_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.decision_section.add_child(t.dice_summary)
	t.decisions_box = VBoxContainer.new()
	t.decisions_box.add_theme_constant_override("separation",8)
	t.decision_section.add_child(t.decisions_box)
	t.weapon_picker = OptionButton.new()
	t.weapon_picker.item_selected.connect(func(index): t.weapon_slot = index; t.refresh())
	t.panel.add_child(t.weapon_picker)
	t.weapon_info = t.label("",14)
	t.weapon_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.panel.add_child(t.weapon_info)
	t.actions_box = GridContainer.new()
	t.actions_box.columns = 2
	t.actions_box.add_theme_constant_override("h_separation",8)
	t.actions_box.add_theme_constant_override("v_separation",8)
	t.panel.add_child(t.actions_box)
	t.inventory_button = t.button("Inventário / trocar",func(): t.inventory_dialog.popup_centered(Vector2i(630,550)),t.panel)
	t.inventory_button.icon = Kit.icon("bag")
	t.inventory_button.tooltip_text = "I · Equipar, reorganizar ou trocar itens."
	t.selection_hint = t.label("",14)
	t.selection_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.selection_hint.modulate = Color("a0b9bb")
	side.add_child(t.selection_hint)
	var roster_header = HBoxContainer.new()
	layout.add_child(roster_header)
	var roster_title = heading(t,"SEU GRUPO",19)
	roster_header.add_child(roster_title)
	var roster_hint = t.label("Uma ativação por vez  ·  teclas 1–6 para escolher",13)
	roster_hint.modulate = Color("9cafb1")
	roster_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roster_header.add_child(roster_hint)
	t.history_button = quiet(t,"Histórico",func(): t.history_dialog.popup_centered_clamped(Vector2i(760,420),.9),roster_header,"history")
	t.history_button.add_theme_font_size_override("font_size",17)
	t.survivor_box = HBoxContainer.new()
	t.survivor_box.add_theme_constant_override("separation",8)
	layout.add_child(t.survivor_box)
	var footer = HBoxContainer.new()
	layout.add_child(footer)
	t.message = t.label("",14)
	t.message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.message.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	t.message.custom_minimum_size.y = 20
	t.message.modulate = Color("f3bf8e")
	footer.add_child(t.message)
	t.status = t.label("",12)
	t.status.modulate = Color("92aaad")
	footer.add_child(t.status)
	t.history_dialog = AcceptDialog.new()
	t.history_dialog.title = "Histórico da missão"
	t.history_dialog.ok_button_text = "Voltar à mesa"
	ui.add_child(t.history_dialog)
	t.log_box = RichTextLabel.new()
	t.log_box.custom_minimum_size = Vector2(670,330)
	t.log_box.scroll_following = true
	t.log_box.add_theme_font_size_override("normal_font_size",16)
	t.history_dialog.add_child(t.log_box)
	return theme
