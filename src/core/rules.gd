extends RefCounted

const Content = preload("res://core/content.gd")
const Survivors = preload("res://core/survivors.gd")
var s: Dictionary = {}
var rng = RandomNumberGenerator.new()
var map = Content.board()
var defs = Content.weapons()
var queue: Array = []

func start(seed_value: int = 0, online: bool = false, profiles: Array = []) -> void:
	if seed_value == 0: rng.randomize()
	else: rng.seed = seed_value
	s = {"schema":1,"content":Content.VERSION,"revision":0,"round":1,"phase":"players","paused":false,"pause_reason":"","outcome":"","active_player":0,"first_player":0,"active":-1,"players":["host","guest"] if online else ["host"],"survivors":[],"zombies":[],"doors":{},"revealed":[],"noise":{},"objectives":map.objectives.duplicate(),"crates":map.crates.duplicate(),"pending":{},"done":[],"log":[],"dice":[],"next_z":0,"seen":{},"deck":[],"discard":[],"spawn_deck":[],"spawn_discard":[],"special_deck":["special","special"],"reserve":{"walker":40,"fatty":16,"runner":16,"abomination":1}}
	s["content_block"] = false
	for pair in map.doors: s.doors[key(pair[0],pair[1])] = false
	var starting = ["pistol","pistol","pistol","axe","crowbar","bat"]
	shuffle_array(starting)
	for i in range(6):
		s.survivors.append({"id":i,"name":"Peão %02d" % (i+1),"owner":"guest" if online and i >= 3 else "host","zone":map.start,"wounds":0,"ap":0,"actions":3,"searched":false,"escaped":false,"inventory":[starting[i],"","","",""],"profile":"","skills":[],"skill_levels":[],"free":{}})
	for i in range(mini(6,profiles.size())):
		var id = str(profiles[i])
		if not Survivors.profiles().has(id): continue
		var v = s.survivors[i]
		v.profile = id
		v.name = Survivors.profiles()[id].name
		v.skills = [Survivors.profiles()[id].blue]
		reset_free(v)
	s.deck = ["pistol","axe","crowbar","shotgun","shotgun","molotov","molotov","food","food","alarm"]
	shuffle_array(s.deck)
	s.spawn_deck = [0,1,0,1]
	shuffle_array(s.spawn_deck)
	for row in map.initial: add_zombie(row[0],row[1])
	note("M0 em construção: fichas parciais e decks de laboratório. Paridade oficial pendente.")

func shuffle_array(a: Array) -> void:
	for i in range(a.size()-1,0,-1):
		var j = rng.randi_range(0,i)
		var old = a[i]
		a[i] = a[j]
		a[j] = old

func note(message: String) -> void:
	s.log.append(message)
	if s.log.size() > 100: s.log.pop_front()

func key(a: String,b: String) -> String:
	return a+"|"+b if a < b else b+"|"+a

func neighbors(z: String, include_closed: bool = false) -> Array:
	var result = []
	for edge in map.edges:
		if z in edge: result.append(edge[1] if edge[0] == z else edge[0])
	for door in map.doors:
		if z in door and (include_closed or s.doors.get(key(door[0],door[1]),false)):
			result.append(door[1] if door[0] == z else door[0])
	return result

func distance(a: String,b: String) -> int:
	var seen = {a:0}
	var todo = [a]
	while not todo.is_empty():
		var z = todo.pop_front()
		if z == b: return seen[z]
		for n in neighbors(z):
			if not seen.has(n):
				seen[n] = seen[z]+1
				todo.append(n)
	return 999

func visible(a: String,b: String) -> bool:
	if not map.zones.has(a) or not map.zones.has(b): return false
	if a == b: return true
	# Continue along the opening's direction. Seeing a street does not allow turning a corner.
	for n in neighbors(a):
		var edge = Content.border(map.zones[a],map.zones[n])
		if edge.is_empty(): continue
		if n == b: return true
		if not map.zones[n].inside and sight_ray(n,b,edge.direction): return true
	return false

func sight_ray(a: String,b: String,direction: Vector2i) -> bool:
	var todo = [a]
	var seen = [a]
	while not todo.is_empty():
		var z = todo.pop_front()
		for n in neighbors(z):
			if n in seen: continue
			var edge = Content.border(map.zones[z],map.zones[n])
			if edge.is_empty() or edge.direction != direction: continue
			if n == b: return true
			seen.append(n)
			if not map.zones[n].inside: todo.append(n)
	return false

func street_visible(a: String,b: String) -> bool:
	if not map.zones.has(a) or not map.zones.has(b): return false
	if map.zones[a].inside or map.zones[b].inside: return false
	return visible(a,b)

func zombies_at(z: String) -> Array:
	return s.zombies.filter(func(v): return v.zone == z)

func survivors_at(z: String) -> Array:
	return s.survivors.filter(func(v): return not v.escaped and v.zone == z)

func add_zombie(kind: String,z: String) -> bool:
	if s.reserve.get(kind,0) <= 0: return false
	s.zombies.append({"id":s.next_z,"type":kind,"zone":z})
	s.next_z += 1
	s.reserve[kind] -= 1
	return true

func max_danger() -> int:
	var d = 0
	for v in s.survivors: d = maxi(d,Content.danger(v.ap))
	return d

func apply(cmd: Dictionary, participant: String = "host") -> Dictionary:
	if not cmd.get("request","") is String: return {"ok":false,"error":"Comando inválido."}
	var request = str(cmd.get("request",""))
	var token = participant+":"+request
	if not request.is_empty() and s.seen.has(token): return {"ok":true,"duplicate":true}
	if cmd.get("revision",s.revision) != s.revision: return {"ok":false,"error":"O tabuleiro mudou. Consulte o estado atualizado."}
	if s.paused: return {"ok":false,"error":"Partida pausada: "+str(s.pause_reason)}
	if not s.outcome.is_empty(): return {"ok":false,"error":"A missão terminou."}
	if not participant in s.players: return {"ok":false,"error":"Participante não autorizado."}
	var backup = s.duplicate(true)
	var old_queue = queue.duplicate(true)
	var old_rng = rng.state
	var error = execute(cmd,participant)
	if not error.is_empty():
		s = backup
		queue = old_queue
		rng.state = old_rng
		return {"ok":false,"error":error}
	if not request.is_empty():
		s.seen[token] = true
		if s.seen.size() > 1024: s.seen.erase(s.seen.keys()[0])
	drain()
	s.revision += 1
	return {"ok":true}

func execute(cmd: Dictionary,pid: String) -> String:
	var action = str(cmd.get("action",""))
	if not s.pending.is_empty():
		if s.pending.owner != pid: return "Aguardando a decisão de outro jogador."
		if action == "roll" and s.pending.kind == "roll": return roll()
		if action == "choose": return choose(str(cmd.get("choice","")))
		return "Conclua a decisão ou rolagem pendente."
	if action == "discard":
		var id = int(cmd.get("actor",-1))
		var slot = int(cmd.get("slot",-1))
		if id < 0 or id >= 6 or slot < 0 or slot > 4: return "Slot inválido."
		var v = s.survivors[id]
		if v.owner != pid or v.escaped: return "Esta peça não está sob seu controle."
		if v.inventory[slot] != "": s.discard.append(v.inventory[slot])
		v.inventory[slot] = ""
		return ""
	if s.phase != "players": return "Aguarde a resolução da horda."
	if s.players[s.active_player] != pid: return "Ainda não é a sua vez."
	if action == "activate":
		var id = int(cmd.get("actor",-1))
		if s.active != -1: return "Encerre a ativação atual antes de trocar."
		if id < 0 or id >= 6: return "Peça inválida."
		var actor = s.survivors[id]
		if actor.owner != pid or actor.escaped or id in s.done: return "Peça indisponível nesta rodada."
		s.active = id
		note(actor.name+" iniciou sua ativação.")
		return ""
	if s.active < 0: return "Escolha uma peça para ativar."
	var v = s.survivors[s.active]
	var target = str(cmd.get("zone",v.zone))
	if not map.zones.has(target): return "Zona inválida."
	if action == "end":
		end_activation()
		return ""
	if action == "escape":
		if not s.objectives.is_empty() or not s.crates.is_empty(): return "Coletem todos os objetivos e caixas antes de fugir."
		if v.zone != map.exit or not zombies_at(v.zone).is_empty(): return "A saída deve estar livre de zumbis."
		v.escaped = true
		note(v.name+" escapou.")
		end_activation()
		if s.survivors.all(func(x): return x.escaped): finish("victory")
		return ""
	if action == "move":
		if not target in neighbors(v.zone): return "Não há passagem aberta para essa zona."
		var extra = zombies_at(v.zone).size()
		var cost = action_cost(v,"move")+extra
		if not can_pay(v,"move",extra): return "Ações insuficientes: sair exige %d." % cost
		pay(v,"move",extra)
		v.zone = target
		note(v.name+" moveu para "+map.zones[target].name+" (%d ação/ações)." % cost)
		return ""
	if v.actions <= 0 and action not in ["attack","search"]: return "Sem ações restantes. Encerre a ativação."
	match action:
		"open":
			var door_key = key(v.zone,target)
			if not s.doors.has(door_key) or s.doors[door_key]: return "Não há porta fechada entre essas zonas."
			var tool = ""
			for i in range(2):
				if defs.get(v.inventory[i],{}).get("door",false): tool = v.inventory[i]
			if tool.is_empty(): return "É preciso equipar uma ferramenta que abra portas."
			v.actions -= 1
			s.doors[door_key] = true
			if defs[tool].get("door_noise",false): add_noise(v.zone)
			var interior = target if map.zones[target].inside else v.zone
			var building = map.zones[interior].building
			if not building in s.revealed:
				s.revealed.append(building)
				var rooms = []
				for z in map.zones:
					if map.zones[z].building == building and map.zones[z].dark: rooms.append(z)
				set_pending({"kind":"building","owner":pid,"rooms":rooms,"prompt":"Escolha a próxima sala escura a revelar."})
			note("Porta aberta. O edifício será revelado uma única vez.")
		"search":
			if not can_pay(v,"search"): return "Sem ações para buscar."
			if not map.zones[v.zone].inside or not zombies_at(v.zone).is_empty(): return "Busque em uma sala sem zumbis."
			if v.searched: return "Esta peça já buscou nesta ativação."
			pay(v,"search")
			v.searched = true
			if s.deck.is_empty():
				s.deck = s.discard.duplicate()
				s.discard.clear()
				shuffle_array(s.deck)
			if s.deck.is_empty(): return "Não há cartas disponíveis no laboratório."
			var card = s.deck.pop_back()
			if card == "alarm":
				s.discard.append(card)
				if not add_zombie("walker",v.zone): queue_extra("walker")
				note("Aaahh!! Um Walker apareceu na busca.")
				drain()
			else: offer_loot(card)
		"objective":
			if not v.zone in s.objectives: return "Não há objetivo nesta zona."
			v.actions -= 1
			s.objectives.erase(v.zone)
			gain_ap(v.id,5)
			note("Objetivo coletado: +5 de adrenalina.")
		"crate":
			if not v.zone in s.crates: return "Não há caixa nesta zona."
			if s.special_deck.is_empty(): return "Sem armas especiais disponíveis."
			v.actions -= 1
			s.crates.erase(v.zone)
			offer_loot(s.special_deck.pop_back())
		"noise":
			v.actions -= 1
			add_noise(v.zone)
		"equip":
			var a = int(cmd.get("from",-1))
			var b = int(cmd.get("to",-1))
			if a < 0 or a > 4 or b < 0 or b > 4 or a == b: return "Escolha dois slots distintos."
			v.actions -= 1
			var old = v.inventory[a]
			v.inventory[a] = v.inventory[b]
			v.inventory[b] = old
		"trade":
			var other = int(cmd.get("other",-1))
			var slot = int(cmd.get("slot",-1))
			if other < 0 or other >= 6 or other == v.id or slot < 0 or slot > 4: return "Troca inválida."
			var w = s.survivors[other]
			if w.zone != v.zone or w.escaped or v.inventory[slot] == "": return "Troca exige outra peça na mesma zona e um item."
			var free = w.inventory.find("")
			if free < 0: return "O destinatário está com inventário cheio."
			set_pending({"kind":"trade","owner":w.owner,"actor":v.id,"other":other,"slot":slot,"free":free,"prompt":"Aceitar item de "+v.name+"?"})
		"attack": return begin_attack(cmd,v,target)
		_: return "Ação desconhecida."
	return ""

func add_noise(z: String) -> void:
	s.noise[z] = int(s.noise.get(z,0))+1

func offer_loot(card: String) -> void:
	set_pending({"kind":"loot","owner":s.survivors[s.active].owner,"card":card,"prompt":"Encontrou "+defs[card].name+". Escolha um slot; substituir descarta a carta antiga."})

func set_pending(p: Dictionary) -> void:
	s.pending = p

func attack_info(cmd: Dictionary,v: Dictionary,target: String) -> Dictionary:
	if not map.zones.has(target): return {"ok":false,"error":"Zona inválida."}
	var slot = int(cmd.get("slot",0))
	if slot < 0 or slot > 1: return {"ok":false,"error":"Use uma arma equipada em uma das mãos."}
	var card = v.inventory[slot]
	var weapon = defs.get(card,{})
	if not weapon.has("range"): return {"ok":false,"error":"Este item não é uma arma equipada."}
	if not can_pay(v,weapon.mode): return {"ok":false,"error":"Sem ações para este ataque."}
	var d = distance(v.zone,target)
	if d < weapon.range[0] or d > weapon.range[1] or not visible(v.zone,target): return {"ok":false,"error":"Alvo fora de alcance ou visão."}
	if weapon.mode == "melee" and target != v.zone: return {"ok":false,"error":"Ataque corpo a corpo exige a mesma zona."}
	var dice = int(weapon.dice)+int("die_combat" in v.skills)+int("die_"+weapon.mode in v.skills)
	if card == "molotov": dice = 0
	if card != "molotov" and cmd.get("dual",false):
		if not weapon.get("dual",false) or v.inventory[1-slot] != card: return {"ok":false,"error":"Dual exige armas idênticas e compatíveis nas duas mãos."}
		dice *= 2
	return {"ok":true,"card":card,"name":weapon.name,"dice":dice,"accuracy":maxi(1,int(weapon.accuracy)-int("accuracy_combat" in v.skills)-int("accuracy_"+weapon.mode in v.skills)),"damage":weapon.damage,"distance":d,"cost":action_cost(v,weapon.mode),"sniper":"sniper" in v.skills,"noise":weapon.noise,"mode":weapon.mode}

func begin_attack(cmd: Dictionary,v: Dictionary,target: String) -> String:
	var info = attack_info(cmd,v,target)
	if not info.ok: return info.error
	var slot = int(cmd.get("slot",0))
	var card = info.card
	var weapon = defs[card]
	pay(v,weapon.mode)
	if weapon.noise: add_noise(v.zone)
	if card == "molotov":
		v.inventory[slot] = ""
		s.discard.append(card)
		for z in zombies_at(target).duplicate(): kill_zombie(z.id,v.id)
		if not survivors_at(target).is_empty(): finish("defeat")
		note("Molotov resolveu seu efeito na zona.")
		return ""
	var dice = info.dice
	set_pending({"kind":"roll","owner":v.owner,"actor":v.id,"target":target,"weapon":card,"dice":dice,"accuracy":info.accuracy,"damage":info.damage,"sniper":info.sniper,"prompt":"Lance %d dado(s). Precisão %d+, dano %d." % [dice,info.accuracy,info.damage]})
	return ""

func roll() -> String:
	var p = s.pending.duplicate(true)
	var weapon = defs[p.weapon]
	var values = []
	var hits = 0
	for i in range(p.dice):
		var value = rng.randi_range(1,6)
		values.append(value)
		if value >= p.get("accuracy",weapon.accuracy): hits += 1
	s.dice = values
	s.pending = {}
	note("Dados: "+str(values)+" → %d acerto(s)." % hits)
	var attacks = []
	for i in range(hits): attacks.append({"kind":"hit","actor":p.actor,"target":p.target,"weapon":p.weapon,"damage":p.get("damage",weapon.damage),"sniper":p.get("sniper",false)})
	if weapon.mode == "ranged" and not p.get("sniper",false):
		for i in range(p.dice-hits): attacks.append({"kind":"friendly","actor":p.actor,"target":p.target,"damage":weapon.damage})
	queue = attacks+queue
	drain()
	return ""

func choices() -> Array:
	var p = s.pending
	if p.is_empty(): return []
	match p.kind:
		"building": return p.rooms
		"loot": return ["0","1","2","3","4","discard"]
		"trade": return ["yes","no"]
		"skill": return Survivors.profiles()[s.survivors[p.actor].profile]["orange" if p.level == 2 else "red"]
		"hit": return p.targets.map(func(v): return str(v))
		"wound": return p.targets.map(func(v): return str(v))
		"split": return p.routes
	return []

func choose(choice: String) -> String:
	if not choice in choices(): return "Escolha não permitida."
	var p = s.pending.duplicate(true)
	s.pending = {}
	match p.kind:
		"skill":
			var v = s.survivors[p.actor]
			v.skills.append(choice)
			v.skill_levels.append(p.level)
			if choice.begins_with("free_"): v.free[choice.trim_prefix("free_")] = int(v.free.get(choice.trim_prefix("free_"),0))+1
			note(v.name+" aprendeu: "+Survivors.skill_name(choice))
		"building":
			p.rooms.erase(choice)
			spawn(choice)
			if not p.rooms.is_empty(): queue.push_front({"kind":"building_continue","pending":p})
		"loot":
			if choice == "discard": s.discard.append(p.card)
			else:
				var v = s.survivors[s.active]
				var idx = int(choice)
				if v.inventory[idx] != "": s.discard.append(v.inventory[idx])
				v.inventory[idx] = p.card
		"trade":
			if choice == "yes":
				var v = s.survivors[p.actor]
				var w = s.survivors[p.other]
				w.inventory[p.free] = v.inventory[p.slot]
				v.inventory[p.slot] = ""
				v.actions -= 1
				note("Transferência aceita. Ação de troca consumida.")
		"hit": kill_zombie(int(choice),p.actor)
		"wound":
			var v = s.survivors[int(choice)]
			v.wounds += p.damage
			note(v.name+" recebeu %d ferimento(s)." % p.damage)
			if v.wounds >= 3: finish("defeat")
		"split":
			var zid = p.ids.pop_back()
			move_zombie(zid,choice)
			p.routes.erase(choice)
			if not p.ids.is_empty(): queue.push_front({"kind":"split_continue","pending":p})
	drain()
	return ""

func kill_zombie(zid: int,actor: int) -> void:
	for i in range(s.zombies.size()):
		var z = s.zombies[i]
		if z.id == zid:
			s.reserve[z.type] += 1
			s.zombies.remove_at(i)
			gain_ap(actor,5 if z.type == "abomination" else 1)
			return

func gain_ap(actor: int,amount: int) -> void:
	var v = s.survivors[actor]
	var old = Content.danger(v.ap)
	v.ap += amount
	if old == 0 and Content.danger(v.ap) > 0:
		v.actions += 1
		note(v.name+" chegou ao amarelo: +1 ação.")
	if not v.profile.is_empty():
		var unlocks = []
		for level in [2,3]:
			if old < level and Content.danger(v.ap) >= level: unlocks.append({"kind":"skill_unlock","actor":actor,"level":level})
		queue = unlocks+queue
	elif old < 2 and Content.danger(v.ap) >= 2:
		s.content_block = true
		s.paused = true
		s.pause_reason = "Limite do laboratório: árvore de habilidades laranja/vermelha ainda não conferida. Salve a partida."

func end_activation() -> void:
	var v = s.survivors[s.active]
	v.actions = 0
	v.free.clear()
	s.done.append(v.id)
	s.active = -1
	if s.survivors.all(func(x): return x.escaped): return
	var pid = s.players[s.active_player]
	if s.survivors.any(func(x): return x.owner == pid and not x.escaped and not x.id in s.done): return
	for offset in range(1,s.players.size()):
		var index = (s.active_player+offset)%s.players.size()
		var owner = s.players[index]
		if s.survivors.any(func(x): return x.owner == owner and not x.escaped and not x.id in s.done):
			s.active_player = index
			return
	s.phase = "horde"
	note("Fase da horda.")
	queue_activations(s.zombies.duplicate(true))
	for zone in map.spawns: queue.append({"kind":"spawn","zone":zone})
	queue.append({"kind":"medic_end"})
	queue.append({"kind":"round_end"})
	drain()

func queue_activations(zombies: Array, front: bool = false) -> void:
	var tasks = []
	var groups = {}
	for z in zombies:
		var k = z.zone+":"+z.type
		if not groups.has(k): groups[k] = []
		groups[k].append(z.id)
	for stage in ["attack_group","move_group"]:
		for ids in groups.values(): tasks.append({"kind":stage,"ids":ids})
	var runners = zombies.filter(func(z): return z.type == "runner")
	# Second action uses current locations after first movement.
	if not runners.is_empty(): tasks.append({"kind":"runner_second","ids":runners.map(func(z): return z.id)})
	queue = tasks+queue if front else queue+tasks

func queue_extra(kind: String) -> void:
	queue_activations(s.zombies.filter(func(z): return z.type == kind).duplicate(true),true)

func live_zombies(ids: Array) -> Array:
	return s.zombies.filter(func(z): return z.id in ids)

func move_zombie(id: int,target: String) -> void:
	for z in s.zombies:
		if z.id == id: z.zone = target

func drain() -> void:
	var guard = 0
	while s.pending.is_empty() and not queue.is_empty() and s.outcome.is_empty() and not s.paused:
		guard += 1
		if guard > 2000:
			s.paused = true
			s.pause_reason = "Resolução excedeu o limite de segurança."
			return
		var task = queue.pop_front()
		match task.kind:
			"skill_unlock":
				var v = s.survivors[task.actor]
				if task.level in v.skill_levels: continue
				set_pending({"kind":"skill","owner":v.owner,"actor":v.id,"level":task.level,"prompt":v.name+": escolha a habilidade "+("laranja" if task.level == 2 else "vermelha")+"."})
			"hit":
				var weapon = defs[task.weapon]
				var zs = zombies_at(task.target)
				if weapon.mode == "ranged" and not task.get("sniper",false) and not zs.is_empty():
					var best = 99
					for z in zs: best = mini(best,priority(z.type))
					zs = zs.filter(func(z): return priority(z.type) == best)
				zs = zs.filter(func(z): return Content.threshold(z.type) <= task.get("damage",weapon.damage))
				if zs.is_empty(): continue
				if zs.size() == 1: kill_zombie(zs[0].id,task.actor)
				else: set_pending({"kind":"hit","owner":s.survivors[task.actor].owner,"actor":task.actor,"targets":zs.map(func(z): return z.id),"prompt":"Escolha qual zumbi recebe o acerto."})
			"friendly":
				var vs = survivors_at(task.target).filter(func(v): return v.id != task.actor)
				if not vs.is_empty(): request_wound(vs,task.damage,s.survivors[task.actor].owner)
			"attack_group":
				var zs = live_zombies(task.ids)
				if zs.is_empty(): continue
				var vs = survivors_at(zs[0].zone)
				if vs.is_empty(): continue
				for z in zs:
					queue.push_front({"kind":"zombie_wound","zone":z.zone})
				# Mark actors as attacked so they cannot move in this action.
				for z in zs: z["attacked"] = true
			"zombie_wound":
				var vs = survivors_at(task.zone)
				if not vs.is_empty(): request_wound(vs,1,s.players[s.first_player])
			"move_group":
				var zs = live_zombies(task.ids).filter(func(z): return not z.get("attacked",false))
				if not zs.is_empty(): resolve_move(zs)
				for z in live_zombies(task.ids): z.erase("attacked")
			"runner_second":
				var zs = live_zombies(task.ids)
				var groups = {}
				for z in zs:
					if not groups.has(z.zone): groups[z.zone] = []
					groups[z.zone].append(z.id)
				var extra = []
				for stage in ["attack_group","move_group"]:
					for ids in groups.values(): extra.append({"kind":stage,"ids":ids})
				queue = extra+queue
			"spawn": spawn(task.zone)
			"building_continue", "split_continue": set_pending(task.pending)
			"medic_end":
				for medic in s.survivors:
					if medic.escaped or not "medic" in medic.skills: continue
					for v in survivors_at(medic.zone):
						if v.wounds > 0:
							v.wounds -= 1
							gain_ap(medic.id,1)
			"round_end":
				s.round += 1
				s.noise.clear()
				s.done.clear()
				s.first_player = (s.first_player+1)%s.players.size()
				s.active_player = s.first_player
				for offset in range(s.players.size()):
					var index = (s.first_player+offset)%s.players.size()
					if s.survivors.any(func(v): return v.owner == s.players[index] and not v.escaped):
						s.active_player = index
						break
				s.phase = "players"
				for v in s.survivors:
					v.actions = 4 if v.ap >= 7 else 3
					v.searched = false
					reset_free(v)
				note("Rodada %d. Ruído transitório removido." % s.round)

func priority(kind: String) -> int:
	return {"fatty":0,"abomination":0,"walker":1,"runner":2}.get(kind,99)

func request_wound(vs: Array,damage: int,owner: String) -> void:
	set_pending({"kind":"wound","owner":owner,"targets":vs.map(func(v): return v.id),"damage":damage,"prompt":"Distribua %d ferimento(s) a uma peça na zona." % damage})

func resolve_move(zs: Array) -> void:
	var start_zone = zs[0].zone
	var candidates = []
	for v in s.survivors:
		if not v.escaped and visible(start_zone,v.zone) and not v.zone in candidates: candidates.append(v.zone)
	if candidates.is_empty(): candidates.assign(map.zones.keys())
	var top = -1
	var targets = []
	for zone in candidates:
		var noise = int(s.noise.get(zone,0))+survivors_at(zone).size()
		if noise > top:
			top = noise
			targets = [zone]
		elif noise == top: targets.append(zone)
	var routes = []
	for zone in targets:
		var d = distance(start_zone,zone)
		if d == 0 or d >= 999: continue
		for n in neighbors(start_zone):
			if distance(n,zone) == d-1 and not n in routes: routes.append(n)
	if routes.is_empty(): return
	var count_each = zs.size()/routes.size()
	var ids = zs.map(func(z): return z.id)
	for route in routes:
		for i in range(int(count_each)): move_zombie(ids.pop_back(),route)
	if not ids.is_empty(): set_pending({"kind":"split","owner":s.players[s.first_player],"ids":ids,"routes":routes,"prompt":"Grupo ímpar: escolha o caminho de uma peça restante."})

func spawn(zone: String) -> void:
	if s.spawn_deck.is_empty():
		s.spawn_deck = s.spawn_discard.duplicate()
		s.spawn_discard.clear()
		shuffle_array(s.spawn_deck)
	var index = s.spawn_deck.pop_back()
	s.spawn_discard.append(index)
	var sample = Content.spawn_samples()[index]
	var count = sample.counts[max_danger()]
	var shortage = false
	for i in range(count):
		if not add_zombie(sample.type,zone): shortage = true
	note("Spawn de laboratório: %d %s em %s." % [count,sample.type,map.zones[zone].name])
	if shortage:
		note("Reserva esgotada: ativação extra.")
		queue_extra(sample.type)

func finish(result: String) -> void:
	s.outcome = result
	s.pending = {}
	queue.clear()
	note("VITÓRIA: todos escaparam." if result == "victory" else "DERROTA: um sobrevivente foi eliminado.")

func pause(reason: String) -> void:
	s.paused = true
	s.pause_reason = reason
	s.revision += 1

func resume() -> void:
	if s.get("content_block",false):
		s.pause_reason = "Limite do laboratório: habilidades laranja/vermelha pendentes de conferência."
		return
	s.paused = false
	s.pause_reason = ""
	s.revision += 1
	drain()

func public_state() -> Dictionary:
	var view = s.duplicate(true)
	for k in ["seen","deck","discard","spawn_deck","spawn_discard","special_deck"]: view.erase(k)
	view["deck_count"] = s.deck.size()
	view["choices"] = choices()
	return view

func save_payload() -> Dictionary:
	return {"state":s.duplicate(true),"queue":queue.duplicate(true),"rng":str(rng.state)}

func restore(payload: Dictionary) -> bool:
	payload = normalize_numbers(payload)
	var state = payload.get("state",{})
	if not state is Dictionary or state.get("schema",0) != 1 or state.get("content","") != Content.VERSION: return false
	if not state.get("survivors",[]) is Array or state.survivors.size() != 6: return false
	for k in s.keys():
		if not state.has(k): return false
	if not valid_structure(state,payload): return false
	for v in state.survivors:
		if not v is Dictionary: return false
		for k in ["id","name","owner","zone","wounds","ap","actions","searched","escaped","inventory","profile","skills","skill_levels","free"]:
			if not v.has(k): return false
		if not map.zones.has(v.zone) or not v.inventory is Array or v.inventory.size() != 5: return false
		for item in v.inventory:
			if item != "" and not defs.has(item): return false
	for z in state.get("zombies",[]):
		if not z is Dictionary or not map.zones.has(z.get("zone","")) or not state.reserve.has(z.get("type","")): return false
	if not payload.get("queue",[]) is Array or not str(payload.get("rng","")).is_valid_int(): return false
	s = state.duplicate(true)
	queue = payload.queue.duplicate(true)
	rng.state = int(payload.rng)
	return true

func valid_structure(state: Dictionary,payload: Dictionary) -> bool:
	for k in ["revision","round","active_player","first_player","active","next_z"]:
		if not state[k] is int: return false
	for k in ["paused","content_block"]:
		if not state[k] is bool: return false
	for k in ["phase","pause_reason","outcome"]:
		if not state[k] is String: return false
	if not state.phase in ["players","horde"] or not state.outcome in ["","victory","defeat"]: return false
	if not state.players is Array or not state.players in [["host"],["host","guest"]]: return false
	if state.active < -1 or state.active >= 6 or state.revision < 0 or state.round < 1: return false
	if state.active_player < 0 or state.active_player >= state.players.size() or state.first_player < 0 or state.first_player >= state.players.size(): return false
	for k in ["zombies","revealed","objectives","crates","done","log","dice","deck","discard","spawn_deck","spawn_discard","special_deck"]:
		if not state[k] is Array: return false
	for k in ["pending","doors","noise","reserve","seen"]:
		if not state[k] is Dictionary: return false
	if not state.pending.is_empty():
		if not state.pending.get("kind","") in ["roll","building","loot","trade","hit","wound","split","skill"]: return false
		if not state.pending.get("owner","") in state.players or not state.pending.get("prompt",null) is String: return false
	var ids = []
	for v in state.survivors:
		if not v is Dictionary: return false
		for k in ["id","wounds","ap","actions"]:
			if not v.get(k,null) is int: return false
		if v.id < 0 or v.id >= 6 or v.id in ids or v.wounds < 0 or v.ap < 0 or v.actions < 0: return false
		if not v.get("owner","") in state.players: return false
		if not v.get("escaped",null) is bool or not v.get("searched",null) is bool: return false
		if not v.get("profile",null) is String or not v.get("skills",null) is Array or not v.get("skill_levels",null) is Array or not v.get("free",null) is Dictionary: return false
		if not v.profile.is_empty() and not Survivors.profiles().has(v.profile): return false
		var allowed = []
		if not v.profile.is_empty():
			var profile = Survivors.profiles()[v.profile]
			allowed = [profile.blue]+profile.orange+profile.red
			if v.skills.count(profile.blue) != 1 or v.skills.size() != v.skill_levels.size()+1: return false
			for level in [2,3]:
				if v.skill_levels.count(level) > 1: return false
				var chosen = v.skills.filter(func(skill): return skill in profile["orange" if level == 2 else "red"])
				if chosen.size() != (1 if level in v.skill_levels else 0): return false
		elif not v.skills.is_empty() or not v.skill_levels.is_empty(): return false
		for skill in v.skills:
			if not skill in allowed: return false
		for type in v.free:
			if not type in ["move","melee","ranged","combat","search"] or not v.free[type] is int or v.free[type] < 0 or v.free[type] > v.skills.count("free_"+type): return false
		for level in v.skill_levels:
			if not level in [2,3] or Content.danger(v.ap) < level: return false
		ids.append(v.id)
	if state.pending.get("kind","") == "skill":
		var p = state.pending
		if not p.get("actor",null) is int or p.actor < 0 or p.actor >= 6 or not p.get("level",null) in [2,3]: return false
		var v = state.survivors[p.actor]
		if v.profile.is_empty() or p.owner != v.owner or p.level in v.skill_levels or Content.danger(v.ap) < p.level: return false
	for z in state.zombies:
		if not z is Dictionary or not z.get("id",null) is int or not z.get("type","") in ["walker","fatty","runner","abomination"]: return false
	for kind in ["walker","fatty","runner","abomination"]:
		if not state.reserve.get(kind,null) is int or state.reserve[kind] < 0: return false
	for zone in state.objectives+state.crates:
		if not zone is String or not map.zones.has(zone): return false
	for item in state.deck+state.discard+state.special_deck:
		if not item is String or not defs.has(item): return false
	for card in state.spawn_deck+state.spawn_discard:
		if not card is int or card < 0 or card >= Content.spawn_samples().size(): return false
	if not payload.get("queue",null) is Array: return false
	for task in payload.queue:
		if not task is Dictionary or not task.get("kind","") in ["hit","friendly","attack_group","move_group","zombie_wound","runner_second","spawn","building_continue","split_continue","round_end","skill_unlock","medic_end"]: return false
		if task.kind == "skill_unlock":
			if not task.get("actor",null) is int or task.actor < 0 or task.actor >= 6 or not task.get("level",null) in [2,3]: return false
			var v = state.survivors[task.actor]
			if v.profile.is_empty() or Content.danger(v.ap) < task.level: return false
	return true

func normalize_numbers(value: Variant) -> Variant:
	# JSON represents every number as float. State has integer counters/IDs only.
	if value is float and is_finite(value) and value == floor(value): return int(value)
	if value is Array:
		var out = []
		for element in value: out.append(normalize_numbers(element))
		return out
	if value is Dictionary:
		var out = {}
		for k in value: out[k] = normalize_numbers(value[k])
		return out
	return value

func reset_free(v: Dictionary) -> void:
	v.free = {}
	for skill in v.skills:
		if skill.begins_with("free_"):
			var type = skill.trim_prefix("free_")
			v.free[type] = int(v.free.get(type,0))+1

func action_cost(v: Dictionary,type: String) -> int:
	if int(v.get("free",{}).get(type,0)) > 0: return 0
	if type in ["melee","ranged"] and int(v.get("free",{}).get("combat",0)) > 0: return 0
	return 1

func can_pay(v: Dictionary,type: String,extra: int = 0) -> bool:
	return v.get("actions",0) >= action_cost(v,type)+extra

func pay(v: Dictionary,type: String,extra: int = 0) -> void:
	if int(v.free.get(type,0)) > 0: v.free[type] -= 1
	elif type in ["melee","ranged"] and int(v.free.get("combat",0)) > 0: v.free.combat -= 1
	else: v.actions -= 1
	v.actions -= extra
