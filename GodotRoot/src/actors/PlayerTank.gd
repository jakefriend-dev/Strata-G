extends ActorPlayer



const moveset: Dictionary = {
	
#	# TEMPLATE
#	"move_key": {
#		"display_name": "Move Name",
#		"display_desc": "Do this set of actions when you pick this move.",
#		"options": 0, # Typically 0 but could be an infinite number
#		"cost": 1,
#		"cooldown": 0, # 0 = no cooldown; 1 = after using, you cannot use it the next 1 turns
#		"initial_cooldown": 0, # Turns required until ability is first usable
#		"uses_per_turn": 0, # 0 = infinite; any positive int = limited
#		"uses_per_battle": 0, # As above, but in total all fight
#	},
	
	"basic_melee": {
		"display_name": "Strike",
		"display_desc": "Hit a unit immediately in front of you.",
		"options": 0, # Typically 0 but could be an infinite number
		"cost": 2,
		"cooldown": 0, # 0 = no cooldown; 1 = after using, you cannot use it the next 1 turns
		"initial_cooldown": 0, # Turns required until ability is first usable
		"uses_per_turn": 0, # 0 = infinite; any positive int = limited
		"uses_per_battle": 0, # As above, but in total all fight
	},

}

# ---

func _ready():
#	print(name," connecting signals")
	connect("on_shield_consumed", self, "prep_melee_counter")
	pass

func prep_melee_counter(is_melee: bool):
#	print(name," reacting to melee damage!")
	if !is_melee: return
	
#	print(name," reacting to melee damage!")
	batman.reaction(self, "basic_melee")
	pass
