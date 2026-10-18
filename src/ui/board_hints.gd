extends Control
## Readable screen-space labels and legal destinations, not a new art direction.
var table

func _process(_delta: float) -> void:
	queue_redraw()

func text_at(text: String,point: Vector2,size_: int,color: Color) -> void:
	var font = ThemeDB.fallback_font
	var width = font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size_).x
	var origin = point-Vector2(width/2,0)
	draw_rect(Rect2(origin+Vector2(-4,-size_),Vector2(width+8,size_+5)),Color(0.035,0.045,0.045,0.86))
	draw_string(font,origin+Vector2(1,1),text,HORIZONTAL_ALIGNMENT_LEFT,-1,size_,Color(0.02,0.03,0.04,0.95))
	draw_string(font,origin,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size_,color)

func _draw() -> void:
	if table == null or table.camera == null or table.session == null or table.session.view.is_empty(): return
	var s = table.session.view
	for id in table.board.zones:
		var zone = table.board.zones[id]
		var p = table.pos(id)
		var points = PackedVector2Array()
		var half_width = zone.width-0.05
		var half_height = zone.height-0.05
		for offset in [Vector3(-half_width,0.16,-half_height),Vector3(half_width,0.16,-half_height),Vector3(half_width,0.16,half_height),Vector3(-half_width,0.16,half_height)]:
			points.append(table.camera.unproject_position(p+offset))
		var center = table.camera.unproject_position(p+Vector3(0,0.16,0))
		var bottom = table.camera.unproject_position(p+Vector3(0,0.16,zone.height-0.26))
		var top = table.camera.unproject_position(p+Vector3(0,0.16,-zone.height+0.33))
		var color = Color("8ee3b0") if table.mode == "move" else Color("ffc56e")
		if id in table.legal_zones:
			draw_colored_polygon(points,Color(color,0.22))
			var outline = points.duplicate()
			outline.append(points[0])
			draw_polyline(outline,color,3,true)
			var cost = 1
			if s.active >= 0:
				cost = table.rule_preview.action_cost(s.survivors[int(s.active)],"move")
				cost += s.zombies.filter(func(z): return z.zone == s.survivors[int(s.active)].zone).size()
			text_at("MOVER · %d AÇÃO" % cost if table.mode == "move" else ("PORTA" if table.mode == "open" else "ALCANCE"),center+Vector2(0,-8),15,color)
		if id == table.hovered_zone:
			var hover_outline = points.duplicate()
			hover_outline.append(points[0])
			draw_polyline(hover_outline,Color(1,.97,.83,.7),2,true)
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
		var survivors = s.survivors.filter(func(v): return not v.escaped and v.zone == id).size()
		var zombies = s.zombies.filter(func(z): return z.zone == id).size()
		var capacity = 8 if zone.width >= 2 else 4
		if survivors+zombies > capacity:
			text_at("%d S / %d Z · %d à vista" % [survivors,zombies,capacity],center+Vector2(0,-16),13,Color("ffe0a0"))
