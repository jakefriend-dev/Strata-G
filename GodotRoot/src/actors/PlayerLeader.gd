extends ActorPlayer

#const COST_: int = 1
#const COST_: int = 1
#const COST_: int = 1
#const COST_: int = 1
#const COST_: int = 1
#const COST_: int = 1

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
	
	"basic_shot": {
		"display_name": "Simple Shot",
		"display_desc": "Shoot the first unit in your line of sight.",
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
	
	pass

func pre_turn_setup():
	pass

func prep_next_action(): # This func should END with setting up one or multiple actions!
	
	# SAMPLE REFERENCE from DOGGO!
#	# If we can afford to charge (and have space to), do that!
#	if can_afford(COST_CHARGE) and can_charge_left:
#		spend(COST_CHARGE) # This is the charge-AND-bite combo
#		batman.append_action(self, "charge_forward")
#		batman.append_action(self, "bite")
#		batman.append_action(self, "charge_back")
#		return
	
	
	
	# DEFAULT ELSE: Can't go anywhere, can't do nothin' :(
	pass





