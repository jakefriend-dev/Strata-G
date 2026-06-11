extends Resource
class_name PlayerAction

# Make sure all TRES files extending this script is set as local to scene, so it can be used by multiple actors!

export var display_name: String
export (String, MULTILINE) var display_desc: String
var key: String # For "Yank-Shot" it's "yank" - whatever the resource name is. Just a convenient reference point; almost certainly a redundancy.

export (int, 0, 8) var options: int = 0
export (String, MULTILINE) var option_desc: String

export (int, 0, 8) var cost: int = 1

export (int, 0, 8) var on_use_cooldown: int = 0
export (int, 0, 8) var initial_cooldown: int = 0
var current_cooldown: int = 0

export var misc: String

export (int, 0, 8) var uses_per_turn: int = 0
export (int, 0, 8) var uses_per_battle: int = 0
var current_turn_uses: int = 0
var current_battle_uses: int = 0

# Nah, the ability script can do this on its own
#export var damage_tags: String = "" # Tags IF damage is called
#export var motion_tags: String = "" # Tags IF external motion is called

export var req_successful_preview: bool = false

var actor: Actor # Just a handy quickref

# ---

func _ready():
	pass

func log_use():
	current_battle_uses += 1
	current_turn_uses += 1
	if on_use_cooldown > 0:
		current_cooldown = (on_use_cooldown + 1) # Adds 1 to account for current turn
	pass
