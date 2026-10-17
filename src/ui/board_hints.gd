extends Control
## Readable screen-space labels and legal destinations, not a new art direction.
var table

func _process(_delta: float) -> void:
	queue_redraw()

func text_at(text: String,point: Vector2,size_: int,color: Color) -> void:
	var font = ThemeDB.fallback_font
	var width = font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size_).x
	var origin = point-Vector2(width/2,0)
	draw_string(font,origin+Vector2(1,1),text,HORIZONTAL_ALIGNMENT_LEFT,-1,size_,Color(0.02,0.03,0.04,0.95))
	draw_string(font,origin,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size_,color)

func _draw() -> void:
	if table == null or table.camera == null or table.session == null or table.session.view.is_empty(): return
	var s = table.session.view
	for id in table.board.zones:
		var p = table.pos(id)
		var points = PackedVector2Array()
		for offset in [Vector3(-0.95,0.16,-0.95),Vector3(0.95,0.16,-0.95),Vector3(0.95,0.16,0.95),Vector3(-0.95,0.16,0.95)]:
			points.append(table.camera.unproject_position(p+offset))
		var center = table.camera.unproject_position(p+Vector3(0,0.16,0))
		var bottom = table.camera.unproject_position(p+Vector3(0,0.16,0.74))
		var top = table.camera.unproject_position(p+Vector3(0,0.16,-0.67))
		var color = Color("8ee3b0") if table.mode == "move" else Color("ffc56e")
		if id in table.legal_zones:
			draw_colored_polygon(points,Color(color,0.22))
			var outline = points.duplicate()
			outline.append(points[0])
			draw_polyline(outline,color,3,true)
			text_at("MOVER" if table.mode == "move" else ("PORTA" if table.mode == "open" else "ALCANCE"),center+Vector2(0,-8),15,color)
		if table.mode == "inspect" and s.active >= 0 and s.survivors[int(s.active)].zone == id:
			var outline = points.duplicate()
			outline.append(points[0])
			draw_polyline(outline,Color("8bdce4"),3,true)
		text_at(table.zone_name(id),bottom+Vector2(0,6),15,Color("f0ede4"))
		var badge = ""
		var badge_color = Color("f0ede4")
		if id in s.objectives:
			badge = "OBJETIVO"
			badge_color = Color("ffb3ab")
		elif id in s.crates:
			badge = "ARMA ESPECIAL"
			badge_color = Color("ffe0a0")
		elif id == table.board.exit:
			badge = "INÍCIO / SAÍDA"
			badge_color = Color("8bdce4")
		elif id in table.board.spawns:
			badge = "ENTRADA ZUMBI"
			badge_color = Color("ffb3ab")
		if not badge.is_empty(): text_at(badge,top,13,badge_color)
