extends MoveAction

func PREVIEW():
	
	var check_vector: Vector2 = batman.loaded_variant
	
	var unoccupieds: Array = support.list_all_unoccupied_tiles_in_dir(actor.coord, check_vector)
	if !unoccupieds.empty():
		add_arrow(actor.coord, unoccupieds.back(), ROWS.PASS)
	
	var victim: Actor = support.find_nearest_actor_in_dir(actor.coord, check_vector)
	if !utils.actorpass(victim): return
	
	add_actor(victim, ROWS.BAD)
	passfail = true
	pass

func ACT():
	# Shoot a target in your line-of-sight; higher damage per tile travelled
	var victim: Actor = get_first_actor_by_MPD_type(ROWS.BAD)
	
	if utils.actorpass(victim):
		strife.damage_actor_at_coord(actor, victim.coord, 2*batman.BASE_HP_FACTOR, ["piercing"])
		strife.quick_vfx(victim, "spark_burst")
	
	end_action()
	pass

