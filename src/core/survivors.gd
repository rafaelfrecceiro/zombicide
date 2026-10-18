extends RefCounted
## Mechanical transcription from the preserved ZCD001, pp.7/15/63/65.
## Art remains an original study, not the official survivor illustrations.
static func profiles() -> Dictionary:
	return {
		"amy":{"name":"Amy","source":"ZCD001 p7","blue":"free_move","orange":["free_melee","free_ranged"],"red":["die_combat","accuracy_combat","medic"]},
		"elle":{"name":"Elle","source":"ZCD001 p15","blue":"sniper","orange":["die_combat","free_ranged"],"red":["die_ranged","free_combat","accuracy_ranged"]}
	}

static func skill_name(id: String) -> String:
	return {"free_move":"+1 ação gratuita de movimento","free_melee":"+1 ação gratuita corpo a corpo","free_ranged":"+1 ação gratuita à distância","free_combat":"+1 ação gratuita de combate","die_combat":"+1 dado por arma em combate","die_ranged":"+1 dado por arma à distância","accuracy_combat":"+1 no resultado dos dados de combate","accuracy_ranged":"+1 no resultado dos dados à distância","sniper":"Atiradora: escolhe alvos, sem fogo amigo","medic":"Médica: cura 1 ferimento por pessoa na zona ao fim da rodada"}.get(id,id)

static func skill_label(id: String) -> String:
	return {"free_move":"Movimento grátis","free_melee":"Corpo a corpo grátis","free_ranged":"Ataque à distância grátis","free_combat":"Combate grátis","die_combat":"+1 dado: combate","die_ranged":"+1 dado: distância","accuracy_combat":"+1 na rolagem: combate","accuracy_ranged":"+1 na rolagem: distância","sniper":"Atiradora","medic":"Médica"}.get(id,id)
