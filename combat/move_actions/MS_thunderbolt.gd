extends MoveAction

func PREVIEW():
	
	var check_vector: Vector2 = batman.loaded_variant
#	var check_vector: Vector2 = actor.my_facing
#	if variant == 2: check_vector += Vector2.UP
#	if variant == 3: check_vector += Vector2.DOWN
	
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
	var dmg: int = 0
	var dist: int = 0
	
	var coord_path: Array = []
	if utils.actorpass(victim):
		
		var check_vector: Vector2 = actor.my_facing
		if variant == 2: check_vector += Vector2.UP
		if variant == 3: check_vector += Vector2.DOWN
		var check_cell: Vector2 = actor.coord
		while check_cell != victim.coord:
			check_cell += check_vector
			if !batman.grid_actors.has_cellv(check_cell):
				dist = 0
				break
			coord_path.append(check_cell)
			dist += 1
		pass
	
	# Distance is based off damage; adjacent to us is 0 damage and +1 per gap of space
	if dist > 0: dmg = (dist - 1)
	if dmg < 0: dmg = 0
#	print("longshot dist ",dist," so base dmg ",dmg)
	dmg *= batman.BASE_HP_FACTOR
	
	for cell in coord_path:
		strife.quick_vfx(cell, "spark_burst")
	if utils.actorpass(victim):
		strife.damage_actor_at_coord(actor, victim.coord, dmg, ["elec"])
		strife.quick_vfx(victim, "spark_burstdamage")
	
	end_action()
	pass

