extends Button
## Cosmetic feedback only; native Button keeps focus, disabled and input behavior.
var reduce_motion_provider: Callable
var hover_amount = 0.0
var hover_tween: Tween
var press_tween: Tween

func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	resized.connect(func(): pivot_offset = size / 2)
	mouse_entered.connect(func(): animate_hover(1.0))
	mouse_exited.connect(func(): animate_hover(0.0))
	button_down.connect(func(): animate_press(.98))
	button_up.connect(func(): animate_press(1.0))

func reduced() -> bool:
	return reduce_motion_provider.is_valid() and reduce_motion_provider.call()

func animate_hover(value: float) -> void:
	if is_instance_valid(hover_tween): hover_tween.kill()
	if reduced() or disabled:
		hover_amount = value if not disabled else 0.0
		queue_redraw()
		return
	hover_tween = create_tween()
	hover_tween.tween_method(func(v): hover_amount = v; queue_redraw(),hover_amount,value,.12)

func reset_motion() -> void:
	if is_instance_valid(hover_tween): hover_tween.kill()
	if is_instance_valid(press_tween): press_tween.kill()
	scale = Vector2.ONE
	hover_amount = 1.0 if is_hovered() and not disabled else 0.0
	queue_redraw()

func animate_press(value: float) -> void:
	if is_instance_valid(press_tween): press_tween.kill()
	if reduced() or disabled: scale = Vector2.ONE; return
	press_tween = create_tween()
	press_tween.tween_property(self,"scale",Vector2.ONE * value,.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _draw() -> void:
	if not disabled and hover_amount > .01:
		draw_line(Vector2(10,size.y-3),Vector2(10+(size.x-20)*hover_amount,size.y-3),Color("40cbd3"),2,true)
