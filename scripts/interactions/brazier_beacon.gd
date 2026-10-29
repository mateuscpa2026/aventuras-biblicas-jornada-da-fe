class_name BrazierBeacon
extends Interactable
## Braseiro do deserto: só acende na ordem certa, controlada pelo mundo de Moisés.

@export var order_index := 1
@export var beacon_name := "Sol"

var lit := false
var _flame: Node3D
var _label: Label3D

func _ready() -> void:
	super()
	interact_radius = 3.2
	prompt_height = 2.5
	prompt_text = "Acender o Braseiro do " + beacon_name

	add_child(Props.brazier())
	_flame = get_node_or_null("Brazier/Flame")
	if _flame:
		_flame.visible = false

	_label = Label3D.new()
	_label.name = "BeaconLabel"
	_label.text = "Braseiro do " + beacon_name
	_label.font_size = 46
	_label.pixel_size = 0.0042
	_label.outline_size = 12
	_label.outline_modulate = Color("#3b2a1c")
	_label.modulate = Color("#fff1d0")
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position = Vector3(0, 2.75, 0)
	add_child(_label)

func get_prompt(_player: Node3D) -> String:
	if lit:
		return "Braseiro do %s aceso" % beacon_name
	return "Acender o Braseiro do %s" % beacon_name

func set_lit(value: bool) -> void:
	lit = value
	if _flame:
		_flame.visible = value
	if _label:
		_label.modulate = Color("#fff1d0") if value else Color("#e8d3a8")

func interact(player: Node3D) -> void:
	if lit:
		Game.toast("O Braseiro do %s já está brilhando." % beacon_name, "✦")
		return
	var player_character := player as PlayerCharacter
	if player_character:
		player_character.play_interact_animation()
	var world := get_parent()
	if world and world.has_method("try_light_beacon"):
		world.try_light_beacon(self)
