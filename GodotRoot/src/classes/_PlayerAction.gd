extends Resource
class_name MoveAction # Change this to StandaloneAction? or similar...?

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

# Quickrefs!
var actor: Actor
var APD: ActionPreviewData
enum acols {  # TOP TO BOTTOM
	BAD,     # Negative effect, like a debuff OR just plain damage
	GOOD,    # Positive effect, like a buff
	NEUTRAL, # Repositioning
	PASS,    # Shooting through an empty tile
	ERROR    # When an actor blocks a movement from playing out, eg
}

var option: int # Shortcut that gets updated against batman.highlighted_subactop

# ---

func _init():
#	if resource_name == "":
#		resource_name = utils.get_resource_name(self)
#	print(resource_name)
	pass

func log_use():
	actor.spend(cost)
	
	if on_use_cooldown > 0:
		current_cooldown = (on_use_cooldown + 1) # Adds 1 to account for current turn
	
	current_battle_uses += 1
	current_turn_uses += 1
	pass

func end_action():
	actor.end_action()
	pass

var pref: String = "["
var suff: String = "]"
func _to_string() -> String:
	if resource_name != "":
		return str(pref,resource_name,suff)
	return str(pref,utils.get_resource_name(self),suff)
	pass
