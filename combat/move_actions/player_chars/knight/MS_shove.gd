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
		
		# Now we're sure that there is a nearby actor to affect
		actualized_variants.append(vec)
		
#		if batman.grid_actors.has_cellv(actor.coord + vec + Vector2(DIST, 0)):
	pass

func PREVIEW():
	if batman.loaded_variant == Vector2.ZERO:
		error_text = "No shoveable units adjacent"
		return
	
	var check_vector: Vector2 = batman.loaded_variant
	var near_coord: Vector2 = actor.coord + check_vector
	var far_coord: Vector2 = near_coord + check_vector
	if !batman.grid_actors.has_cellv(near_coord) or !batman.grid_actors.has_cellv(far_coord):
		error_text = "Shoving tiles are out of bounds"
		return
	
	var victim: Actor = batman.grid_actors.get_cellv(near_coord)
	var far_occupant: Actor = batman.grid_actors.get_cellv(far_coord)
	var blocked: bool = utils.actorpass(far_occupant)
	
	if strife.is_unmovable(victim):
		add_cell(near_coord, ROWS.ERROR)
		add_arrow(near_coord, far_coord, ROWS.PASS)
		if blocked:
			add_cell(far_coord, ROWS.ERROR)
		else:
			add_cell(far_coord, ROWS.PASS)
		error_text = "Target is unmovable"
		return
	
	add_cell(near_coord, ROWS.NEUTRAL) # We're sure the victim is valid at this point
	
	if blocked:
		add_cell(far_coord, ROWS.ERROR)
		add_arrow(near_coord, far_coord, ROWS.PASS)
#		add_arrow(near_coord, far_coord, ROWS.ERROR)
		error_text = "Target has something behind it"
		return
	
	if !support.is_tile_traversable_exact(victim, far_coord):
		add_cell(far_coord, ROWS.PASS) # It's blocked, but NOT by an actor
		add_arrow(near_coord, far_coord, ROWS.PASS)
#		add_arrow(near_coord, far_coord, ROWS.ERROR)
		error_text = "Target can't move into tile behind it"
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
	actor.log_hit()
	
	strife.do_impact_motion(actor, victim, check_vector, ["unit_dur_0.25"])
	
#	var dur: float = 0.25
#	yield(utils.yt(dur, actor), "timeout")
#	if !batman.is_my_action(actor): return
	
	end_action()
	pass

