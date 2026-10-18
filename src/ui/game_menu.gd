extends CanvasLayer
const Art = preload("res://ui/comic_art.gd")
const Kit = preload("res://ui/ui_kit.gd")
var table
var screen: Control
var study_profiles: CheckButton
var new_button: Button
var return_button: Button
var fade: Tween
var open = false

func _ready() -> void:
	layer = 20
	screen = Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen)
	screen.theme = Kit.theme()
	var bg = TextureRect.new()
	bg.texture = Art.BOARD
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.modulate = Color(.30,.34,.35,1)
	screen.add_child(bg)
	var ink = ColorRect.new()
	ink.color = Color(.025,.045,.055,.84)
	ink.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(ink)
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right"]: margin.add_theme_constant_override("margin_"+side,64)
	for side in ["top","bottom"]: margin.add_theme_constant_override("margin_"+side,46)
	screen.add_child(margin)
	var vertical = VBoxContainer.new()
	vertical.add_theme_constant_override("separation",20)
	margin.add_child(vertical)
	var eyebrow = table.label("COOPERATIVO   /   MESA DIGITAL   /   2ª EDIÇÃO",15)
	eyebrow.modulate = Color("78b9bd")
	vertical.add_child(eyebrow)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation",62)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vertical.add_child(row)
	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation",12)
	row.add_child(left)
	var title_ = table.label("ZOMBICIDE",82)
	title_.add_theme_font_override("font",Art.HEADER_FONT)
	left.add_child(title_)
	var line = ColorRect.new()
	line.color = Art.RED
	line.custom_minimum_size = Vector2(90,5)
	line.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left.add_child(line)
	var tagline = table.label("Planeje em grupo.\nFaça cada ação valer.",21)
	tagline.modulate = Color("acbab5")
	left.add_child(tagline)
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 12
	left.add_child(spacer)
	new_button = menu_button("INICIAR MISSÃO","attack",func(): table.request_new_mission(study_profiles.button_pressed),left,true)
	return_button = menu_button("VOLTAR À MESA","exit",hide_menu,left)
	menu_button("CARREGAR MISSÃO","history",func(): session_page(0),left)
	menu_button("JOGAR COM AMIGO","group",func(): session_page(1),left)
	menu_button("OPÇÕES","settings",func(): session_page(2),left)
	var right = PanelContainer.new()
	right.custom_minimum_size.x = 400
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var panel = Kit.surface(Art.PAPER,Color("b3a384"),22)
	panel.border_width_top = 7
	panel.border_color = Art.RED
	right.add_theme_stylebox_override("panel",panel)
	row.add_child(right)
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation",14)
	right.add_child(content)
	var local_theme = Kit.theme()
	local_theme.set_color("font_color","Label",Art.INK)
	local_theme.set_color("font_color","CheckButton",Art.INK)
	right.theme = local_theme
	var chapter = table.label("MISSÃO 00",20)
	chapter.add_theme_font_override("font",Art.HEADER_FONT)
	chapter.add_theme_color_override("font_color",Art.RED)
	content.add_child(chapter)
	var mission = table.label("COLETAR\nE ESCAPAR",48)
	mission.add_theme_font_override("font",Art.HEADER_FONT)
	content.add_child(mission)
	content.add_child(table.label("FÁCIL     /     ~30 MIN     /     6 SOBREVIVENTES",14))
	var objective = table.label("Recolha os objetivos e as caixas de armas. Depois, leve todo o grupo à saída livre de zumbis.",17)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(objective)
	content.add_child(HSeparator.new())
	study_profiles = CheckButton.new()
	study_profiles.text = "Usar fichas conferidas: Amy e Elle"
	study_profiles.button_pressed = true
	study_profiles.add_theme_font_size_override("font_size",16)
	content.add_child(study_profiles)
	var note = table.label("M0 EM CONSTRUÇÃO\nDuas fichas conferidas; quatro peões e baralhos de laboratório. Retratos e modelos são estudos visuais.",13)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.modulate = Color("666b60")
	content.add_child(note)
	var footer = table.label("QUADRINHOS URBANOS     ·     DECISÕES SUAS, REGRAS AUTOMATIZADAS",13)
	footer.modulate = Color("829d9e")
	vertical.add_child(footer)
	screen.hide()

func menu_button(text: String,icon: String,fn: Callable,parent: Node,primary: bool = false) -> Button:
	var b = table.button(text,fn,parent)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size.y = 62
	b.add_theme_font_size_override("font_size",28)
	b.icon = Kit.icon(icon)
	Kit.role(b,"primary" if primary else "quiet")
	return b

func session_page(index: int) -> void:
	if index == 1 and table.session.mode == "offline": table.session.chosen_profiles = ["amy","","","elle","",""] if study_profiles.button_pressed else []
	table.session_tabs.current_tab = index
	table.session_dialog.popup_centered_clamped(Vector2i(650,470),.9)

func show_menu() -> void:
	open = true
	screen.show()
	new_button.disabled = table.session.mode != "offline"
	new_button.tooltip_text = "Para iniciar outra missão, saia da sala online." if new_button.disabled else "Preparar uma nova mesa local."
	screen.modulate = Color.WHITE
	if not table.reduce_motion:
		screen.modulate.a = 0
		if is_instance_valid(fade): fade.kill()
		fade = create_tween()
		fade.tween_property(screen,"modulate:a",1.0,.18)
	new_button.grab_focus()

func hide_menu() -> void:
	if is_instance_valid(fade): fade.kill()
	open = false
	screen.hide()
	table.roster_buttons[0].grab_focus()
