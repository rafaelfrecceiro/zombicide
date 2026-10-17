extends SceneTree
const Session = preload("res://net/session.gd")
var session
var side = "host"
var output = ""
var stage = 0
var ticks = 0
var start_ms = 0
var observed_pause = false
var rejected_foreign = false
var reconnect_at = 0
var steps = 0

func _initialize() -> void:
	Engine.max_fps = 60
	run.call_deferred()

func run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--side="): side = a.trim_prefix("--side=")
		if a.begins_with("--report="): output = a.trim_prefix("--report=")
	session = Session.new()
	session.save_path = "user://qa-network.save"
	session.name = "Session"
	root.add_child(session)
	session.rejected.connect(func(message):
		if message.contains("controle") or message.contains("indisponível"): rejected_foreign = true)
	var err = session.host("qa-private-invitation",28171) if side == "host" else session.join("127.0.0.1","qa-private-invitation",28171)
	if err != OK:
		complete(false,"Cannot start ENet peer %d" % err)
		return
	start_ms = Time.get_ticks_msec()

func _process(_delta: float) -> bool:
	if session == null: return false
	ticks += 1
	if Time.get_ticks_msec()-start_ms > 18000:
		complete(false,"Timed out at stage %d" % stage)
		return false
	var v = session.view
	if v.is_empty(): return false
	if side == "host":
		if stage == 0 and not v.paused:
			for id in [0,1,2]:
				session.submit({"action":"activate","actor":id})
				session.submit({"action":"end"})
			stage = 1
		elif stage == 1 and v.paused and v.pause_reason.contains("desconectou"):
			observed_pause = true
			if v.survivors[3].owner != "guest" or v.survivors[3].zone != "w1":
				complete(false,"Lost guest ownership or move")
				return false
			stage = 2
		elif stage == 2 and not v.paused:
			stage = 3
			reconnect_at = ticks+20
		elif stage == 3 and ticks >= reconnect_at:
			complete(observed_pause and v.survivors[3].zone == "w1","Host observed pause, credential rejoin and preserved ownership")
	else:
		if stage == 0 and v.get("players",[]).size() == 2 and not v.paused and v.active_player == 1:
			session.submit({"action":"activate","actor":0})
			stage = 1
		elif stage == 1 and rejected_foreign:
			session.submit({"action":"activate","actor":3})
			stage = 2
		elif stage == 2 and v.active == 3:
			session.submit({"action":"move","zone":"w1"})
			stage = 3
		elif stage == 3 and v.survivors[3].zone == "w1":
			session.disconnect_client()
			stage = 4
			reconnect_at = ticks+35
		elif stage == 4 and ticks >= reconnect_at:
			# Recreate session to exercise credentials restored from disk, not memory.
			session.free()
			session = Session.new()
			session.name = "Session"
			root.add_child(session)
			session.join("127.0.0.1","qa-private-invitation",28171)
			stage = 5
		elif stage == 5 and not v.paused and v.active == 3:
			stage = 6
			reconnect_at = ticks+35
		elif stage == 6 and ticks >= reconnect_at:
			complete(rejected_foreign and v.survivors[3].zone == "w1","Client command rejected, legal move and credential reconnect preserved")
	return false

func complete(ok: bool,message: String) -> void:
	print("NETWORK ",side," ",ok," ",message)
	if output != "":
		var f = FileAccess.open(output,FileAccess.WRITE)
		f.store_string(JSON.stringify({"side":side,"ok":ok,"stage":stage,"message":message},"  "))
	quit(0 if ok else 1)
