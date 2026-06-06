extends Actor
class_name ActorPlayer

var staple_attack: String
var staple_cost: int = 1

# ---

func ACT_basic_move(dir: Vector2):
#	var actor: Actor = get_actor()
#	print(actor.name,": executing basic move")
	
	var exact_coord: Vector2 = coord + dir
	var dur: float = 0.125
	
	hotmove(exact_coord, dur)
	yield(utils.yt(dur, self), "timeout")
	if !batman.is_my_turn(self): return
	
	end_action()
	pass

func ACT_staple_attack():
	call(str("ACT_"+staple_attack))
	pass

func ACT_basic_shot():
	var victim: Actor = act.find_nearest_actor_in_dir(coord, Vector2.RIGHT)
	if victim == null: end_action()
	
	strife.damage_actor_at_coord(self, victim.coord, base_damage, false)
	
	end_action()
	pass

func ACT_basic_melee():
	var exact_coord: Vector2 = coord + Vector2.RIGHT
	
	strife.damage_actor_at_coord(self, exact_coord, base_damage, true)
	
	end_action()
	pass

