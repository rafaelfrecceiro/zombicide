extends SceneTree
const Rules = preload("res://core/rules.gd")
var checks = 0
var failures: Array = []
var seq = 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool,text: String) -> void:
	checks += 1
	if not ok: failures.append(text)
	print("SKILLS ","PASS " if ok else "FAIL ",text)
func cmd(r,action: String,extra: Dictionary = {},owner: String = "host") -> Dictionary:
	seq += 1
	var input = {"action":action,"request":"skills-%d" % seq,"revision":r.s.revision}
	input.merge(extra)
	return r.apply(input,owner)
func fresh():
	var r = Rules.new()
	r.start(3456,false,["amy","","","elle","",""])
	return r
func run() -> void:
	var r = fresh()
	check(r.s.survivors[0].name == "Amy" and r.s.survivors[0].free.move == 1 and r.s.survivors[3].skills == ["sniper"],"verified blue skills are assigned only to Amy and Elle")
	check(r.defs.pistol.accuracy == 3,"pistol accuracy matches the visually inspected p13 card")
	cmd(r,"activate",{"actor":0})
	var v = r.s.survivors[0]
	v.actions = 0
	check(cmd(r,"move",{"zone":"v2"}).ok and v.actions == 0 and v.free.move == 0,"Amy can use one free Move with zero general actions")
	check(not cmd(r,"move",{"zone":"v0"}).ok,"free Move cannot be reused")
	r = fresh(); v = r.s.survivors[0]; r.s.active = 0
	v.zone = "v0"; v.actions = 0
	check(not cmd(r,"move",{"zone":"v2"}).ok,"free base action does not waive the zombie disengagement surcharge")
	v = r.s.survivors[0]
	v.actions = 1
	check(cmd(r,"move",{"zone":"v2"}).ok and v.actions == 0 and v.free.move == 0,"disengagement spends one general action and the free base Move")
	r = fresh(); v = r.s.survivors[0]; r.s.active = 0
	v.ap = 18; v.actions = 0
	r.gain_ap(0,1); r.drain()
	check(not r.s.paused and r.s.pending.kind == "skill" and r.choices() == ["free_melee","free_ranged"],"orange opens Amy's verified choices instead of the generic content block")
	var before = r.save_payload()
	check(not cmd(r,"choose",{"choice":"medic"}).ok and r.save_payload() == before,"a red skill cannot be selected at orange")
	v = r.s.survivors[0]
	check(cmd(r,"choose",{"choice":"free_ranged"}).ok and v.free.ranged == 1,"chosen free action is available immediately")
	v.zone = "v0"; v.inventory = ["pistol","pistol","","",""]
	var info = r.attack_info({"slot":0,"dual":true},v,"v2")
	check(info.ok and info.cost == 0 and info.dice == 2,"shared preview accounts for a restricted free Ranged action")
	check(cmd(r,"attack",{"zone":"v2","dual":true}).ok and v.actions == 0 and v.free.ranged == 0,"attack consumes the restricted pool without creating general actions")
	var pending = r.save_payload()
	var clone = fresh()
	check(clone.restore(pending),"pending attack and restricted pools survive restore")
	cmd(r,"roll"); cmd(clone,"roll")
	check(r.s.dice == clone.s.dice,"restored skill attack preserves RNG outcomes")
	r = fresh(); v = r.s.survivors[0]; r.s.active = 0
	v.ap = 42; v.skill_levels = [2]; v.skills.append("free_melee"); v.actions = 2
	r.gain_ap(0,1); r.drain()
	check(r.s.pending.level == 3 and r.choices().size() == 3,"red offers the three verified Amy skills")
	cmd(r,"choose",{"choice":"die_combat"})
	v.inventory = ["pistol","pistol","","",""]; v.zone = "v0"
	check(r.attack_info({"dual":true},v,"v2").dice == 4,"extra die applies to each of the two Dual weapons")
	v.inventory[0] = "molotov"
	check(r.attack_info({},v,"v2").dice == 0,"dice bonuses never turn Molotov into a dice attack")
	r = fresh(); r.s.active = 3; v = r.s.survivors[3]
	v.zone = "v0"; v.inventory[0] = "pistol"
	r.s.zombies.clear(); r.add_zombie("fatty","v2"); r.add_zombie("walker","v2")
	r.s.survivors[0].zone = "v2"
	check(r.attack_info({},v,"v2").sniper,"Elle's preview identifies the Sniper effect")
	r.queue = [{"kind":"hit","actor":3,"target":"v2","weapon":"pistol","sniper":true}]
	r.drain()
	check(r.s.zombies.size() == 1 and r.s.zombies[0].type == "fatty","Sniper may eliminate a Walker behind the Fatty priority")
	r.rng.seed = 3456
	cmd(r,"attack",{"zone":"v2"}); cmd(r,"roll")
	check(r.s.pending.is_empty() and r.s.survivors[0].wounds == 0,"a Sniper miss does not create friendly fire")
	r = fresh(); v = r.s.survivors[0]; r.s.active = 0
	v.ap = 42; v.skill_levels = [2]; v.skills.append("free_melee")
	r.gain_ap(0,1); r.drain(); cmd(r,"choose",{"choice":"medic"})
	v.wounds = 1; r.s.survivors[1].wounds = 2
	var ap = v.ap
	r.queue = [{"kind":"medic_end"}]; r.drain()
	check(v.wounds == 0 and r.s.survivors[1].wounds == 1 and v.ap == ap+2,"Medic heals one wound per survivor in the zone and earns AP per wound")
	r.queue = [{"kind":"round_end"}]; r.drain()
	check(v.free.move == 1 and v.free.melee == 1,"typed free pools replenish at the next round")
	var forged = r.save_payload(); forged.state.survivors[0].free.move = 50
	check(not fresh().restore(forged),"save rejects forged free-action quantities")
	var queued = fresh().save_payload()
	queued.queue = [{"kind":"skill_unlock","actor":99,"level":2}]
	check(not fresh().restore(queued),"save rejects invalid actor in a queued skill unlock")
	r = fresh(); r.s.active = 3; v = r.s.survivors[3]
	v.zone = "v0"; v.inventory = ["pistol","pistol","","",""]
	v.ap = 43; v.skill_levels = [2,3]; v.skills += ["die_combat","accuracy_ranged"]
	var modified = r.attack_info({"dual":true},v,"v2")
	check(modified.dice == 4 and modified.accuracy == 2 and fresh().restore(r.save_payload()),"Elle's orange and red modifiers combine and survive save validation")
	cmd(r,"attack",{"zone":"v2","dual":true})
	check(r.s.pending.accuracy == 2 and r.s.pending.dice == 4,"manual roll freezes modified accuracy and dice in its pending decision")
	r = fresh(); r.s.active = 3; v = r.s.survivors[3]
	v.ap = 43; v.skill_levels = [2,3]; v.skills += ["free_ranged","free_combat"]
	r.reset_free(v); v.actions = 0
	v.zone = "v0"; v.inventory[0] = "pistol"
	cmd(r,"attack",{"zone":"v2"})
	check(v.free.ranged == 0 and v.free.combat == 1 and v.actions == 0,"a typed action is consumed before the more flexible free Combat pool")
	r.s.pending = {}; v.inventory[0] = "axe"
	check(cmd(r,"attack",{"zone":"v0"}).ok and v.free.combat == 0 and v.actions == 0,"the remaining free Combat action can pay for a Melee attack")
	var report = ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="): report = arg.trim_prefix("--report=")
	if not report.is_empty():
		var f = FileAccess.open(report,FileAccess.WRITE)
		f.store_string(JSON.stringify({"checks":checks,"passed":checks-failures.size(),"failures":failures},"  "))
	quit(0 if failures.is_empty() else 1)
