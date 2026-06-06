extends Actor

#const COST_: int = 1
#const COST_: int = 1
#const COST_: int = 1
#const COST_: int = 1
#const COST_: int = 1
#const COST_: int = 1
const COST_WALK: int = 1

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

func ACT_walk(motion: Vector2):
	# Move 1 tile within your faction bounds
#	print("Moving ",motion," to seek a target (if vertmove, may still charge")
	
	var dest_coord: Vector2 = coord + motion
	
	var dur: float = 0.75
	
	hotmove(dest_coord, dur)
	yield(utils.yt(dur, self), "timeout")
	if !batman.is_my_turn(self): return
	
	end_action()
	
	pass






