extends MoveAction

#var DIST: int = 3

# Only uncomment this method if you want to bypass "normal" variant loading
func LOAD_VARIANTS():
	for vec in plausible_variants:
		if vec == Vector2.ZERO: continue
		
		var cellnear: Vector2 = actor.coord + vec
		if !batman.grid_actors.has_cellv(cellnear): continue
		var victim: Actor = batman.grid_actors.get_cellv(cellnear)
		if !utils.actorpass(victim): continue
		var cellfar: Vector2 = cellnear + vec
		if !batman.grid_actors.has_cellv(cellfar): continue
		
		# Removed these checks; we should instead allow previewing the error
#		var far_occupant: Actor
#		if utils.actorpass(far_occupant): continue
		
		# Now we're sure that there is room for an actor to move, and a nearby actor to affect
		if support.is_tile_traversable_exact(victim, cellfar):
			actualized_variants.append(vec)
		
#		if batman.grid_actors.has_cellv(actor.coord + vec + Vector2(DIST, 0)):
	pass


func PREVIEW():
	if batman.loaded_variant == Vector2.ZERO:
		return
	
	var check_vector: Vector2 = batman.loaded_variant
	var near_coord: Vector2 = actor.coord + check_vector
	var far_coord: Vector2 = near_coord + check_vector
	
	var victim: Actor = batman.grid_actors.get_cellv(near_coord)
#	if !utils.actorpass(victim):
	
	if !strife.is_affected_by_force(victim):
		add_cell(near_coord, ROWS.ERROR)
		add_cell(far_coord, ROWS.ERROR)
		add_arrow(near_coord, far_coord, ROWS.ERROR)
		return
	
	add_cell(near_coord, ROWS.NEUTRAL)
	
	var far_occupant: Actor = batman.grid_actors.get_cellv(far_coord)
	if utils.actorpass(far_occupant):
		add_cell(far_coord, ROWS.ERROR)
		add_arrow(near_coord, far_coord, ROWS.ERROR)
		return
	
	add_cell(far_coord, ROWS.NEUTRAL)
	add_arrow(near_coord, far_coord, ROWS.NEUTRAL)
	passfail = true
	pass

func ACT():
	var check_vector: Vector2 = batman.loaded_variant
	var near_coord: Vector2 = actor.coord + check_vector
#	var far_coord: Vector2 = near_coord + check_vector
	var victim: Actor = batman.grid_actors.get_cellv(near_coord)
	
	strife.do_impact_motion(actor, victim, check_vector)
	
#	var dur: float = 0.25
#	yield(utils.yt(dur, actor), "timeout")
#	if !batman.is_my_action(actor): return
	
	end_action()
	pass

