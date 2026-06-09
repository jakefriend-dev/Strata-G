extends Actor
class_name ActorPlayer

var staple_attack: String
var staple_cost: int = 1

# ---

func attempt_player_char_move(motion: Vector2):
	if !can_afford(COST_WALK): return
	if !support.is_tile_traversable_relative(self, motion): return
	
	var exact_coord: Vector2 = coord + motion
	
	# Should be valid, then!
	spend(COST_WALK)
	batman.append_action(self, "walk", [exact_coord])
	submit_player_action()
	pass

func attempt_player_char_basicattack():
	var COST: int = staple_cost
	if !can_afford(COST): return
	
	# Should be valid, then!
	spend(COST)
	batman.append_action(self, "staple_attack")
	submit_player_action()
	pass

func submit_player_action():
	emit_signal("player_action_submitted")
	pass

# ---

#func ACT_basic_move(dir: Vector2):
##	var actor: Actor = get_actor()
##	print(actor.name,": executing basic move")
#
#	var exact_coord: Vector2 = coord + dir
#	var dur: float = 0.125
#
#	hotmove(exact_coord, dur)
#	yield(utils.yt(dur, self), "timeout")
#	if !batman.is_my_action(self): return
#
#	end_action()
#	pass

func ACT_staple_attack():
	call(str("ACT_"+staple_attack))
	pass

func ACT_basic_shot():
	var victim: Actor = support.find_nearest_actor_in_dir(coord, Vector2.RIGHT)
	if victim == null:
		end_action()
		return
	
	strife.damage_actor_at_coord(self, victim.coord, base_damage)
	
	end_action()
	pass

func ACT_basic_melee():
	var exact_coord: Vector2 = coord + Vector2.RIGHT
	
	strife.damage_actor_at_coord(self, exact_coord, base_damage)
	
	end_action()
	pass

