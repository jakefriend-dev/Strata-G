extends MoveAction

func PREVIEW():
	
	var first_vec: Vector2 = actor.my_facing
	
	var unoccupieds_1: Array = support.list_all_unoccupied_tiles_in_dir(actor.coord, first_vec)
	if !unoccupieds_1.empty():
		add_arrow(actor.coord, unoccupieds_1.back(), ROWS.PASS)
	
	var victim_1: Actor = support.find_nearest_actor_in_dir(actor.coord, first_vec)
	if !utils.actorpass(victim_1): return
	
	add_actor(victim_1, ROWS.BAD)
	var first_target: Vector2 = victim_1.coord
	passfail = true
	
	var second_vec: Vector2 = batman.loaded_variant
	
	var unoccupieds_2: Array = support.list_all_unoccupied_tiles_in_dir(first_target, second_vec)
	if !unoccupieds_2.empty():
		add_arrow(first_target, unoccupieds_2.back(), ROWS.PASS)
	
	var victim_2: Actor = support.find_nearest_actor_in_dir(first_target, second_vec)
	if !utils.actorpass(victim_2): return
	
	add_actor(victim_2, ROWS.BAD)
	var _second_target: Vector2 = victim_2.coord
	
	pass

func ACT():
	# Shoot a target in your line-of-sight; higher damage per tile travelled
	for victim in get_all_actors_by_MPD_type(ROWS.BAD): if victim is Actor:
		if utils.actorpass(victim):
			strife.damage_actor_at_coord(actor, victim.coord, actor.dmg(base_damage), ["piercing"])
			strife.quick_vfx(victim, "spark_burst")
	
	end_action()
	pass

