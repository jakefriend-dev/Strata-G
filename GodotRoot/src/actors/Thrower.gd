extends ActorEnemy

#const COST_: int = 1
#const COST_: int = 1
const COST_AIM_ROCK: int = 1
const COST_THROW: int = 2
const COST_KICK: int = 2
const COST_BOOST_SHIELD: int = 1

enum {NO_ROCK, HELD_ROCK, DROPPED_ROCK}
var rockstate: int = NO_ROCK
# ---

func _ready():
	connect("on_shield_broken_any", self, "on_shield_broken")
	pass

func pre_combat_setup():
	ACT_prep_rock()
	pass

func pre_turn_setup():
	pass

func prep_next_action(): # This func should END with setting up one or multiple actions!
	
	if rockstate == NO_ROCK:
		# When we're rockless, prioritize getting one!
		if can_afford(COST_AIM_ROCK):
			spend(COST_AIM_ROCK)
			batman.append_action(self, "prep_rock")
			return
		# If we can't afford to, buff our shield instead for all we've got!
		if can_afford(COST_BOOST_SHIELD):
			var remainder: int = action_points
			spend(remainder)
			batman.append_action(self, "boost_shield", [remainder])
			return
		return
	
	if rockstate == HELD_ROCK:
		if can_afford(COST_THROW):
			if !targeted_tiles.empty():
				spend(COST_THROW)
				batman.append_action(self, "throw_rock")
				return
		return
	
	if rockstate == DROPPED_ROCK:
		if can_afford(COST_KICK):
			spend(COST_KICK)
			batman.append_action(self, "kick_rock")
			return
		return
	
	# DEFAULT ELSE: Can't go anywhere, can't do nothin' :(
	pass

func on_shield_broken(_is_melee):
	batman.reaction(self, "drop_rock")
	pass

# ---

func ACT_prep_rock():
	# Pick a PC!
	var pcs: Array = batman.get_all_current_players()
	pcs.shuffle()
	for pc in pcs:
		if !batman.targeted_tiles.has(pc.coord):
			set_targeted_tiles([pc.coord])
	# If there wasn't a 'free' PC, double-target
	if targeted_tiles.empty():
		set_targeted_tiles([pcs[0].coord])
	
	rockstate = HELD_ROCK
	sprite.frame = rockstate
	end_action()
	pass

func ACT_drop_rock(): # Shield break!
	release_targeted_tiles()
	if rockstate == HELD_ROCK:
		rockstate = DROPPED_ROCK
		sprite.frame = rockstate
		strife.damage_actor_at_coord(self, coord, base_damage)
	end_action()
	pass

func ACT_throw_rock():
	var target: Vector2 = targeted_tiles[0] # Just in case of accidental multiple
	strife.damage_actor_at_coord(self, target, base_damage)
	
	rockstate = NO_ROCK
	sprite.frame = rockstate
	end_action()
	pass

func ACT_kick_rock():
	var victim: Actor = support.find_nearest_actor_in_dir(coord, Vector2.LEFT)
	if !victim == null:
		strife.damage_actor_at_coord(self, victim.coord, base_damage)
	
	rockstate = NO_ROCK
	sprite.frame = rockstate
	end_action()
	pass

func ACT_boost_shield(amount: int):
	bonus_shield = amount
	update_bui()
	end_action()
	pass







