extends Actor

#const COST_: int = 1
#const COST_: int = 1
#const COST_: int = 1
#const COST_: int = 1
#const COST_: int = 1
#const COST_: int = 1

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

# ---


func ACT_charge_forward():
	# Claim everything to your left (that you can move to!
	allowed_over_faction_lines = true
	var chargies: Array = support.list_all_traversible_tiles_in_dir(Vector2.LEFT, self)
#	print("chargies: ",chargies)
	var xdist: int = chargies.size()
	
	if xdist == 0: # Just in case
		batman.skip_action()
		return
	
	# We're clear! Mark the endpoint and claim before moving
	claim_tile()
	var dest_coord: Vector2 = chargies.back()
	
	# Perform a visual movement to the destination cell!
	var dur: float = float(xdist)*0.1
	hotmove(dest_coord, dur)
	
	yield(utils.yt(dur, self), "timeout")
	if !batman.is_my_action(self): return
	
	end_action()
	pass

#func ACT_charge_back():
##	print("Returning from our charge!")
#
#	# Safety check; we should not start from our claimed tile
#	if coord == claimed_tile:
#		batman.skip_action()
#		return
#
#	var valid_xdist: float = abs(claimed_tile.x - coord.x)
#
#	# Perform a visual movement to the destination cell!
#	var dur: float = valid_xdist*0.1
#	hotmove(claimed_tile, dur)
#	yield(utils.yt(dur, self), "timeout")
#	if !batman.is_my_action(self): return
#
#	allowed_over_faction_lines = false
#	end_action()
#	pass
#
#func ACT_bite():
#	# Bites to the left; we are dumb so if this gets called we're not worrying about if there's a target or friendly fire.
##	print("Biting!")
#
#	var damage: int = base_damage
#	if check_status("enrage"):
#		damage += batman.BASE_HP_FACTOR
#	strife.damage_actor_at_coord(self, coord + Vector2.LEFT, damage)
#
#	clear_status("enrage") # Whether it's active of not
#	strife.end_vfx_on_actor(self, "buff", true)
#	if !batman.is_my_action(self): return
#
#	end_action()
#	pass
#
#func ACT_enrage():
#	start_status("enrage", "Enrage", "good", 2, true)
#	strife.quick_vfx(self, "quick_good")
#	strife.quick_vfx(self, "buff")
##	add_bonus_actions(1)
#
#	yield(utils.yt(0.5, self), "timeout")
#	if !batman.is_my_action(self): return
#
#	end_action()
#	pass








