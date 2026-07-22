extends MoveAction

func PREVIEW():
	
	var check_vector: Vector2 = batman.loaded_variant
	
	var sighted: Array = support.get_all_tiles_in_dir(actor.coord, check_vector)
	if !sighted.empty():
		add_arrow(actor.coord + check_vector, sighted.back(), ROWS.BAD)
	
	for coord in sighted:
		var victim: Actor = batman.grid_actors.get_cellv(coord)
		if !utils.actorpass(victim): continue
		add_actor(victim, ROWS.BAD)
	
	pass

func ACT():
	# Shoot a target in your line-of-sight; higher damage per tile travelled
	var victims: Array = get_all_actors_by_MPD_type(ROWS.BAD)
	for victim in victims:
		if utils.actorpass(victim):
			actor.log_hit()
			strife.damage_actor_at_coord(actor, victim.coord, actor.dmg(base_damage), ["piercing", "fire_elem"])
			strife.quick_vfx(victim, "spark_burst")
	
	end_action()
	pass

