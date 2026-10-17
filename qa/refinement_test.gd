extends SceneTree
var table
var checks = 0
var failures: Array = []
var output = ""
var frame_size = Vector2i.ZERO
func _initialize() -> void:
	Engine.max_fps = 60
	run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("REFINE ","PASS " if ok else "FAIL ",message)
func frame(name_: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var captured = root.get_texture().get_image()
	frame_size = captured.get_size()
	check(captured.save_png(output+"/"+name_+".png") == OK,"GPU frame "+name_)
func has_visible(node: Node,name_: String) -> bool:
	if node is Node3D and str(node.name) == name_ and node.visible: return true
	for child in node.get_children():
		if has_visible(child,name_): return true
	return false
func run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--output="): output = a.trim_prefix("--output=")
	if output.is_empty(): quit(1); return
	DirAccess.make_dir_recursive_absolute(output)
	table = load("res://main.tscn").instantiate()
	table.skip_intro = true
	root.add_child(table)
	for i in range(5): await process_frame
	var art = preload("res://ui/comic_art.gd")
	var axe = art.miniature("survivor_01","axe")
	check(axe.get_meta("refined") and has_visible(axe,"WeaponAxe") and not has_visible(axe,"WeaponPistol"),"refined survivor displays equipped axe and hides pistol")
	axe.free()
	table.gallery.popup_centered_clamped(Vector2i(980,540),.92)
	for i in range(6): await process_frame
	check(table.gallery.viewport.own_world_3d and table.gallery.figures.get_child_count() == 4,"four-model gallery uses an isolated 3D world")
	await frame("miniatures")
	for child in table.gallery.figures.get_children(): child.rotation.y = .65
	await frame("miniatures-rotated")
	table.gallery.hide()
	var r = table.session.rules
	r.rng.seed = 3456
	r.s.active = 0
	r.s.survivors[0].zone = "v0"
	r.s.survivors[0].inventory = ["pistol","pistol","","",""]
	r.s.zombies.clear()
	r.add_zombie("walker","v2")
	table.session.refresh()
	await create_timer(.36).timeout
	var saved = r.save_payload()
	var info = r.attack_info({"slot":0,"dual":true},r.s.survivors[0],"v2")
	check(info.ok and info.dice == 2 and r.save_payload() == saved,"preview computes dual dice without changing state or RNG")
	table.use_dual = true
	table.confirm_attack("v2")
	check(table.attack_dialog.visible and table.attack_details.dice == 2 and r.s.pending.is_empty(),"confirmation uses shared rule preview and preserves resources")
	await frame("attack-preview")
	table.attack_dialog.confirmed.emit()
	table.attack_dialog.hide()
	check(r.s.pending.kind == "roll" and r.s.pending.dice == 2 and table.dice_tray.pending_count == 2,"legal attack opens two pending dice without generating values")
	await process_frame
	check(table.decisions_box.get_global_rect().end.y <= root.size.y,"manual roll area remains inside the window")
	await frame("dice-pending")
	table.session.submit({"action":"roll"})
	check(table.dice_tray.values == r.s.dice and table.dice_tray.pending_count == 0,"displayed faces equal authoritative results")
	check(table.dice_summary.text.contains("acerto"),"result summary uses the resolved rule event")
	var after_roll = r.save_payload()
	await create_timer(.55).timeout
	check(r.save_payload() == after_roll,"dice presentation does not change RNG or reapply combat")
	await frame("dice-result")
	table.confirm_attack("h")
	check(not table.attack_dialog.visible and not table.message.text.is_empty(),"illegal target never opens a misleading confirmation")
	for i in range(14): r.add_zombie("walker","v2")
	table.session.refresh()
	table.selected = "v2"
	table.inspect_zone()
	var ids = r.s.zombies.filter(func(z): return z.zone == "v2")
	var all_listed = true
	for z in ids: all_listed = all_listed and table.zone_text.text.contains("#%d ·" % z.id)
	check(all_listed and table.zone_text.text.contains("ZUMBIS · %d" % ids.size()),"dense zone inspection lists every actor including hidden figures")
	await frame("zone-inspector")
	var f = FileAccess.open(output+"/result.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"passed":checks-failures.size(),"failures":failures,"window":str(root.size),"png_dimensions":str(frame_size)},"  "))
	quit(0 if failures.is_empty() else 1)
