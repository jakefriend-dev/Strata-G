extends MoveAction

var DIST: int = 2

func PREVIEW():
	
	var check_vector: Vector2 = batman.loaded_variant
	
	var unoccupieds: Array = support.list_all_unoccupied_tiles_in_dir(actor.coord, check_vector)
	if !unoccupieds.empty():
		add_arrow(actor.coord, unoccupieds.back(), ROWS.PASS)
	
	var center_victim: Actor = support.find_nearest_actor_in_dir(actor.coord, check_vector)
	if !utils.actorpass(center_victim):
		error_text = "No target in line of sight"
		return
	
	add_actor(center_victim, ROWS.BAD)
	passfail = true
	
	var center_coord: Vector2 = center_victim.coord
	
	for vec in utils.get_all_vectordirs():
		var victim2: Actor = support.find_nearest_actor_in_dir(center_coord, vec, DIST)
		if utils.actorpass(victim2):
			add_actor(victim2, ROWS.BAD)
			add_arrow(center_coord, victim2.coord, ROWS.BAD)
		else:
			var unoccupieds2: Array = support.list_all_unoccupied_tiles_in_dir(center_coord, vec, DIST)
			if !unoccupieds2.empty():
				add_arrow(center_coord, unoccupieds2.back(), ROWS.BAD)
	pass

func ACT():
	for victim in get_all_actors_by_MPD_type(ROWS.BAD):
		if utils.actorpass(victim):
			strife.damage_actor_at_coord(actor, victim.coord, actor.dmg(base_damage), ["elem_FIRE"])
			strife.quick_vfx(victim, "spark_burst")
	
	end_action()
	pass

