class_name StoryCast
## Personagens principais de cada capítulo. O mesmo visual alimenta os retratos
## da abertura e o NPC do mundo, para a criança reconhecer quem vive a história.

const MEMBERS := {
	"adao": {
		"name": "Adão",
		"role": "Cuidador do jardim",
		"look": {
			"skin": Color("#c98d63"), "hair": Color("#3a2a1c"), "tunic": Color("#a8b884"),
			"trim": Color("#d9b96a"), "pants": Color("#7a6a4a"), "shoe": Color("#5a4632"),
			"gender": "male", "outfit": "tunic", "hair_style": "short", "headwear": "headband",
			"cloak": Color("#6f9a6a"),
		},
	},
	"eva": {
		"name": "Eva",
		"role": "Companheira de Adão",
		"look": {
			"skin": Color("#d9a47c"), "hair": Color("#4a2f20"), "tunic": Color("#c98f7a"),
			"trim": Color("#f2c14e"), "pants": Color("#8a6a52"), "shoe": Color("#5a4632"),
			"gender": "female", "outfit": "dress", "hair_style": "braid", "headwear": "none",
			"jewelry": true, "sash": Color("#f2c14e"), "veil": Color("#f7e0b0"),
		},
	},
	"noe": {
		"name": "Noé",
		"role": "Construtor da arca",
		"look": {
			"skin": Color("#cf9c72"), "hair": Color("#e8e2d4"), "beard": Color("#e8e2d4"),
			"tunic": Color("#8a6a45"), "trim": Color("#c9a06a"), "pants": Color("#6b5a4a"),
			"shoe": Color("#4d3a2a"), "scale": 1.02,
			"gender": "male", "outfit": "robe", "hair_style": "short", "headwear": "turban",
			"veil": Color("#cbb38c"), "sash": Color("#b98a62"),
		},
	},
	"sem": {
		"name": "Sem",
		"role": "Filho de Noé",
		"look": {
			"skin": Color("#c98d63"), "hair": Color("#3a2a1c"), "tunic": Color("#7a8f6a"),
			"trim": Color("#c9a06a"), "pants": Color("#6b5a4a"), "shoe": Color("#4d3a2a"),
			"gender": "male", "outfit": "tunic", "hair_style": "short", "headwear": "headband",
		},
	},
	"davi": {
		"name": "Davi",
		"role": "Pastor corajoso",
		"look": {
			"skin": Color("#d9a47c"), "hair": Color("#a85f34"), "tunic": Color("#b98a62"),
			"trim": Color("#d9a441"), "pants": Color("#7a5f42"), "shoe": Color("#4d3a2a"),
			"gender": "male", "outfit": "tunic", "hair_style": "short", "headwear": "headband",
			"cloak": Color("#8a5a3a"), "sash": Color("#d9a441"),
		},
	},
	"samuel": {
		"name": "Samuel",
		"role": "Profeta que ungiu Davi",
		"look": {
			"skin": Color("#b98a63"), "hair": Color("#5a4632"), "beard": Color("#5a4632"),
			"tunic": Color("#8a9e6a"), "trim": Color("#c9a06a"), "pants": Color("#6b5a4a"),
			"shoe": Color("#4d3a2a"), "scale": 1.03,
			"gender": "male", "outfit": "robe", "hair_style": "short", "headwear": "turban",
			"veil": Color("#c9b08a"), "sash": Color("#c9a06a"),
		},
	},
	"moises": {
		"name": "Moisés",
		"role": "Líder do êxodo",
		"look": {
			"skin": Color("#c98d63"), "hair": Color("#e8e2d4"), "beard": Color("#e8e2d4"),
			"tunic": Color("#b98a62"), "trim": Color("#d97b4b"), "pants": Color("#7a5f42"),
			"shoe": Color("#4d3a2a"), "scale": 1.04,
			"gender": "male", "outfit": "robe", "hair_style": "short", "headwear": "turban",
			"veil": Color("#d9c9a8"), "sash": Color("#d97b4b"),
		},
	},
	"miria": {
		"name": "Miriã",
		"role": "Irmã de Moisés",
		"look": {
			"skin": Color("#d9a47c"), "hair": Color("#4a2f20"), "tunic": Color("#8a9e6a"),
			"trim": Color("#f2c14e"), "pants": Color("#7a6a4a"), "shoe": Color("#4d3a2a"),
			"gender": "female", "outfit": "dress", "hair_style": "braid", "headwear": "headband",
			"jewelry": true, "sash": Color("#f2c14e"), "veil": Color("#f7e0b0"),
		},
	},
	"jesus": {
		"name": "Jesus",
		"role": "Mestre do amor",
		"look": {
			"skin": Color("#d9a47c"), "hair": Color("#5a3b26"), "beard": Color("#5a3b26"),
			"tunic": Color("#f2ead2"), "trim": Color("#c9a06a"), "pants": Color("#c9bda0"),
			"shoe": Color("#7a5f42"), "scale": 1.03,
			"gender": "male", "outfit": "robe", "hair_style": "long", "headwear": "none",
			"sash": Color("#c9a06a"),
		},
	},
	"maria": {
		"name": "Maria",
		"role": "Mãe de Jesus",
		"look": {
			"skin": Color("#d9a47c"), "hair": Color("#4a2f20"), "tunic": Color("#8f9fd4"),
			"trim": Color("#e8d6ab"), "pants": Color("#7a6a4a"), "shoe": Color("#4d3a2a"),
			"gender": "female", "outfit": "dress", "hair_style": "braid", "headwear": "veil",
			"jewelry": true, "veil": Color("#8f9fd4"), "sash": Color("#e8d6ab"),
		},
	},
}

static func ids() -> Array[String]:
	var result: Array[String] = []
	for member_id in MEMBERS:
		result.append(str(member_id))
	return result

static func is_valid(member_id: String) -> bool:
	return MEMBERS.has(member_id)

static func member(member_id: String) -> Dictionary:
	return MEMBERS.get(member_id, {})

static func look(member_id: String) -> Dictionary:
	return member(member_id).get("look", {})

static func display_name(member_id: String) -> String:
	return str(member(member_id).get("name", ""))

static func role(member_id: String) -> String:
	return str(member(member_id).get("role", ""))

static func names_of(member_ids: Array) -> String:
	var names: Array[String] = []
	for member_id in member_ids:
		if is_valid(str(member_id)):
			names.append(display_name(str(member_id)))
	if names.is_empty():
		return ""
	if names.size() == 1:
		return names[0]
	var text := names[0]
	for i in range(1, names.size()):
		text += (" e " if i == names.size() - 1 else ", ") + names[i]
	return text

static func names_of_chapter(chapter: Dictionary) -> String:
	return names_of(chapter.get("cast", []))
