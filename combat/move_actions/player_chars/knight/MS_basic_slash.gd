extends MoveAction

func PREVIEW():
	
	var check_vector: Vector2 = batman.loaded_variant
#	var check_vector: Vector2 = actor.my_facing
#	if variant == 2: check_vector += Vector2.UP
#	if variant == 3: check_vector += Vector2.DOWN
	
	var exact_coord: Vector2 = actor.coord + check_vector
	if !batman.grid_actors.has_cellv(exact_coord):
		return
	
	add_cell(exact_coord, ROWS.BAD)
	
	var victim: Actor = batman.grid_actors.get_cellv(exact_coord)
	if !utils.actorpass(victim): return
	
	add_actor(victim, ROWS.BAD)
	passfail = true
	pass

func ACT():
	# Shoot a target in your line-of-sight; higher damage per tile travelled
	var victim: Actor = get_first_actor_by_MPD_type(ROWS.BAD)
	
	if utils.actorpass(victim):
		strife.damage_actor_at_coord(actor, victim.coord, actor.dmg(base_damage))
#		strife.quick_vfx(victim, "spark_burst")
		actor.log_hit()
	
	end_action()
	pass

