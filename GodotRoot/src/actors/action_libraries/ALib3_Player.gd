extends ActionLibrary

var actor: Actor
var staple_attack: String
var staple_cost: int = 1

# ---

#func get_actor() -> Node: return get_local_scene()

func ACT_basic_move(dir: Vector2):
#	var actor: Actor = get_actor()
#	print(actor.name,": executing basic move")
	
	var exact_coord: Vector2 = actor.coord + dir
	var dur: float = 0.125
	
	lib_general.hotmove(exact_coord, dur)
	yield(utils.yt(dur, actor), "timeout")
	if !batman.is_my_turn(actor): return
	
	actor.end_action()
	pass

func ACT_staple_attack():
	call(str("ACT_"+staple_attack))
	pass

func ACT_basic_shot():
	var victim: Actor = act.find_nearest_actor_in_dir(actor.coord, Vector2.RIGHT)
	if victim == null: actor.end_action()
	
	strife.damage_actor_at_coord(actor, victim.coord, actor.base_damage, false)
	
	actor.end_action()
	pass

func ACT_basic_melee():
	var exact_coord: Vector2 = actor.coord + Vector2.RIGHT
	
	strife.damage_actor_at_coord(actor, exact_coord, actor.base_damage, true)
	
	actor.end_action()
	pass
