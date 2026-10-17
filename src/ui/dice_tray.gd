extends Control
## Faces always reflect the host result. Animation is cosmetic and never rolls RNG.
var values: Array = []
var pending_count = 0
var elapsed = 1.0
var reduce_motion = false
var last_signature = ""

func _ready() -> void:
	custom_minimum_size = Vector2(250,90)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func display(dice: Array,count_: int,reduce_: bool) -> void:
	reduce_motion = reduce_
	pending_count = count_
	var signature = str(dice)
	if signature != last_signature and not dice.is_empty(): elapsed = 0.0
	last_signature = signature
	values = dice.duplicate()
	queue_redraw()

func _process(delta: float) -> void:
	if elapsed < .5:
		elapsed += delta
		queue_redraw()

func _draw() -> void:
	var tray = StyleBoxFlat.new()
	tray.bg_color = Color("252a28")
	tray.border_color = Color("191c1d")
	tray.set_border_width_all(2)
	tray.set_corner_radius_all(5)
	draw_style_box(tray,Rect2(Vector2.ZERO,size))
	var count_ = pending_count if pending_count > 0 else values.size()
	var shown = mini(6,maxi(1,count_))
	var edge = minf(54.0,(size.x-24.0-(shown-1)*8.0)/shown)
	for i in range(shown):
		var bounce = absf(sin(elapsed*18+i*.7))*8*(1-elapsed/.5) if not reduce_motion and elapsed < .5 and pending_count == 0 else 0.0
		var p = Vector2((size.x-shown*edge-(shown-1)*8)/2+i*(edge+8),(size.y-edge)/2-bounce)
		var rect = Rect2(p,Vector2.ONE*edge)
		var face = StyleBoxFlat.new()
		face.bg_color = Color("efe3cb") if pending_count == 0 else Color("b5b09f")
		face.border_color = Color("121817")
		face.set_border_width_all(2)
		face.set_corner_radius_all(6)
		face.shadow_color = Color(0,0,0,.5)
		face.shadow_offset = Vector2(2,4)
		face.shadow_size = 2
		draw_style_box(face,rect)
		if pending_count > 0:
			draw_string(ThemeDB.fallback_font,p+Vector2(edge*.33,edge*.68),"?",HORIZONTAL_ALIGNMENT_LEFT,-1,int(edge*.57),Color("333b35"))
		elif i < values.size():
			var value = int(values[i])
			var dots = []
			if value%2 == 1: dots.append(Vector2(.5,.5))
			if value >= 2: dots.append_array([Vector2(.26,.26),Vector2(.74,.74)])
			if value >= 4: dots.append_array([Vector2(.74,.26),Vector2(.26,.74)])
			if value == 6: dots.append_array([Vector2(.26,.5),Vector2(.74,.5)])
			for dot in dots: draw_circle(p+dot*edge,maxf(2,edge*.075),Color("191c1d"))
