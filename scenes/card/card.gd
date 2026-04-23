class_name Card
extends Control

signal drop_attempted(card: Card)

const HOVER_SCALE := Vector2(1.08, 1.08)

var card_data: CardData
var is_dragging := false
var mouse_offset := Vector2.ZERO
var in_hand := true

@onready var cost_label: Label = $Cost
@onready var name_label: Label = $CardName
@onready var desc_label: Label = $Description
@onready var type_label: Label = $TypeLabel


func setup(data: CardData) -> void:
	card_data = data
	name_label.text = data.card_name
	cost_label.text = "X" if data.cost < 0 else str(data.cost)
	desc_label.text = data.description
	type_label.text = CardData.Type.keys()[data.type]


func _gui_input(event: InputEvent) -> void:
	if not in_hand:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		is_dragging = true
		mouse_offset = get_global_mouse_position() - global_position
		z_index = 50
		scale = HOVER_SCALE
		get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if not is_dragging:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		is_dragging = false
		z_index = 0
		scale = Vector2.ONE
		drop_attempted.emit(self)


func _process(_delta: float) -> void:
	if is_dragging:
		global_position = get_global_mouse_position() - mouse_offset


func set_playable(playable: bool) -> void:
	modulate = Color.WHITE if playable else Color(0.5, 0.5, 0.5, 0.8)
