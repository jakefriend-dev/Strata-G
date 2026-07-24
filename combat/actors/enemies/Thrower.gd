extends ActorEnemy

#const COST_: int = 1
#const COST_: int = 1
const COST_AIM_ROCK: int = 1
const COST_THROW: int = 2
const COST_KICK: int = 2

enum {NO_ROCK, HELD_ROCK, DROPPED_ROCK}
var rockstate: int = NO_ROCK
# ---

func _ready():
#	connect("on_shield_broken_through", self, "on_shield_broken")
	pass

func pre_combat_setup():
#	PREFIGHT_prep_rock()
	prime_npc_move(moveset["ROCK_THROWERY"], true)
	pass

func pre_turn_setup():
	pass

func prep_next_action(): # This func should END with setting up one or multiple actions!
	
	# Follow-through on your telegraphed move, if you can
	if telegraphed_move != null:
		if telegraphed_move.totality_check(self):
			prime_npc_move(telegraphed_move)
			return
		else:
			clear_telegraphed_move()
	
	# If we CAN'T telegraph, as noted by still having enough AP at this point, enrage!
	if can_afford(moveset["ENRAGE_BUFF"].cost + moveset["ROCK_THROWERY"].telegraph_cost):
		if moveset["ENRAGE_BUFF"].totality_check(self):
			prime_npc_move(moveset["ENRAGE_BUFF"])
			return
	
	# At this point, we have no use for 'spare' AP, just fire our telegraph and end turn
	if telegraphed_move != null: return
	
	if moveset["ROCK_THROWERY"].totality_check(self):
		prime_npc_move(moveset["ROCK_THROWERY"])
		return
	pass


#
#	if rockstate == NO_ROCK:
#		# When we're rockless, prioritize getting one!
#		if can_afford(COST_AIM_ROCK):
#			spend(COST_AIM_ROCK)
#			batman.append_action(self, "prep_rock")
#			return
#		return
#
#	if rockstate == HELD_ROCK:
#		if can_afford(COST_THROW):
#			if !targeted_tiles.empty():
#				spend(COST_THROW)
#				batman.append_action(self, "throw_rock")
#				return
#		return
#
#	if rockstate == DROPPED_ROCK:
#		if can_afford(COST_KICK):
#			spend(COST_KICK)
#			batman.append_action(self, "kick_rock")
#			return
#		return
#
#	# DEFAULT ELSE: Can't go anywhere, can't do nothin' :(
#	pass

#func on_shield_broken(_combat_package: Dictionary):
#	if telegraphed_move == moveset["ROCK_THROWERY"]:
#		moveset["ROCK_THROWERY"].drop_rock_reaction = true
#		prime_npc_move(moveset["ROCK_THROWERY"], true)
#		return
##	batman.reaction(self, "drop_rock")
#	pass

# ---

#func PREFIGHT_prep_rock():
#	# Pick a PC!
#	var pcs: Array = batman.get_all_current_players()
##	print("pcs: ",pcs)
#	pcs.shuffle()
#	for pc in pcs:
#		if !batman.targeted_tiles.has(pc.coord):
#			set_targeted_tiles([pc.coord])
#	# If there wasn't a 'free' PC, double-target
#	if targeted_tiles.empty():
#		set_targeted_tiles([pcs[0].coord])
#
#	rockstate = HELD_ROCK
#	sprite.frame = rockstate
#
##	end_action()
#	pass

#func ACT_prep_rock():
#
#	# Pick a PC!
#	var pcs: Array = batman.get_all_current_players()
#	pcs.shuffle()
#	for pc in pcs:
#		if !batman.targeted_tiles.has(pc.coord):
#			set_targeted_tiles([pc.coord])
#	# If there wasn't a 'free' PC, double-target
#	if targeted_tiles.empty():
#		set_targeted_tiles([pcs[0].coord])
#
#	strife.quick_vfx(self, "spark_burst")
#
#	rockstate = HELD_ROCK
#	sprite.frame = rockstate
#
#	yield(utils.yt(0.25, self), "timeout")
#	if !batman.is_my_action(self): return
#
#	end_action()
#	pass

#func ACT_drop_rock(): # Shield break!
#	release_targeted_tiles()
#	if rockstate == HELD_ROCK:
#		rockstate = DROPPED_ROCK
#		sprite.frame = rockstate
#		strife.damage_actor_at_coord(self, coord, dmg(1))
#
#	yield(utils.yt(0.125, self), "timeout")
#	if !batman.is_my_action(self): return
#
#	end_action()
#	pass

#func ACT_throw_rock():
#	var target: Vector2 = targeted_tiles[0] # Just in case of accidental multiple
#
#	yield(utils.yt(0.125, self), "timeout")
#	if !batman.is_my_action(self): return
#
#	strife.damage_actor_at_coord(self, target, dmg(1))
#	strife.quick_vfx(self, "spark_burst")
#	rockstate = NO_ROCK
#	sprite.frame = rockstate
#
#	yield(utils.yt(0.25, self), "timeout")
#	if !batman.is_my_action(self): return
#
#	end_action()
#	pass

#func ACT_kick_rock():
#	var victim: Actor = support.find_nearest_actor_in_dir(coord, Vector2.LEFT)
#	if !victim == null:
#		strife.damage_actor_at_coord(self, victim.coord, dmg(1))
#
#	rockstate = NO_ROCK
#	sprite.frame = rockstate
#	end_action()
#	pass








