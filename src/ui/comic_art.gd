extends RefCounted
## Presentation only. Illustration never supplies zone or rule data.
const PORTRAITS = preload("res://assets/b/portraits-v1.png")
const BOARD = preload("res://assets/b/board-v1.png")
const INK = Color("191c1d")
const PAPER = Color("efe3cb")
const RED = Color("d44234")
const TEAL = Color("277e86")
static var models: Dictionary = {}
static var prepared: Dictionary = {}

static func portrait(id: int) -> AtlasTexture:
	var tex = AtlasTexture.new()
	tex.atlas = PORTRAITS
	var size_ = Vector2(PORTRAITS.get_size())/Vector2(3,2)
	tex.region = Rect2(Vector2(id%3,id/3)*size_,size_)
	tex.filter_clip = true
	return tex

static func miniature(id: String) -> Node3D:
	if not models.has(id):
		models[id] = load("res://assets/b/models/"+id+".glb")
	var node = models[id].instantiate()
	prepare_materials(node)
	return node

static func prepare_materials(node: Node) -> void:
	if node is MeshInstance3D:
		for i in range(node.mesh.get_surface_count()):
			var original = node.mesh.surface_get_material(i)
			if original == null: continue
			var id = original.get_instance_id()
			if not prepared.has(id):
				var m = original.duplicate()
				m.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT
				m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
				m.roughness = 1.0
				var outline = ShaderMaterial.new()
				outline.shader = preload("res://ui/comic_outline.gdshader")
				m.next_pass = outline
				prepared[id] = m
			node.set_surface_override_material(i,prepared[id])
	for child in node.get_children(): prepare_materials(child)
