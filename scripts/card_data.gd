class_name CardData
extends Resource

enum Type { ATTACK, SKILL, POWER, STATUS }

@export var card_name: String = "Card"
@export var cost: int = 1
@export var description: String = ""
@export var type: Type = Type.ATTACK
@export var damage: int = 0
@export var block_amount: int = 0
@export var draw_amount: int = 0
@export var strength_gain: int = 0
@export var vulnerable_stacks: int = 0
@export var weak_stacks: int = 0
@export var exhaust: bool = false
