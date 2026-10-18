extends RefCounted
## Map transcribed from ZCD001 p.36 using the zone definition on p.9.
## Equipment, survivor profiles and decks remain incomplete laboratory content.

const VERSION = "m0-lab-v3-skills"

static func board() -> Dictionary:
	var zones = {}
	# Names below are descriptive labels of our own, not official room names.
	var names = {"a":"Café", "b":"Depósito", "c":"Arquivo", "e":"Sala", "f":"Banheiro", "g":"Quarto", "h":"Oficina", "w0":"Saída", "v2":"Cruzamento sul", "v0":"Rua central", "n0":"Cruzamento norte", "n3":"Rua nordeste"}
	# Left, top, width, height in schematic board units. A tile seam is NOT a zone boundary.
	var areas = {"a":[0,0,1,1],"b":[1,0,1,2],"c":[0,1,1,1],"e":[4,1,1,1],"f":[5,1,1,1],"g":[4,2,1,1],"h":[5,2,1,1],"w0":[0,2,2,1],"v2":[2,2,2,1],"v0":[2,1,2,1],"n0":[2,0,2,1],"n3":[4,0,2,1]}
	for id in areas:
		var r = areas[id]
		var building = "west" if id in ["a","b","c"] else ("east" if id in ["e","f","g","h"] else "")
		zones[id] = {"id":id,"name":names[id],"left":r[0],"top":r[1],"width":r[2],"height":r[3],"x":r[0]+r[2]/2.0-0.5,"y":r[1]+r[3]/2.0-0.5,"inside":not building.is_empty(),"building":building,"dark":id in ["b","c","e","h"]}
	var edges = [["a","b"],["a","c"],["b","c"],["e","f"],["e","g"],["f","h"],["g","h"],["w0","v2"],["v2","v0"],["v0","n0"],["n0","n3"]]
	return {"zones":zones,"edges":edges,"doors":[["b","w0"],["e","n3"],["g","v2"]],"start":"w0","exit":"w0","objectives":["c","h"],"crates":["b","g"],"spawns":["n3","n0"],"initial":[["runner","n0"],["fatty","n0"],["walker","v0"],["walker","v2"]]}

static func bounds(zone: Dictionary) -> Rect2:
	return Rect2(zone.left,zone.top,zone.width,zone.height)

static func border(a: Dictionary,b: Dictionary) -> Dictionary:
	var ra = bounds(a)
	var rb = bounds(b)
	var low = maxf(ra.position.y,rb.position.y)
	var high = minf(ra.end.y,rb.end.y)
	if high > low:
		if ra.end.x == rb.position.x: return {"from":Vector2(ra.end.x,low),"to":Vector2(ra.end.x,high),"direction":Vector2i.RIGHT}
		if rb.end.x == ra.position.x: return {"from":Vector2(ra.position.x,low),"to":Vector2(ra.position.x,high),"direction":Vector2i.LEFT}
	low = maxf(ra.position.x,rb.position.x)
	high = minf(ra.end.x,rb.end.x)
	if high > low:
		if ra.end.y == rb.position.y: return {"from":Vector2(low,ra.end.y),"to":Vector2(high,ra.end.y),"direction":Vector2i.DOWN}
		if rb.end.y == ra.position.y: return {"from":Vector2(low,ra.position.y),"to":Vector2(high,ra.position.y),"direction":Vector2i.UP}
	return {}

static func weapons() -> Dictionary:
	return {
		"pistol":{"name":"Pistola","mode":"ranged","range":[0,1],"dice":1,"accuracy":3,"damage":1,"noise":true,"dual":true},
		"axe":{"name":"Machado","mode":"melee","range":[0,0],"dice":1,"accuracy":4,"damage":2,"noise":false,"door":true,"door_noise":true},
		"crowbar":{"name":"Pé de cabra","mode":"melee","range":[0,0],"dice":1,"accuracy":4,"damage":1,"noise":false,"door":true,"door_noise":false},
		"bat":{"name":"Taco — teste","mode":"melee","range":[0,0],"dice":2,"accuracy":3,"damage":1,"noise":false},
		"shotgun":{"name":"Escopeta","mode":"ranged","range":[0,1],"dice":2,"accuracy":4,"damage":2,"noise":true},
		"molotov":{"name":"Molotov","mode":"ranged","range":[0,1],"dice":0,"accuracy":2,"damage":99,"noise":true,"consume":true},
		"special":{"name":"Arma especial — teste","mode":"ranged","range":[0,2],"dice":3,"accuracy":3,"damage":2,"noise":true},
		"food":{"name":"Provisões — teste","mode":"item"},
		"alarm":{"name":"Aaahh!!","mode":"event"}
	}

static func spawn_samples() -> Array:
	# Only two examples observed in rulebook pp.15/25. Repeated samples are LAB, not a deck.
	return [{"type":"walker","counts":[1,2,4,6],"source":"p15"},{"type":"walker","counts":[3,5,7,9],"source":"p25"}]

static func threshold(kind: String) -> int:
	return {"walker":1,"runner":1,"fatty":2,"abomination":3}.get(kind,1)

static func danger(ap: int) -> int:
	return 3 if ap >= 43 else (2 if ap >= 19 else (1 if ap >= 7 else 0))
