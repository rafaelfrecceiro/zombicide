extends RefCounted
## Explicit laboratory content. Numbers are not a complete transcription of the box.

static func board() -> Dictionary:
	var zones = {}
	var names = {"a":"Café", "b":"Escritório", "c":"Arquivo", "d":"Depósito", "e":"Sala", "f":"Cozinha", "g":"Quarto", "h":"Oficina"}
	var cells = {"a":[0,0],"b":[1,0],"c":[0,1],"d":[1,1],"e":[4,1],"f":[5,1],"g":[4,2],"h":[5,2],"n0":[2,0],"n1":[3,0],"n2":[4,0],"n3":[5,0],"v0":[2,1],"v1":[3,1],"v2":[2,2],"v3":[3,2],"w0":[0,2],"w1":[1,2]}
	for id in cells:
		zones[id] = {"id":id,"name":names.get(id,"Rua "+id),"x":cells[id][0],"y":cells[id][1],"inside":names.has(id),"building":"west" if id in ["a","b","c","d"] else ("east" if names.has(id) else ""),"dark":id in ["b","c","e","h"]}
	var edges = [["a","b"],["a","c"],["b","d"],["c","d"],["e","f"],["e","g"],["f","h"],["g","h"],["n0","n1"],["n1","n2"],["n2","n3"],["n0","v0"],["v0","v2"],["n1","v1"],["v1","v3"],["v0","v1"],["v2","v3"],["w0","w1"],["w1","v2"]]
	return {"zones":zones,"edges":edges,"doors":[["d","v0"],["c","w0"],["e","v1"],["e","n2"]],"start":"w0","exit":"w0","objectives":["c","h"],"crates":["d","g"],"spawns":["n3","n0"],"initial":[["runner","n0"],["fatty","n1"],["walker","v0"],["walker","v2"]]}

static func weapons() -> Dictionary:
	return {
		"pistol":{"name":"Pistola","mode":"ranged","range":[0,1],"dice":1,"accuracy":4,"damage":1,"noise":true,"dual":true},
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
