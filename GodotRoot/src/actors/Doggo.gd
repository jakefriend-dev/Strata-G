extends Actor

var last_movedir_y: int = 0

# ---

func on_turn_reset():
	allowed_over_faction_lines = false
	pass

# -

func begin_turn():
	# First: If we already have a viable victim, don't bother moving up or down
	if can_see_victim():
		return
	
	# No victim? Check if we can vertmove (prioritizing your logged movedir)
	if last_movedir_y == 0: last_movedir_y = utils.negchance_int()
	var movedir: Vector2 = Vector2(0, last_movedir_y)
	
	var can_move_vert: bool = true
	if !act.is_tile_traversable_relative(self, movedir): # If you can't move your preferred way, flip!
		last_movedir_y *= -1
		movedir = Vector2(0, last_movedir_y)
		if !act.is_tile_traversable_relative(self, movedir):
			can_move_vert = false
	
	# If vertmove is possible, do that! Then victimcheck again
	if can_move_vert:
		act.execute_action(self, "walk_1_tile", [movedir])
		yield(act, "all_action_steps_complete")
		
		if can_see_victim():
			return
		end_turn()
		return
	
	# If we CAN'T move up or down, move forward or back (at random) if able, then end your turn
	var moptions: Array = act.vet_actormove_optionset_relative(self, [Vector2.LEFT, Vector2.RIGHT])
	if moptions.empty():
		print(name,": Can't do anything; skip!")
	else:
		moptions.shuffle()
		act.execute_action(self, "walk_1_tile", [moptions[0]])
		yield(act, "all_action_steps_complete")
	
	end_turn()
	pass

func can_see_victim() -> bool:
	var victim: Actor = act.find_nearest_actor_in_dir(coord, Vector2.LEFT)
#	print("victim: ",victim)
	if victim != null:
		if victim.faction == factions.PLAYER:
			sequence_attack(victim)
			return true
	return false
	pass

func sequence_attack(victim: Actor): # Handles the 'charge and bite OR just bite' stuff
	var need_to_charge: bool = (victim.coord != (coord + Vector2.LEFT))
#	var charge_x_cells: int = act.get_dist_between_actors(self, victim).x
	
	if need_to_charge:
		act.execute_action(self, "charge_forward")
		yield(act, "all_action_steps_complete")
		if !batman.is_my_turn(self): return
	
	act.execute_action(self, "bite")
	yield(act, "all_action_steps_complete")
	if !batman.is_my_turn(self): return
	
	if need_to_charge:
		act.execute_action(self, "charge_back")
		yield(act, "all_action_steps_complete")
		if !batman.is_my_turn(self): return
	
	end_turn()
	pass

# -

func ACT_charge_forward():
	# Claim everything to your left (that you can move to!
	allowed_over_faction_lines = true
	var chargies: Array = act.list_all_traversible_tiles_in_dir(Vector2.LEFT, self)
	var xdist: int = chargies.size()
	
	if xdist == 0: # Just in case
		act.skip_action()
		return
	
	# We're clear! Mark the endpoint and claim before moving
	claim_tile()
	var dest_coord: Vector2 = chargies.back()
	
	# Perform a visual movement to the destination cell!
	var dur: float = float(xdist)*0.1
	act.hotmove(self, dest_coord, dur)
	yield(utils.yt(dur, self), "timeout")
	if !batman.is_my_turn(self): return
	
	end_action()
	pass

func ACT_charge_forward_OLD(xdist: int):
	# Quickly move the furthest left you are able, crossing faction lines
#	print("Charging to bite target!")
	var check_coord: Vector2 = Vector2.ZERO
	var valid_xdist: int = 0
	for x in xdist:
		check_coord.x -= 1
		if act.is_actormove_possible_relative(self, check_coord, true):
			valid_xdist += 1
		else:
			break
	
	if valid_xdist == 0:
		act.skip_action()
		return
	
	var dest_coord: Vector2 = coord
	dest_coord.x -= valid_xdist
	
	if !act.update_actor_coord_data(self, dest_coord):
		act.skip_action()
		return
	
	# Perform a visual movement to the destination cell!
	var dur: float = float(valid_xdist)*0.1
	act.hotmove(self, dest_coord, dur)
	yield(utils.yt(dur, self), "timeout")
	
	end_action()
	pass

func ACT_charge_back():
#	print("Returning from our charge!")
	
	# Safety check; we should not start from our claimed tile
	if coord == claimed_tile:
		act.skip_action()
		return
	
	var valid_xdist: float = abs(claimed_tile.x - coord.x)
	
	# Perform a visual movement to the destination cell!
	var dur: float = valid_xdist*0.1
	act.hotmove(self, claimed_tile, dur)
	yield(utils.yt(dur, self), "timeout")
	if !batman.is_my_turn(self): return
	
	end_action()
	pass

func ACT_bite():
	# Bites to the left; we are dumb so if this gets called we're not worrying about if there's a target or friendly fire.
#	print("Biting!")
	
	act.damage_actor_at_coord(self, coord + Vector2.LEFT, base_damage*batman.BASE_HP_UNIT)
	if !batman.is_my_turn(self): return
	
	end_action()
	pass

func ACT_walk_1_tile(motion: Vector2):
	# Move 1 tile within your faction bounds
#	print("Moving ",motion," to seek a target (if vertmove, may still charge")
	
	var dest_coord: Vector2 = coord + motion
	
#	if !act.update_actor_coord_data(self, dest_coord):
#		act.skip_action()
#		return
	
	var dur: float = 0.5
	
	act.hotmove(self, dest_coord, dur)
	yield(utils.yt(dur, self), "timeout")
	if !batman.is_my_turn(self): return
	
	end_action()
	
	pass






