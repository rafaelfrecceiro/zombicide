extends SceneTree
var failures: Array = []
var checks = 0
var output = ""
var table
func _initialize() -> void:
	Engine.max_fps = 60
	run.call_deferred()
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("ART ","PASS " if ok else "FAIL ",message)
func frame(name_: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(output+"/"+name_+".png") == OK,"GPU frame "+name_)
func run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--output="): output = a.trim_prefix("--output=")
	if output.is_empty(): quit(1); return
	DirAccess.make_dir_recursive_absolute(output)
	table = load("res://main.tscn").instantiate()
	table.skip_intro = true
	root.add_child(table)
	for i in range(5): await process_frame
	table.session.submit({"action":"activate","actor":0})
	table.set_mode("move")
	await frame("before")
	var start = table.piece_nodes.s0.position
	table.session.submit({"action":"move","zone":"v2"})
	await create_timer(0.10).timeout
	var midway = table.piece_nodes.s0.position
	check(midway.distance_to(start) > 0.1 and midway.distance_to(table.piece_positions.s0) > 0.1,"presentation sampled during motion between distinct source and destination")
	await frame("during")
	await create_timer(0.30).timeout
	check(table.session.view.survivors[0].actions == 2 and table.piece_nodes.s0.position.distance_to(table.piece_positions.s0) < .01,"motion finished without changing rule cost")
	await frame("after")
	table.angle = 0.30
	table.elevation = 1.52
	table.position_camera()
	await create_timer(.26).timeout
	await frame("camera")
	table.reduce_motion = true
	table.session.submit({"action":"move","zone":"w0"})
	check(table.piece_nodes.s0.position.distance_to(table.piece_positions.s0) < .01,"reduced motion immediately displays authoritative destination")
	var r = table.session.rules
	for i in range(14): r.add_zombie("walker","v2")
	table.session.refresh()
	check(table.session.view.zombies.filter(func(z): return z.zone == "v2").size() == 15,"dense display preserves all fifteen zombies in rules state")
	check(table.piece_nodes.size() == 17,"dense zone limits displayed figures to eight; rest remain in rules and choices")
	await frame("dense")
	var result = {"checks":checks,"passed":checks-failures.size(),"failures":failures,"resolution":str(root.size),"motion":"positions and GPU frames sampled; not a human playtest or FPS benchmark"}
	var f = FileAccess.open(output+"/result.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(result,"  "))
	quit(0 if failures.is_empty() else 1)
