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

# -

func prep_next_action(): # This func should END with setting up one or multiple actions!
	allowed_over_faction_lines = false
	var can_charge_fwd: bool = support.is_tile_traversable_relative(self, my_facing, true)
	print("doggo can charge fwd? ",can_charge_fwd)
	
	# Can we see a victim?
	if can_see_victim():
		print("CAN see victim")
		# Can we bite WITHOUT needing to charge?
		if victim.coord == (coord + my_facing):
			if moveset["BASIC_BITE"].totality_check(self, true):
				prime_npc_move(moveset["BASIC_BITE"])
				return
			# If we're literally next to the target and can't afford to bite, we have 1 or 0 AP left and are already where we want to be; give up manually and wait
			return
		
		# Nope! Time to consider other options. From here on, we're not adjacent to our victim, but we CAN see one.
		
		# If we can afford to charge (and have space to), do that!
		if can_charge_fwd and moveset["FULL_CHARGE"].totality_check(self, true):
			prime_npc_move(moveset["FULL_CHARGE"])
			return
		
		# Otherwise, if we can SEE the target but can't attack it - get angry!
		elif moveset["ENRAGE_BUFF"].totality_check(self):
			prime_npc_move(moveset["ENRAGE_BUFF"])
			return
		
		# *Otherwise*, if we can *only* afford to move towards the target, do that.
		elif walkdir_check(my_facing):
			directed_walk_if_possible(my_facing)
			return
		
		# If we can see the target but can't do ANYTHING else... just end the turn.
		return
	
	# From here on, we know we CAN'T see the target.
	print("CANNOT see victim (or sees shielded victim)")
	
	# If we're enraged, charge/bite regardless! (If we can afford it)
	if check_status("enrage"):
		if can_charge_fwd and moveset["FULL_CHARGE"].totality_check(self, true):
			prime_npc_move(moveset["FULL_CHARGE"])
			return
		elif support.is_cellv_occupied(coord + my_facing) and moveset["BASIC_BITE"].totality_check(self, true):
			prime_npc_move(moveset["BASIC_BITE"])
			return
	
	# At this point, we're moving up and down randomly until we see someone.
	
	# Move up or down if able (prioritizing your last direction)
	var movedir: Vector2 = Vector2(0, last_movedir_y)
	if walkdir_check(movedir):
		directed_walk_if_possible(movedir)
		return
	
	# If you can't move your preferred vert-way, flip!
	last_movedir_y *= -1
	movedir = Vector2(0, last_movedir_y)
	if walkdir_check(movedir):
		directed_walk_if_possible(movedir)
		return
	
	# If we can't vertmove, horzmove? This will be at random.
	var moptions: Array = support.vet_actormove_optionset_relative(self, [Vector2.LEFT, Vector2.RIGHT])
	if !moptions.empty():
		moptions.shuffle()
	
	for motion in moptions:
		if walkdir_check(motion):
			directed_walk_if_possible(motion)
			return
	
	# Can't go anywhere, can't do nothin' :(
	pass

func can_see_victim() -> bool:
	victim = support.find_nearest_actor_in_dir(coord, my_facing)
#	print("victim: ",victim)
	if utils.actorpass(victim):
		if victim.faction != factions.NEUTRAL:
			if victim.faction != faction:
				if (victim.coord == coord + my_facing) and victim.shield <= 3:
					# Avoid shielded enemies if we're ALREADY next to them
					victim = null
					return false
				else:
					return true
	victim = null
	return false
	pass

# -


