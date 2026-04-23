extends Control

const CARD_SCENE := preload("res://scenes/card/card.tscn")
const CARD_WIDTH := 120
const CARD_HEIGHT := 180
const CARD_SPACING := 12
const VIEWPORT_W := 1280

var player_hp := 80
var player_max_hp := 80
var player_block := 0
var player_strength := 0
var player_energy := 3
var player_max_energy := 3

var enemy_hp := 42
var enemy_max_hp := 44
var enemy_block := 0
var enemy_strength := 0

var hand: Array[Card] = []
var draw_pile: Array[CardData] = []
var discard_pile: Array[CardData] = []

var player_turn := true

@onready var hand_container: Control = $HandContainer
@onready var play_zone: Panel = $PlayZone
@onready var player_hp_label: Label = $BattleArea/PlayerSide/HPLabel
@onready var player_block_label: Label = $BattleArea/PlayerSide/BlockLabel
@onready var enemy_hp_label: Label = $BattleArea/EnemySide/HPLabel
@onready var enemy_intent_label: Label = $BattleArea/EnemySide/IntentLabel
@onready var energy_label: Label = $UILayer/EnergyLabel
@onready var turn_label: Label = $UILayer/TurnLabel
@onready var end_turn_btn: Button = $UILayer/EndTurnButton


func _ready() -> void:
	end_turn_btn.pressed.connect(_on_end_turn_pressed)
	_init_deck()
	_shuffle(draw_pile)
	_start_player_turn()


func _init_deck() -> void:
	for i in 5:
		draw_pile.append(_make_card("Strike", 1, CardData.Type.ATTACK, "Deal 6 damage.", 6))
	for i in 4:
		draw_pile.append(_make_card("Defend", 1, CardData.Type.SKILL, "Gain 5 Block.", 0, 5))
	draw_pile.append(_make_card("Bash", 2, CardData.Type.ATTACK, "Deal 8 dmg.\nApply 2 Vuln.", 8, 0, 2))


func _make_card(cname: String, cost: int, type: CardData.Type, desc: String,
		dmg: int = 0, blk: int = 0, vuln: int = 0) -> CardData:
	var d := CardData.new()
	d.card_name = cname
	d.cost = cost
	d.type = type
	d.description = desc
	d.damage = dmg
	d.block_amount = blk
	d.vulnerable_stacks = vuln
	return d


func _start_player_turn() -> void:
	player_turn = true
	player_block = 0
	player_energy = player_max_energy
	_draw_cards(5)
	_update_ui()
	turn_label.text = "Your Turn"
	end_turn_btn.disabled = false


func _draw_cards(count: int) -> void:
	for i in count:
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				return
			draw_pile = discard_pile.duplicate()
			discard_pile.clear()
			_shuffle(draw_pile)
		if hand.size() >= 10:
			break
		_spawn_card(draw_pile.pop_back())


func _spawn_card(data: CardData) -> void:
	var card: Card = CARD_SCENE.instantiate()
	hand_container.add_child(card)
	card.setup(data)
	card.drop_attempted.connect(_on_card_drop_attempted)
	hand.append(card)
	_reposition_hand()
	_refresh_playability()


func _reposition_hand() -> void:
	var n := hand.size()
	if n == 0:
		return
	var total_w := n * CARD_WIDTH + (n - 1) * CARD_SPACING
	var start_x := (VIEWPORT_W - total_w) / 2.0
	for i in n:
		if not hand[i].is_dragging:
			hand[i].position = Vector2(start_x + i * (CARD_WIDTH + CARD_SPACING), 5.0)


func _on_card_drop_attempted(card: Card) -> void:
	var center := card.global_position + Vector2(CARD_WIDTH, CARD_HEIGHT) / 2.0
	if play_zone.get_global_rect().has_point(center):
		_try_play_card(card)
	else:
		_reposition_hand()


func _try_play_card(card: Card) -> void:
	if not player_turn or card.card_data.cost > player_energy:
		_reposition_hand()
		return
	player_energy -= card.card_data.cost
	_apply_effect(card.card_data)
	hand.erase(card)
	discard_pile.append(card.card_data)
	card.queue_free()
	_update_ui()
	_reposition_hand()
	_refresh_playability()
	if enemy_hp <= 0:
		_victory()


func _apply_effect(data: CardData) -> void:
	if data.damage > 0:
		var dmg := data.damage + player_strength
		var absorbed := min(dmg, enemy_block)
		enemy_block -= absorbed
		enemy_hp -= dmg - absorbed
	if data.block_amount > 0:
		player_block += data.block_amount
	if data.strength_gain > 0:
		player_strength += data.strength_gain


func _on_end_turn_pressed() -> void:
	if not player_turn:
		return
	player_turn = false
	end_turn_btn.disabled = true
	turn_label.text = "Enemy Turn"
	for card in hand:
		discard_pile.append(card.card_data)
		card.queue_free()
	hand.clear()
	_update_ui()
	await get_tree().create_timer(0.8).timeout
	_run_enemy_turn()


func _run_enemy_turn() -> void:
	var dmg := 11 + enemy_strength
	var absorbed := min(dmg, player_block)
	player_block -= absorbed
	player_hp -= dmg - absorbed
	_update_ui()
	if player_hp <= 0:
		_game_over()
		return
	await get_tree().create_timer(0.6).timeout
	_start_player_turn()


func _refresh_playability() -> void:
	for card in hand:
		card.set_playable(card.card_data.cost <= player_energy)


func _update_ui() -> void:
	player_hp_label.text = "HP: %d/%d" % [player_hp, player_max_hp]
	player_block_label.text = "Block: %d" % player_block
	enemy_hp_label.text = "HP: %d/%d" % [enemy_hp, enemy_max_hp]
	enemy_intent_label.text = "Attack %d" % (11 + enemy_strength)
	energy_label.text = "Energy: %d/%d" % [player_energy, player_max_energy]


func _victory() -> void:
	player_turn = false
	end_turn_btn.disabled = true
	turn_label.text = "Victory!"


func _game_over() -> void:
	player_turn = false
	end_turn_btn.disabled = true
	turn_label.text = "Game Over"


func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := randi() % (i + 1)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
