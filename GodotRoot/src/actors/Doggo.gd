extends Actor

var last_movedir_y: int = 0

#func ready_turn_actions_OLD():
#	# Move 1 direction randomly
#	act.prep_random_move_actor(self)
#
#	# Perform a charge, then return to the original position
#	act.prep_relative_move(self, Vector2.LEFT, true, true, true)
#	act.prep_simple_attack(self, false, false)
#	act.prep_relative_move(self, Vector2.RIGHT, true, false, true)
#
#	# All actions readied!
#	act.start_action_queue(self)
##	print(act.actionlog)
#	pass

func begin_turn():
	# First: If we already have a viable victim, don't bother moving up or down
	if check_for_victim():
		return
	
	# No victim? Check if we can vertmove (prioritizing your logged movedir)
	if last_movedir_y == 0: last_movedir_y = utils.negchance_int()
	var can_move_vert: bool = true
	var movedir: Vector2 = Vector2(0, last_movedir_y)
	
	if !act.can_move_relative_vector(self, movedir): # If you can't move your preferred way, flip!
		last_movedir_y *= -1
		movedir = Vector2(0, last_movedir_y)
		if !act.can_move_relative_vector(self, movedir):
			can_move_vert = false
	
	# If vertmove is possible, do that! Then victimcheck again
	if can_move_vert:
		act.prep_relative_move(self, movedir)
		print("Moving up and down to seek a target...")
		check_for_victim()
		return
	
	# If we CAN'T move up or down, move forward or back (at random) if able, then end your turn
	var moptions: Array = act.vet_move_targetset(self, [Vector2.LEFT, Vector2.RIGHT])
	if moptions.empty():
		print(name,": Can't do anything; skip!")
		act.skip_turn(self)
	else:
		moptions.shuffle()
		act.prep_relative_move(self, moptions[0])
		print(name,": Moving left/right because couldn't move up/down")
		act.start_action_queue(self)
	end_turn()
	pass

func check_for_victim() -> bool:
	var victim: Actor = act.find_first_actor_in_dir(coord, Vector2.LEFT)
	if victim != null:
		if victim.faction == factions.PLAYER:
			set_up_attack(victim)
			return true
	return false
	pass

func set_up_attack(victim: Actor): # Handles the 'charge and bite OR just bite' stuff
	var need_to_charge: bool = victim.coord != (coord + Vector2.LEFT)
	
	if need_to_charge:
		print("Charging to bite target!")
		act.prep_relative_move(self, Vector2.LEFT, true, true, true)
	else:
		print("Biting target (no need to charge)")
	act.prep_simple_attack(self, false, false)
	if need_to_charge:
		act.prep_relative_move(self, Vector2.RIGHT, true, false, true)
	print(name,": Can attack at start of turn, so simply doing so!")
	act.start_action_queue(self)
	end_turn()
	pass

func ACT_charge_forward():
	# Quickly move the furthest left you are able, crossing faction lines
	pass

func ACT_charge_back():
	# Return to your pre-charge starting position
	pass

func ACT_bite():
	# Assuming there's an actor to your left, bite
	pass

func ACT_walk_1_tile():
	# Move 1 tile within your faction bounds
	pass

func begin_turn_OLD():
	# First: If we already have a viable enemy target, skip right to the attack without moving
	var victim: Actor = act.find_first_PC_in_dir(coord, Vector2.LEFT)
	if victim != null:
		
		var need_to_charge: bool = victim.coord != (coord + Vector2.LEFT)
		
		if need_to_charge:
			act.prep_relative_move(self, Vector2.LEFT, true, true, true)
		act.prep_simple_attack(self, false, false)
		if need_to_charge:
			act.prep_relative_move(self, Vector2.RIGHT, true, false, true)
		print(name,": Can attack at start of turn, so simply doing so!")
		act.start_action_queue(self)
		
		return
	
	# Second: If we DON'T have a viable enemy target, try to move up or down (prioritizing your logged movedir)
	if last_movedir_y == 0: last_movedir_y = utils.negchance_int()
	var can_move_vert: bool = true
	var movedir: Vector2 = Vector2(0, last_movedir_y)
	
	if !act.can_move_relative_vector(self, movedir): # If you can't move your preferred way, flip!
		last_movedir_y *= -1
		movedir = Vector2(0, last_movedir_y)
		if !act.can_move_relative_vector(self, movedir):
			can_move_vert = false
	
	# Moving up/down is viable! Do so, then attempt to attack from that position
	if can_move_vert:
		act.prep_relative_move(self, movedir)
		
		# If we CAN move, check if we could attack from the dest position
		victim = act.find_first_PC_in_dir(coord + movedir, Vector2.LEFT)
		if victim != null:
			var need_to_charge: bool = victim.coord != (coord + Vector2.LEFT)
		
			if need_to_charge:
				act.prep_relative_move(self, Vector2.LEFT, true, true, true)
			act.prep_simple_attack(self, false, false)
			if need_to_charge:
				act.prep_relative_move(self, Vector2.RIGHT, true, false, true)
			print(name,": Moving up/down and THEN attacking")
		else:
			print(name,": Moving up/down, but can't attack after")
			pass
		
		act.start_action_queue(self)
		return
	
	# If we CAN'T move up or down, move forward or back (at random) and end your turn
	var moptions: Array = act.vet_move_targetset(self, [Vector2.LEFT, Vector2.RIGHT])
	if moptions.empty():
		print(name,": Can't do nothing; skip!")
		act.skip_turn(self)
	else:
		moptions.shuffle()
		act.prep_relative_move(self, moptions[0])
		print(name,": Moving left/right because couldn't move up/down")
		act.start_action_queue(self)
	pass


