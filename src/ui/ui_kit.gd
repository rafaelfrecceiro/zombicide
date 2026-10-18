extends RefCounted
const Art = preload("res://ui/comic_art.gd")
static var icons: Dictionary = {}

static func surface(bg: Color,border: Color = Color("354144"),padding: int = 10) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(4)
	s.set_content_margin_all(padding)
	return s

static func theme() -> Theme:
	var t = Theme.new()
	t.default_font_size = 16
	t.set_font("font","Button",Art.HEADER_FONT)
	t.set_font_size("font_size","Button",20)
	t.set_color("font_color","Label",Art.PAPER)
	t.set_color("default_color","RichTextLabel",Art.PAPER)
	for state in ["normal","hover","pressed","disabled"]:
		t.set_stylebox(state,"Button",surface({"normal":Art.PAPER,"hover":Color("fff3d9"),"pressed":Color("d3c4a7"),"disabled":Color("d6ceb9")}[state],Color("b3a68b"),9))
		var ink = Color("7d7c6f") if state == "disabled" else Art.INK
		t.set_color("font_"+state+"_color" if state != "normal" else "font_color","Button",ink)
		t.set_color("icon_"+state+"_color","Button",ink)
	t.set_color("font_focus_color","Button",Art.INK)
	var focus = surface(Color.TRANSPARENT,Color("278892"),9)
	focus.set_border_width_all(2)
	t.set_stylebox("focus","Button",focus)
	t.set_constant("h_separation","Button",8)
	t.set_stylebox("panel","TooltipPanel",surface(Color("102428"),Color("439aa2"),12))
	t.set_color("font_color","TooltipLabel",Art.PAPER)
	t.set_font_size("font_size","TooltipLabel",15)
	return t

static func role(b: Button,kind: String) -> void:
	b.set_meta("game_role",kind)
	b.mouse_default_cursor_shape = Control.CURSOR_ARROW if b.disabled else Control.CURSOR_POINTING_HAND
	var dark = kind == "quiet"
	var primary = kind == "primary"
	for state in ["normal","hover","pressed"]:
		var bg = Color("243034") if dark else Art.RED if primary else Art.PAPER
		if state == "hover": bg = bg.lightened(.10)
		if state == "pressed": bg = bg.darkened(.12)
		var style = surface(bg,Color("485355") if dark else bg.darkened(.18),7 if dark else 9)
		style.corner_radius_top_right = 12 if primary else 2
		style.corner_radius_bottom_left = 12 if primary else 2
		style.border_width_bottom = 3 if state != "pressed" else 1
		style.shadow_color = Color(0,0,0,.25)
		style.shadow_offset = Vector2(0,2)
		style.shadow_size = 2
		b.add_theme_stylebox_override(state,style)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color","icon_normal_color","icon_hover_color","icon_pressed_color"]:
		b.add_theme_color_override(state,Art.PAPER if dark or primary else Art.INK)

static func icon(id: String) -> Texture2D:
	if icons.has(id): return icons[id]
	var paths = {
		"move":'<path d="M4 12h16m-5-5 5 5-5 5M9 4v3M9 17v3"/>',
		"attack":'<circle cx="12" cy="12" r="7"/><path d="M12 2v6m0 8v6M2 12h6m8 0h6"/>',
		"open":'<path d="M5 21V3h14v18M5 3l10 3v15H5m6-9h1"/>',
		"search":'<circle cx="10" cy="10" r="6"/><path d="m15 15 6 6"/>',
		"end":'<path d="m4 12 5 5L20 6"/>',
		"bag":'<rect x="5" y="7" width="14" height="15" rx="3"/><path d="M9 7V3h6v4M8 14h8v5H8z"/>',
		"history":'<path d="M4 5h16v14H4zM8 9h8M8 13h6"/>',
		"help":'<circle cx="12" cy="12" r="9"/><path d="M9 9c0-4 7-4 6 0 0 2-3 2-3 5m0 3v1"/>',
		"settings":'<path d="M3 6h18M3 12h18M3 18h18M8 3v6m8 0v6M8 15v6"/>',
		"objective":'<path d="m6 6 12 12M18 6 6 18"/><circle cx="12" cy="12" r="10"/>',
		"crate":'<path d="m3 6 9-4 9 4v12l-9 4-9-4zm0 0 9 5 9-5M12 11v11"/>',
		"exit":'<path d="M10 3H4v18h6m3-14 5 5-5 5M9 12h12"/>',
		"dice":'<rect x="3" y="3" width="18" height="18" rx="3"/><path d="M7 7h.1M12 12h.1M17 17h.1"/>',
		"group":'<circle cx="8" cy="7" r="3"/><circle cx="17" cy="8" r="2"/><path d="M2 21v-4a6 6 0 0 1 12 0v4m3-7c3 0 5 2 5 5v2"/>',
	}
	if not paths.has(id): return null
	var svg = '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><g fill="none" stroke="white" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">'+paths[id]+'</g></svg>'
	var img = Image.new()
	if img.load_svg_from_string(svg) != OK: return null
	icons[id] = ImageTexture.create_from_image(img)
	return icons[id]

static func game_windows(t: Theme) -> void:
	var border = surface(Color("17262b"),Color("bd4c3b"),4)
	border.expand_margin_top = 42
	border.expand_margin_left = 5
	border.expand_margin_right = 5
	border.expand_margin_bottom = 5
	border.shadow_color = Color(0,0,0,.6)
	border.shadow_size = 16
	border.shadow_offset = Vector2(0,8)
	t.set_stylebox("embedded_border","Window",border)
	t.set_stylebox("embedded_unfocused_border","Window",border)
	t.set_font("title_font","Window",Art.HEADER_FONT)
	t.set_font_size("title_font_size","Window",26)
	t.set_color("title_color","Window",Art.PAPER)
	t.set_constant("title_height","Window",42)
	t.set_constant("close_v_offset","Window",24)
	t.set_stylebox("tab_selected","TabContainer",surface(Art.RED,Art.RED,12))
	t.set_stylebox("tab_unselected","TabContainer",surface(Color("26383c"),Color("26383c"),12))
	t.set_stylebox("panel","TabContainer",surface(Art.PAPER,Art.PAPER,14))
	t.set_color("font_selected_color","TabContainer",Art.PAPER)
	t.set_color("font_unselected_color","TabContainer",Art.PAPER)
	t.set_font("font","TabContainer",Art.HEADER_FONT)
	t.set_font_size("font_size","TabContainer",22)
	t.set_stylebox("normal","LineEdit",surface(Color("e2d6bd"),Color("ada48c"),10))
	t.set_stylebox("focus","LineEdit",surface(Color.TRANSPARENT,Art.TEAL,10))
	t.set_color("font_color","LineEdit",Art.INK)
