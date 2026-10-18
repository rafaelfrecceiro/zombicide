extends SceneTree
var table
var checks = 0
var failures: Array = []
var output = ""
var image_size = Vector2i.ZERO
func _initialize() -> void: run.call_deferred()
func check(ok: bool,text: String) -> void:
	checks += 1
	if not ok: failures.append(text)
	print("MENU ","PASS " if ok else "FAIL ",text)
func frame(name_: String) -> void:
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	var img = root.get_texture().get_image()
	image_size = img.get_size()
	check(img.save_png(output+"/"+name_+".png") == OK,"GPU frame "+name_)
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	if output.is_empty(): quit(1); return
	DirAccess.make_dir_recursive_absolute(output)
	table = load("res://main.tscn").instantiate()
	root.add_child(table)
	await create_timer(.35).timeout
	check(table.game_menu.open and root.get_visible_rect().encloses(table.game_menu.new_button.get_global_rect()),"game starts in an in-game mission menu with a visible primary action")
	await frame("mission-menu")
	var saved = table.session.rules.save_payload()
	var key = InputEventKey.new(); key.keycode = KEY_1; key.pressed = true
	Input.parse_input_event(key)
	await process_frame
	check(table.session.rules.save_payload() == saved,"mission menu blocks gameplay shortcuts")
	table.game_menu.session_page(2)
	await frame("options")
	check(table.session_tabs.get_tab_count() == 3 and table.session_tabs.current_tab == 2,"session menu separates mission, friends and options")
	table.session_tabs.current_tab = 1
	await frame("friends")
	check(table.code.secret and table.ip.text == "127.0.0.1","private room retains its invitation field and host address")
	table.session_tabs.current_tab = 0
	table.session.save_path = "user://qa-menu-mission.save"
	var mission_page = table.session_tabs.get_child(0)
	mission_page.get_child(0).pressed.emit()
	check(table.session_feedback.text.contains("Missão salva"),"save confirmation remains visible inside the session menu")
	mission_page.get_child(1).pressed.emit()
	check(not table.game_menu.open and not table.session_dialog.visible,"successful load returns directly to the table")
	table.game_menu.show_menu()
	table.game_menu.session_page(0)
	table.session.save_path = "user://qa-menu-missing-"+str(Time.get_ticks_usec())+".save"
	mission_page.get_child(1).pressed.emit()
	check(table.session_dialog.visible and table.session_feedback.text.contains("incompatível"),"failed load leaves the menu open with a visible explanation")
	table.session_dialog.hide()
	table.game_menu.new_button.pressed.emit()
	await process_frame
	check(not table.game_menu.open and table.session.view.survivors[0].name == "Amy" and table.session.view.survivors[3].name == "Elle","starting the study preset creates only the two verified profiles")
	table.roster_buttons[0].pressed.emit()
	await process_frame
	check(table.action_buttons.move.text.contains("grátis") and not table.action_buttons.move.disabled,"Amy's free action is identified on the gameplay button")
	await frame("amy-ready")
	table.set_mode("move")
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT; event.pressed = true
	event.position = table.camera.unproject_position(table.pos("v2")+Vector3(0,.12,0))
	table.field.gui_input.emit(event)
	check(table.session.view.survivors[0].actions == 3 and table.session.view.survivors[0].free.move == 0,"board input spends the free move while preserving general actions")
	var r = table.session.rules
	r.s.survivors[0].ap = 18
	r.gain_ap(0,1); r.drain(); table.session.refresh()
	await frame("skill-choice")
	check(table.session.view.pending.kind == "skill" and table.decisions_box.get_child_count() == 3,"progression presents two readable verified skill choices")
	var before = r.save_payload()
	table.game_menu.show_menu()
	table.game_menu.new_button.pressed.emit()
	check(table.new_dialog.visible and r.save_payload() == before,"new game cannot replace a running mission without confirmation")
	table.new_dialog.canceled.emit(); table.new_dialog.hide()
	check(r.save_payload() == before and table.game_menu.open,"canceling new game preserves the current decision and menu")
	table.game_menu.hide_menu()
	table.session.mode = "host"
	table.game_menu.show_menu()
	check(table.game_menu.new_button.disabled,"local reset is unavailable while hosting an online room")
	table.session.mode = "offline"
	var f = FileAccess.open(output+"/result.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"passed":checks-failures.size(),"failures":failures,"png_dimensions":str(image_size)},"  "))
	quit(0 if failures.is_empty() else 1)
