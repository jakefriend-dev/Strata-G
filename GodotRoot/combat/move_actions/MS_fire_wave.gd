extends MoveAction

func PREVIEW():
	
	var check_vector: Vector2 = actor.my_facing
	if variant == 2: check_vector += Vector2.UP
	if variant == 3: check_vector += Vector2.DOWN
	
	var sighted: Array = support.get_all_tiles_in_dir(actor.coord, check_vector)
	if !sighted.empty():
		add_arrow(actor.coord, sighted.back(), ROWS.BAD)
	
#	var victims: Array = []
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
			strife.damage_actor_at_coord(actor, victim.coord, 1*batman.BASE_HP_FACTOR, ["piercing", "elem_FIRE"])
			strife.quick_effect(victim, "spark_burst")
	
	end_action()
	pass

