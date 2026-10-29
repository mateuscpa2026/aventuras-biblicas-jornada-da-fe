class_name PlayerLooks
## Exploradores que a criança pode escolher para guiar a jornada.
## Cada visual usa o mesmo StylizedRig; nenhum recurso externo é necessário.

const DEFAULT_ID := "josue"

const LOOKS := [
	{
		"id": "josue",
		"name": "Josué",
		"tag": "Gosta de ajudar",
		"colors": {
			"skin": Color("#d9a273"),
			"hair": Color("#2f2119"),
			"iris": Color("#4c3222"),
			"tunic": Color("#4f8a54"),
			"trim": Color("#e8b45c"),
			"pants": Color("#6d5846"),
			"shoe": Color("#4a3424"),
			"gender": "male",
			"outfit": "tunic",
			"hair_style": "short",
			"headwear": "headband",
			"sash": Color("#e8b45c"),
		},
	},
	{
		"id": "ester",
		"name": "Ester",
		"tag": "Curiosa e corajosa",
		"colors": {
			"skin": Color("#eec39c"),
			"hair": Color("#3a271d"),
			"iris": Color("#6b4a2a"),
			"tunic": Color("#3d7f96"),
			"trim": Color("#f4c86a"),
			"pants": Color("#6d5846"),
			"shoe": Color("#7a5438"),
			"gender": "female",
			"outfit": "dress",
			"hair_style": "braid",
			"headwear": "headband",
			"jewelry": true,
			"sash": Color("#f4c86a"),
		},
	},
	{
		"id": "sara",
		"name": "Sara",
		"tag": "Alegre e atenta",
		"colors": {
			"skin": Color("#8d5b3c"),
			"hair": Color("#1d1510"),
			"iris": Color("#3d2a1c"),
			"tunic": Color("#c96a55"),
			"trim": Color("#f2d38a"),
			"pants": Color("#6d5846"),
			"shoe": Color("#5a3b26"),
			"gender": "female",
			"outfit": "dress",
			"hair_style": "bun",
			"headwear": "none",
			"jewelry": true,
			"sash": Color("#f2d38a"),
		},
	},
	{
		"id": "daniel",
		"name": "Daniel",
		"tag": "Sempre pronto",
		"colors": {
			"skin": Color("#f0c9a5"),
			"hair": Color("#6b4423"),
			"iris": Color("#557a5a"),
			"tunic": Color("#b5643f"),
			"trim": Color("#efd8a6"),
			"pants": Color("#7f6a50"),
			"shoe": Color("#4d3a2a"),
			"gender": "male",
			"outfit": "tunic",
			"hair_style": "curly",
			"headwear": "none",
			"sash": Color("#efd8a6"),
		},
	},
]

static func ids() -> Array[String]:
	var result: Array[String] = []
	for look in LOOKS:
		result.append(str(look["id"]))
	return result

static func is_valid(look_id: String) -> bool:
	for look in LOOKS:
		if str(look["id"]) == look_id:
			return true
	return false

static func get_look(look_id: String) -> Dictionary:
	for look in LOOKS:
		if str(look["id"]) == look_id:
			return look
	return LOOKS[0]

static func name_of(look_id: String) -> String:
	return str(get_look(look_id).get("name", "Explorador"))

static func colors(look_id: String) -> Dictionary:
	return get_look(look_id).get("colors", {})

static func apply(rig: Node, look_id: String) -> void:
	if rig and rig.has_method("configure"):
		rig.configure(colors(look_id))
