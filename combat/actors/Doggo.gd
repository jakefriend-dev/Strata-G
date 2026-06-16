extends ActorEnemy

var last_movedir_y: int = 0

const COST_CHARGE: int = 3
const COST_BITE_NOCHARGE: int = 2
const COST_ENRAGE: int = 2

var victim: Actor

# ---

func _ready():
	last_movedir_y = utils.negchance_int()
	pass

func pre_turn_setup():
	allowed_over_faction_lines = false
	victim = null
	pass

#func post_turn_teardown():
#	allowed_over_faction_lines = false
#	victim = null
#	pass

# -

func prep_next_action(): # This func should END with setting up one or multiple actions!
	
	var can_charge_left: bool = support.is_tile_traversable_relative(self, my_facing, true)
#	print("doggo can charge left? ",can_charge_left)
	
	# Can we see a victim?
	if can_see_victim():
		
		# If so, can we bite WITHOUT needing to charge?
		if victim.coord == (coord + my_facing):
			if can_afford(COST_BITE_NOCHARGE):
				spend(COST_BITE_NOCHARGE)
				batman.append_action(self, "bite")
				return
			# If we're literally next to the target and can't afford to bite, we have 1 or 0 AP left and are already where we want to be; give up manually and wait
			return
		
		# Nope! Time to consider other options. From here on, we're not adjacent to our victim, but we CAN see one.
		
		# If we can afford to charge (and have space to), do that!
		if can_afford(COST_CHARGE) and can_charge_left:
			spend(COST_CHARGE) # This is the charge-AND-bite combo
			batman.append_action(self, "charge_forward")
			batman.append_action(self, "bite")
			batman.append_action(self, "charge_back")
			return
		# Otherwise, if we can SEE the target but can't attack it - get angry!
		elif !check_effect("enrage") and can_afford(COST_ENRAGE):
			spend(COST_ENRAGE)
			batman.append_action(self, "enrage")
			return
		# *Otherwise*, if we can move towards the target, do that.
		elif can_afford(COST_WALK):
			if can_charge_left:
				spend(COST_WALK)
				batman.append_action(self, "walk", [Vector2.LEFT])
				return
		# If we can see the target but can't do ANYTHING else, just end the turn.
		return
	
	# From here on, we know we CAN'T see the target. So we need to move!
	
	# If we're enraged, charge/bite regardless! (If we can afford it)
	if check_effect("enrage"):
		if can_charge_left:
			if can_afford(COST_CHARGE):
				print("Doggo charging REGARDLESS OF LACK OF LOS because it enraged last turn! Ostensibly we have at least 1 tile we're allowed to charge into")
				spend(COST_CHARGE)
				batman.append_action(self, "charge_forward")
				batman.append_action(self, "bite")
				batman.append_action(self, "charge_back")
				return
		else:
			if can_afford(COST_BITE_NOCHARGE):
				print("Doggo biting REGARDLESS OF LACK OF LOS because it enraged last turn! And we don't have the ability to charge")
				spend(COST_BITE_NOCHARGE)
				batman.append_action(self, "bite")
				return
	
	if !can_afford(COST_WALK):
		# Or not - we've got no gas left.
		return
	
	# Move up or down if able (prioritizing your last direction)
	var movedir: Vector2 = Vector2(0, last_movedir_y)
	if support.is_tile_traversable_relative(self, movedir):
		spend(COST_WALK)
		batman.append_action(self, "walk", [movedir])
		return
	
	# If you can't move your preferred way, flip!
	last_movedir_y *= -1
	movedir = Vector2(0, last_movedir_y)
	if support.is_tile_traversable_relative(self, movedir):
		spend(COST_WALK)
		batman.append_action(self, "walk", [movedir])
		return
	
	# If we can't vertmove, horzmove? This will be at random.
	var moptions: Array = support.vet_actormove_optionset_relative(self, [Vector2.LEFT, Vector2.RIGHT])
	if !moptions.empty():
		moptions.shuffle()
		spend(COST_WALK)
		batman.append_action(self, "walk", [moptions[0]])
		return
	
	# Can't go anywhere, can't do nothin' :(
	pass

func can_see_victim() -> bool:
	victim = support.find_nearest_actor_in_dir(coord, my_facing)
#	print("victim: ",victim)
	if victim != null:
		if victim.faction == factions.PLAYER:
			return true
	victim = null
	return false
	pass

# -

func ACT_charge_forward():
	# Claim everything to your left (that you can move to!
	allowed_over_faction_lines = true
	var chargies: Array = support.list_all_traversible_tiles_in_dir(my_facing, self)
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

func ACT_charge_back():
#	print("Returning from our charge!")
	
	# Safety check; we should not start from our claimed tile
	if coord == claimed_tile:
		batman.skip_action()
		return
	
	var valid_xdist: float = abs(claimed_tile.x - coord.x)
	
	# Perform a visual movement to the destination cell!
	var dur: float = valid_xdist*0.1
	hotmove(claimed_tile, dur)
	yield(utils.yt(dur, self), "timeout")
	if !batman.is_my_action(self): return
	
	allowed_over_faction_lines = false
	end_action()
	pass

func ACT_bite():
	# Bites to the left; we are dumb so if this gets called we're not worrying about if there's a target or friendly fire.
#	print("Biting!")
	
	var damage: int = base_damage
	if check_effect("enrage"):
		damage += batman.BASE_HP_FACTOR
	strife.damage_actor_at_coord(self, coord + Vector2.LEFT, damage)
	
	clear_effect("enrage") # Whether it's active of not
	strife.end_effect_on_actor(self, "buff", true)
	if !batman.is_my_action(self): return
	
	end_action()
	pass

func ACT_enrage():
	start_effect("enrage", 2)
	strife.quick_effect(self, "quick_good")
	strife.quick_effect(self, "buff")
#	add_bonus_actions(1)
	
	yield(utils.yt(0.5, self), "timeout")
	if !batman.is_my_action(self): return
	
	end_action()
	pass




