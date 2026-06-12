extends MoveAction

func PREVIEW():
	var check_cells: Array = []
	
	# Center tile
	var check_vector: Vector2 = actor.my_facing
	check_cells.append(actor.coord + check_vector)
	
	# Upper tile
	check_vector += Vector2.UP
	if variant == 1: check_cells.append(actor.coord + check_vector)
	if variant == 2: check_cells.append(actor.coord + check_vector + actor.my_facing)
	if variant == 3: check_cells.append(actor.coord + check_vector + actor.their_facing)
	
	# Lower tile
	check_vector += Vector2.DOWN
	check_vector += Vector2.DOWN
	if variant == 1: check_cells.append(actor.coord + check_vector)
	if variant == 2: check_cells.append(actor.coord + check_vector + actor.their_facing)
	if variant == 3: check_cells.append(actor.coord + check_vector + actor.my_facing)
	
	for target in check_cells:
		add_cell(target, ROWS.BAD)
		
		var victim: Actor = batman.grid_actors.get_cellv(target)
		if !utils.actorpass(victim): continue
		add_actor(victim, ROWS.BAD)
	pass

func ACT():
	for target in get_all_cells_by_MPD_type(ROWS.BAD):
		strife.damage_actor_at_coord(actor, target, 3*batman.BASE_HP_FACTOR)
		strife.quick_effect(target, "spark_burst")
	
	end_action()
	pass

