extends SceneTree
var table
var count = 0
var failures = []
var screenshot = ""
var report_path = ""

func _initialize() -> void:
	Engine.max_fps = 60
	run.call_deferred()

func check(ok: bool,text: String) -> void:
	count += 1
	if not ok: failures.append(text)
	print("UI ","PASS " if ok else "FAIL ",text)

func find_button(text: String,node: Node) -> Button:
	if node is Button and node.text == text: return node
	for child in node.get_children():
		var found = find_button(text,child)
		if found != null: return found
	return null

func click_zone(id: String) -> void:
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = table.camera.unproject_position(table.pos(id)+Vector3(0,0.12,0))
	table.field.gui_input.emit(event)

func run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--capture="): screenshot = a.trim_prefix("--capture=")
		if a.begins_with("--report="): report_path = a.trim_prefix("--report=")
	table = load("res://main.tscn").instantiate()
	table.skip_intro = true
	root.add_child(table)
	for i in range(5): await process_frame
	check(table.camera != null and table.figures.get_child_count() > 25,"3D table and rigid pegs instantiated")
	check(find_button("Mover",table).disabled,"actions disabled before activation")
	check(table.guide_title.text.begins_with("1. Escolha"),"first action explained on screen")
	check(table.help_dialog.dialog_text.contains("3. ATAQUE") and table.help_dialog.dialog_text.contains("4. ENCERRE"),"in-game help explains movement, dice and turn sequence")
	table.survivor_box.get_child(0).pressed.emit()
	check(table.session.view.active == 0,"survivor button activates piece")
	check(not find_button("Mover",table).disabled,"legal turn unlocks actions")
	find_button("Mover",table).pressed.emit()
	check("w1" in table.legal_zones and not "c" in table.legal_zones,"legal move highlights exclude closed doors")
	check(table.guide_title.text.contains("zona verde"),"destination guidance follows selected action")
	click_zone("w1")
	check(table.session.view.survivors[0].zone == "w1","mouse projection moves to selected zone")
	check(table.session.view.survivors[0].actions == 2,"UI movement spends one action")
	find_button("Mover",table).pressed.emit()
	click_zone("a")
	check(table.session.view.survivors[0].zone == "w1" and table.session.view.survivors[0].actions == 2,"illegal click does not move or spend")
	check(table.message.text.contains("passagem"),"rejection reason appears in interface")
	var r = table.session.rules
	r.s.survivors[0].zone = "v0"
	r.s.survivors[0].inventory[0] = "pistol"
	table.session.refresh()
	find_button("Atacar",table).pressed.emit()
	click_zone("v2")
	check(table.attack_dialog.visible and table.session.view.pending.is_empty(),"attack preview preserves resources until confirmation")
	table.attack_dialog.confirmed.emit()
	table.attack_dialog.hide()
	check(table.session.view.pending.get("kind","") == "roll","attack opens dice interaction")
	check(not table.actions_box.visible and table.decision_section.visible,"pending decision replaces competing action controls")
	var roll = find_button("LANÇAR 1 DADO(S)",table)
	check(roll != null and not roll.disabled,"player can initiate dice roll")
	await process_frame
	check(root.get_visible_rect().encloses(roll.get_global_rect()),"roll button fits visible window without scrolling")
	if screenshot != "":
		for i in range(4): await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(screenshot) == OK,"real GPU frame captured")
	roll.pressed.emit()
	check(table.session.view.dice.size() == 1,"roll button generates one result")
	check(table.dice_label.text.contains(str(table.session.view.dice[0])),"dice result visible")
	find_button("Vista superior",table).pressed.emit()
	check(table.elevation > 1.5,"top-down camera available")
	if report_path != "":
		var f = FileAccess.open(report_path,FileAccess.WRITE)
		f.store_string(JSON.stringify({"checks":count,"passed":count-failures.size(),"failures":failures},"  "))
	print("UI RESULT ",count-failures.size(),"/",count)
	quit(0 if failures.is_empty() else 1)
