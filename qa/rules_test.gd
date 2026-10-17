extends SceneTree
const Rules = preload("res://core/rules.gd")
const Storage = preload("res://core/storage.gd")
var count = 0
var failures = []
var seq = 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool,name_: String) -> void:
	count += 1
	if not ok:
		failures.append(name_)
		printerr("FAIL: ",name_)
	else: print("PASS: ",name_)

func fresh(online: bool = false):
	var r = Rules.new()
	r.start(12345,online)
	return r

func command(r,action: String,extra: Dictionary = {},pid: String = "host") -> Dictionary:
	seq += 1
	var cmd = {"action":action,"request":"qa-%d" % seq,"revision":r.s.revision}
	cmd.merge(extra,true)
	return r.apply(cmd,pid)

func combat_fixture(r,weapon: String = "pistol") -> void:
	r.s.active = 0
	r.s.survivors[0].zone = "v0"
	r.s.survivors[0].inventory[0] = weapon
	r.s.zombies.clear()
	r.s.pending = {}
	r.queue.clear()

func run() -> void:
	var r = fresh()
	check(r.s.survivors.size() == 6 and r.s.zombies.size() == 4,"six survivors and four initial enemies")
	check(r.s.objectives.size() == 2 and r.s.crates.size() == 2,"M0 two objectives and two crates")
	check(not command(r,"move",{"zone":"v2"}).ok,"must activate first")
	check(command(r,"activate",{"actor":0}).ok,"activate own piece")
	var actions = r.s.survivors[0].actions
	check(not command(r,"move",{"zone":"a"}).ok and r.s.survivors[0].actions == actions,"illegal move never spends actions")
	check(command(r,"move",{"zone":"v2"}).ok and r.s.survivors[0].actions == actions-1,"legal movement spends exactly one action")
	check(not command(r,"activate",{"actor":1}).ok,"cannot interleave survivor activations")
	check(not r.visible("w0","b") and not r.visible("w0","c"),"closed entrance and solid wall block vision")
	check(not command(r,"move",{"zone":"c"}).ok,"closed wall/door rejects movement")
	r.s.survivors[0].zone = "v0"
	r.s.survivors[0].actions = 2
	r.add_zombie("walker","v0")
	check(not command(r,"move",{"zone":"v2"}).ok,"leaving two zombies costs three actions")
	r.s.survivors[0].actions = 3
	check(command(r,"move",{"zone":"v2"}).ok and r.s.survivors[0].actions == 0,"full disengagement cost applied")
	r = fresh()
	r.s.active = 0
	r.s.survivors[0].zone = "c"
	r.s.deck = ["shotgun"]
	check(command(r,"search").ok and r.s.pending.kind == "loot","search produces inventory choice")
	check(command(r,"choose",{"choice":"2"}).ok and r.s.survivors[0].inventory[2] == "shotgun","loot can be stored in backpack")
	check(not command(r,"search").ok,"second search rejected")
	check(not command(r,"attack",{"slot":2,"zone":"c"}).ok,"backpack weapon cannot attack")
	check(command(r,"equip",{"from":2,"to":0}).ok,"reorganization equips backpack weapon")
	r = fresh()
	combat_fixture(r)
	check(command(r,"attack",{"zone":"v2"}).ok and r.s.pending.kind == "roll" and r.s.dice.is_empty(),"attack waits for player roll")
	var saved = r.save_payload()
	var clone = fresh()
	check(clone.restore(saved),"save restores pending roll")
	check(command(r,"roll").ok,"player initiates random result")
	check(command(clone,"roll").ok and clone.s.dice == r.s.dice,"save preserves RNG sequence")
	check(not command(r,"roll").ok,"cannot reroll freely")
	r = fresh()
	combat_fixture(r)
	r.add_zombie("fatty","v0")
	r.add_zombie("runner","v0")
	r.queue = [{"kind":"hit","actor":0,"target":"v0","weapon":"pistol"},{"kind":"hit","actor":0,"target":"v0","weapon":"pistol"}]
	r.drain()
	check(r.s.zombies.size() == 2,"damage one does not accumulate or bypass ranged priority")
	r.queue = [{"kind":"hit","actor":0,"target":"v0","weapon":"axe"}]
	r.drain()
	if r.s.pending.get("kind","") == "hit": command(r,"choose",{"choice":str(r.s.zombies[0].id)})
	check(r.s.zombies.size() == 1 and r.s.zombies[0].type == "runner","damage two kills fatty")
	r = fresh()
	combat_fixture(r)
	r.s.survivors[1].zone = "v0"
	r.queue = [{"kind":"friendly","actor":0,"target":"v0","damage":2}]
	r.drain()
	check(r.s.pending.kind == "wound" and r.s.pending.targets == [1],"friendly fire excludes shooter")
	command(r,"choose",{"choice":"1"})
	check(r.s.survivors[1].wounds == 2,"friendly fire uses weapon damage")
	r = fresh()
	combat_fixture(r)
	r.s.survivors[0].ap = 6
	r.gain_ap(0,1)
	check(r.max_danger() == 1 and r.s.survivors[0].actions == 4,"yellow danger and extra action immediate")
	r = fresh(true)
	check(not command(r,"activate",{"actor":3}).ok,"host cannot activate guest piece")
	check(not command(r,"activate",{"actor":3},"guest").ok,"guest cannot act before own player turn")
	for id in [0,1,2]:
		command(r,"activate",{"actor":id})
		command(r,"end")
	check(r.s.active_player == 1 and command(r,"activate",{"actor":3},"guest").ok,"all host pieces finish before guest turn")
	r = fresh()
	combat_fixture(r)
	r.s.survivors[0].zone = "v0"
	r.add_zombie("runner","n0")
	r.queue_activations(r.s.zombies.duplicate(true))
	r.drain()
	check(r.s.zombies[0].zone == "v0" and r.s.pending.kind == "wound","runner moves then attacks in same activation")
	r = fresh()
	combat_fixture(r)
	r.add_zombie("walker","v0")
	r.queue_activations(r.s.zombies.duplicate(true))
	r.drain()
	command(r,"choose",{"choice":"0"})
	check(r.s.zombies[0].zone == "v0" and r.s.survivors[0].wounds == 1,"zombie attacks once and does not move after attacking")
	r = fresh()
	r.s.active = 0
	r.s.survivors[0].zone = "c"
	check(command(r,"objective").ok and r.s.survivors[0].ap == 5 and not "c" in r.s.objectives,"objective grants five adrenaline once")
	check(not command(r,"objective").ok,"objective cannot be collected twice")
	r.s.survivors[0].zone = "w0"
	check(not command(r,"escape").ok,"cannot escape before all objectives and crates")
	r.s.objectives.clear()
	r.s.crates.clear()
	r.add_zombie("walker","w0")
	check(not command(r,"escape").ok,"occupied exit blocks escape")
	r.s.zombies.clear()
	for i in range(1,6): r.s.survivors[i].escaped = true
	check(command(r,"escape").ok and r.s.outcome == "victory","all survivors exit for victory")
	r = fresh()
	combat_fixture(r)
	r.s.survivors[0].wounds = 2
	r.request_wound([r.s.survivors[0]],1,"host")
	command(r,"choose",{"choice":"0"})
	check(r.s.outcome == "defeat","third wound causes collective defeat")
	r = fresh()
	command(r,"activate",{"actor":0})
	var cmd = {"action":"move","zone":"v2","request":"repeat","revision":r.s.revision}
	check(r.apply(cmd).ok and r.apply(cmd).get("duplicate",false) and r.s.survivors[0].actions == 2,"duplicate network command spends once")
	var bad = r.save_payload()
	bad.state.schema = 99
	var before = r.save_payload()
	check(not r.restore(bad) and r.save_payload() == before,"incompatible save preserves live state")
	var path = "user://qa-m0.save"
	check(Storage.write(path,r.save_payload()) == OK,"save written with checksum")
	var restored = fresh()
	var restored_ok = restored.restore(Storage.read(path))
	check(restored_ok and restored.s == r.s,"serialized save roundtrip preserves state")
	var public = r.public_state()
	check(not public.has("deck") and not public.has("spawn_deck") and not public.has("seen"),"public snapshot hides future decks and processed command IDs")
	r.pause("guest absent")
	check(not command(r,"move",{"zone":"w0"}).ok,"paused game blocks commands")
	r.resume()
	check(command(r,"move",{"zone":"w0"}).ok,"resume restores legal action")
	r = fresh()
	combat_fixture(r)
	r.s.survivors[0].inventory[0] = "crowbar"
	r.s.survivors[0].zone = "w0"
	check(command(r,"open",{"zone":"b"}).ok and r.s.pending.kind == "building","opening building asks order of dark rooms")
	command(r,"choose",{"choice":"c"})
	check(r.s.zombies.size() > 0 and r.s.pending.kind == "building","first dark room spawned and next choice retained")
	command(r,"choose",{"choice":"b"})
	check(r.s.pending.is_empty() and "west" in r.s.revealed,"building revelation completes once")
	r = fresh()
	combat_fixture(r)
	r.s.survivors[0].inventory[0] = "pistol"
	var state_before = r.save_payload()
	check(not command(r,"attack",{"zone":"v2","dual":true}).ok and r.s.survivors[0].actions == state_before.state.survivors[0].actions,"invalid dual request rolls back cost and noise")
	r = fresh()
	combat_fixture(r)
	command(r,"attack",{"zone":"v2"})
	var pending_path = "user://qa-pending-roll.save"
	Storage.write(pending_path,r.save_payload())
	var disk_clone = fresh()
	check(disk_clone.restore(Storage.read(pending_path)) and disk_clone.s.pending.kind == "roll","disk save preserves pending roll and integer IDs")
	command(r,"roll")
	command(disk_clone,"roll")
	check(disk_clone.s.dice == r.s.dice,"disk restored pending roll gives same RNG outcome")
	var malformed = fresh().save_payload()
	malformed.state.players = []
	check(not disk_clone.restore(malformed),"empty player list rejected before replacing state")
	malformed = fresh().save_payload()
	malformed.state.survivors[0].id = 80
	check(not disk_clone.restore(malformed),"out of range actor ID rejected")
	malformed = fresh().save_payload()
	malformed.state.deck = ["invented-item"]
	check(not disk_clone.restore(malformed),"unknown deck entry rejected")
	r = fresh()
	r.s.survivors[0].ap = 18
	r.gain_ap(0,1)
	r.pause("guest absent")
	r.resume()
	check(r.s.paused and r.s.content_block,"reconnect cannot bypass unsupported skill content guard")
	r = fresh()
	r.s.survivors[0].actions = 3
	Storage.write(path,r.save_payload())
	r.s.survivors[0].actions = 2
	Storage.write(path,r.save_payload())
	var backup = fresh()
	check(backup.restore(Storage.read(path+".bak")) and backup.s.survivors[0].actions == 3,"previous save retained as recoverable backup")
	var corrupt = FileAccess.open(path,FileAccess.WRITE)
	corrupt.store_string("{broken")
	corrupt.close()
	check(Storage.read(path).is_empty() and not Storage.read(path+".bak").is_empty(),"partial/corrupt save rejected while backup survives")
	r = fresh(true)
	for i in range(3): r.s.survivors[i].escaped = true
	r.s.phase = "horde"
	r.queue = [{"kind":"round_end"}]
	r.s.first_player = 1
	r.drain()
	check(r.s.active_player == 1,"round skips player with all survivors already escaped")
	r = fresh()
	r.s.active = 0
	r.s.survivors[0].inventory[0] = "axe"
	var before_trade = r.s.survivors[0].actions
	check(command(r,"trade",{"other":1,"slot":0}).ok and r.s.pending.kind == "trade","trade awaits recipient consent")
	command(r,"choose",{"choice":"yes"})
	check(r.s.survivors[0].inventory[0] == "" and r.s.survivors[1].inventory.has("axe") and r.s.survivors[0].actions == before_trade-1,"trade moves item once and consumes one action")
	r = fresh()
	combat_fixture(r)
	var z1 = r.s.next_z
	r.add_zombie("walker","v0")
	r.add_zombie("walker","v0")
	r.set_pending({"kind":"split","owner":"host","ids":[z1,z1+1],"routes":["n0","n3","v2"],"prompt":"split"})
	command(r,"choose",{"choice":"n0"})
	check(not "n0" in r.choices(),"uneven split cannot allocate multiple remainder pieces to one route")
	# Regression cases from ZCD001 pp.9-10/36, not from the old square grid.
	r = fresh()
	check(r.zombies_at("n0").size() == 2 and r.zombies_at("v0").size() == 1 and r.zombies_at("v2").size() == 1,"M0 runner and fatty share north junction; walkers occupy central and south streets")
	check(r.neighbors("w0") == ["v2"] and not "c" in r.neighbors("w0",true),"exit reaches the south junction; archive has no outside door")
	check(r.distance("w0","n3") == 4,"exit to northeast spawn is four street moves, not a square per tile fragment")
	check(r.distance("w0","c") == 999,"closed west entrance blocks archive route")
	r.s.doors[r.key("b","w0")] = true
	check(r.distance("w0","c") == 2,"opened west entrance reaches archive via large storeroom in two moves")
	check(r.visible("w0","b") and not r.visible("w0","c"),"street sight enters one room only")
	check(r.visible("b","w0") and not r.visible("b","v2"),"large room sees through south door without turning east")
	check(r.visible("n0","v2") and not r.visible("n3","v0"),"avenue sight crosses tile seams but does not turn at north junction")
	r.s.doors[r.key("g","v2")] = true
	check(r.visible("g","w0") and r.visible("w0","g") and not r.visible("w0","h"),"east doorway sees straight across southern street, limited to first room")
	r.s.doors[r.key("e","n3")] = true
	check(r.visible("e","n3") and not r.visible("e","n0"),"north entrance cannot see around the corner")
	check(r.visible("a","b") and r.visible("a","c") and r.visible("c","b"),"three west rooms have the printed internal openings")
	var old_map = r.save_payload()
	old_map.state.content = "m0-lab-v1"
	var unchanged = r.save_payload()
	check(not r.restore(old_map) and r.save_payload() == unchanged,"old eighteen-cell save rejected without changing current mission")
	print("RESULT ",count-failures.size(),"/",count," passed")
	var report = {"checks":count,"passed":count-failures.size(),"failures":failures}
	var out = ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--report="): out = a.trim_prefix("--report=")
	if out != "":
		var f = FileAccess.open(out,FileAccess.WRITE)
		f.store_string(JSON.stringify(report,"  "))
	quit(0 if failures.is_empty() else 1)
