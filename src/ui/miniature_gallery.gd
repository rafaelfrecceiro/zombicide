extends AcceptDialog
## Inspection window for actual imported GLBs, not a generated concept image.
const Art = preload("res://ui/comic_art.gd")
var viewport: SubViewport
var figures: Node3D
var heading: Label
var camera: Camera3D
var angle = 0.0

func _ready() -> void:
	title = "Miniaturas · estudo B-002"
	ok_button_text = "Voltar à mesa"
	min_size = Vector2i(760,480)
	var layout = VBoxContainer.new()
	add_child(layout)
	heading = Label.new()
	heading.text = "QUADRINHOS URBANOS · QUATRO SILHUETAS EM POSES FIXAS"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size",20)
	layout.add_child(heading)
	var field = SubViewportContainer.new()
	field.stretch = true
	field.custom_minimum_size = Vector2(740,340)
	field.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(field)
	viewport = SubViewport.new()
	viewport.own_world_3d = true
	viewport.size = Vector2i(960,400)
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	field.add_child(viewport)
	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("252b2a")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("fff1d6")
	env.ambient_light_energy = .5
	env_node.environment = env
	viewport.add_child(env_node)
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45,-35,0)
	light.light_energy = .8
	viewport.add_child(light)
	figures = Node3D.new()
	viewport.add_child(figures)
	var ids = ["survivor_01","walker","runner","fatty"]
	for i in range(4):
		var holder = Node3D.new()
		holder.position.x = (i-1.5)*1.6
		figures.add_child(holder)
		var model = Art.miniature(ids[i])
		model.scale = Vector3.ONE*1.35
		holder.add_child(model)
		var pedestal = MeshInstance3D.new()
		var mesh = CylinderMesh.new()
		mesh.top_radius = .42
		mesh.bottom_radius = .46
		mesh.height = .10
		mesh.radial_segments = 48
		pedestal.mesh = mesh
		var m = StandardMaterial3D.new()
		m.albedo_color = Color("277e86") if i == 0 else Color("a44c3f")
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		pedestal.material_override = m
		pedestal.position.y = -.05
		holder.add_child(pedestal)
	var names = HBoxContainer.new()
	for label_text in ["SOBREVIVENTE 01","WALKER","RUNNER","FATTY"]:
		var label = Label.new()
		label.text = label_text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		names.add_child(label)
	layout.add_child(names)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.8
	camera.position = Vector3(0,2.7,6.0)
	viewport.add_child(camera)
	camera.look_at(Vector3(0,.65,0))
	var buttons = HBoxContainer.new()
	layout.add_child(buttons)
	for entry in [["Girar figuras ↶",-.35],["Girar figuras ↷",.35]]:
		var b = Button.new()
		b.text = entry[0]
		var change = float(entry[1])
		b.pressed.connect(func():
			angle += change
			for child in figures.get_children(): child.rotation.y = angle)
		buttons.add_child(b)
	var note = Label.new()
	note.text = "Poses fixas · modelos de estudo próprios · sem habilidades oficiais associadas"
	note.add_theme_font_size_override("font_size",13)
	layout.add_child(note)
