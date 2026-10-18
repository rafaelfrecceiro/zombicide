extends SceneTree
var table
var checks = 0
var failures: Array = []
var output = ""
var image_size = Vector2i.ZERO
func _initialize() -> void:
	Engine.max_fps = 60
	run.call_deferred()
func check(ok: bool,message_: String) -> void:
	checks += 1
	if not ok: failures.append(message_)
	print("LAYOUT ","PASS " if ok else "FAIL ",message_)
func frame(name_: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var img = root.get_texture().get_image()
	image_size = img.get_size()
	check(img.save_png(output+"/"+name_+".png") == OK,"GPU frame "+name_)
func key(code_: Key) -> void:
	var ev = InputEventKey.new()
	ev.keycode = code_
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	ev = InputEventKey.new()
	ev.keycode = code_
	ev.pressed = false
	Input.parse_input_event(ev)
	await process_frame
func fit(control: Control) -> bool:
	return root.get_visible_rect().encloses(control.get_global_rect())
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	if output.is_empty(): quit(1); return
	DirAccess.make_dir_recursive_absolute(output)
	table = load("res://main.tscn").instantiate()
	root.add_child(table)
	await create_timer(.35).timeout
	check(not table.help_dialog.visible and table.empty_hint.visible and table.survivor_box.get_child_count() == 6,"first contact shows group and guidance without a blocking modal")
	check(fit(table.survivor_box) and fit(table.side_card) and fit(table.field),"group, card and table fit the initial window")
	await frame("first-contact")
	await key(KEY_1)
	check(table.session.view.active == 0 and not table.empty_hint.visible,"keyboard selects an available survivor and reveals its controls")
	var r = table.session.rules
	var stable_move = table.action_buttons.move
	var stable_roster = table.roster_buttons[0]
	var stable_piece = table.piece_nodes.s0
	stable_move.grab_focus()
	await key(KEY_M)
	check(table.mode == "move" and not table.legal_zones.is_empty(),"move shortcut highlights legal zones")
	check(table.action_buttons.move == stable_move and table.roster_buttons[0] == stable_roster and root.gui_get_focus_owner() == stable_move,"mode refresh preserves button identity and keyboard focus")
	check(table.piece_nodes.s0 == stable_piece,"cosmetic mode changes preserve the actual 3D miniature")
	var saved = r.save_payload()
	table.cancel_button.pressed.emit()
	check(table.mode == "inspect" and r.save_payload() == saved,"visible cancel returns to inspection without cost or RNG changes")
	await key(KEY_2)
	check(r.save_payload() == saved,"shortcut cannot activate another survivor during the current activation")
	check(table.action_buttons.search.disabled and table.action_buttons.search.tooltip_text.contains("sala"),"unavailable search explains its room requirement")
	check(table.roster_buttons[0].get_theme_color("icon_normal_color") == Color.WHITE,"portrait keeps original colors rather than inheriting ink tint")
	# Isolate cosmetic sampling from real desktop pointer enter/exit events.
	stable_move.mouse_filter = Control.MOUSE_FILTER_IGNORE
	await process_frame
	stable_move.animate_hover(1)
	await create_timer(.05).timeout
	check(stable_move.hover_amount > 0 and stable_move.hover_amount < 1,"hover feedback sampled between its start and end")
	await frame("hover-feedback")
	await create_timer(.14).timeout
	# GPU readback can advance wall timers more than Tween's processed frames.
	for i in range(30):
		if not stable_move.hover_tween.is_running(): break
		await process_frame
	check(is_equal_approx(stable_move.hover_amount,1.0) and r.save_payload() == saved,"hover finishes without changing gameplay")
	stable_move.mouse_filter = Control.MOUSE_FILTER_STOP
	table.help_dialog.popup_centered(Vector2i(640,440))
	await process_frame
	await key(KEY_A)
	check(table.mode == "inspect" and r.save_payload() == saved,"open modal prevents gameplay shortcuts")
	table.help_dialog.hide()
	await process_frame
	var old_camera = table.camera.position
	table.angle += .25
	table.position_camera()
	await create_timer(.07).timeout
	check(table.camera.position.distance_to(old_camera) > .01 and table.camera.position.distance_to(table.camera_goal.position) > .01,"camera transition sampled between distinct poses")
	await create_timer(.23).timeout
	for i in range(30):
		if not table.camera_tween.is_running(): break
		await process_frame
	check(table.camera.position.distance_to(table.camera_goal.position) < .01,"camera reaches its fitted pose")
	table.apply_reduce_motion(true)
	stable_move.animate_hover(0)
	stable_move.animate_hover(1)
	stable_move.animate_press(.98)
	table.angle = 0
	table.position_camera()
	check(stable_move.hover_amount == 1 and stable_move.scale == Vector2.ONE and table.camera.position == table.camera_goal.position,"reduced motion makes hover, press and camera immediate")
	r.rng.seed = 3456
	r.s.survivors[0].zone = "v0"
	r.s.survivors[0].inventory = ["pistol","pistol","","",""]
	r.s.zombies.clear()
	r.add_zombie("walker","v2")
	table.session.refresh()
	table.use_dual = true
	table.confirm_attack("v2")
	await frame("attack-preview")
	table.attack_dialog.confirmed.emit()
	table.attack_dialog.hide()
	await process_frame
	check(fit(table.side_card) and fit(table.decisions_box) and fit(table.survivor_box),"pending dice and group remain visible without scrolling")
	await frame("manual-dice")
	await key(KEY_SPACE)
	check(r.s.pending.is_empty() and table.dice_tray.values == r.s.dice and r.s.dice.size() == 2,"space initiates one authoritative dual roll")
	var after_roll = r.save_payload()
	await key(KEY_SPACE)
	check(r.save_payload() == after_roll,"space cannot reroll after the decision resolves")
	check(fit(table.side_card) and fit(table.actions_box) and fit(table.survivor_box),"results and restored actions fit together after rolling")
	check(fit(table.message) and fit(table.status),"feedback and session status remain inside the window after combat")
	await frame("combat-result")
	table.history_button.pressed.emit()
	await frame("history")
	check(table.history_dialog.visible and table.log_box.text.contains("Dados:"),"history drawer retains authoritative combat events")
	table.history_dialog.hide()
	for i in range(14): r.add_zombie("walker","v2")
	r.s.pending = {"kind":"hit","owner":"host","actor":0,"targets":r.s.zombies.map(func(z): return z.id),"prompt":"Escolha qual zumbi recebe o acerto."}
	table.session.refresh()
	await process_frame
	await process_frame
	var scroll = table.decisions_box.get_child(1) # Prompt followed by the bounded choice list.
	var choices = scroll.get_child(0) if scroll is ScrollContainer else null
	check(choices != null and choices.get_child_count() == 14 and fit(table.side_card) and fit(table.survivor_box),"fourteen legal targets use a bounded list while group and card remain visible")
	if choices != null:
		scroll.scroll_vertical = 10000
		await process_frame
		await frame("dense-choice")
		var before_count = r.s.zombies.size()
		var last_id = r.s.zombies[-1].id
		choices.get_child(13).pressed.emit()
		check(r.s.pending.is_empty() and r.s.zombies.size() == before_count-1 and not r.s.zombies.any(func(z): return z.id == last_id),"last scrolled target applies exactly the selected legal choice")
	var f = FileAccess.open(output+"/result.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"passed":checks-failures.size(),"failures":failures,"png_dimensions":str(image_size),"motion":"sampled transitions; not a performance benchmark or human playtest"},"  "))
	quit(0 if failures.is_empty() else 1)
