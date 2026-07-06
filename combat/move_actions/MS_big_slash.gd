extends MoveAction

var slash_1_cells: Array = []
var slash_2_cells: Array = []

var slash_count: int = 0

func PREVIEW():
	slash_1_cells.clear()
	slash_2_cells.clear()
	slash_count = 0
	# Don't worry about validations for if cells exist until the ACT()
	
	if batman.loaded_variant == actor.my_facing:
		slash_1_cells.append(actor.coord + actor.my_facing)
		slash_1_cells.append(actor.coord + actor.my_facing + Vector2.UP)
		slash_1_cells.append(actor.coord + actor.my_facing + Vector2.DOWN)
		
		slash_2_cells.append(actor.coord + actor.my_facing)
		slash_2_cells.append(actor.coord + (actor.my_facing*2))
	
	elif batman.loaded_variant == (actor.my_facing + Vector2.UP):
		slash_1_cells.append(actor.coord + actor.my_facing + Vector2.UP)
		slash_1_cells.append(actor.coord + (Vector2.UP*2))
		slash_1_cells.append(actor.coord + (actor.my_facing*2))
		
		slash_2_cells.append(actor.coord + actor.my_facing + Vector2.UP)
		slash_2_cells.append(actor.coord + (actor.my_facing*2) + (Vector2.UP*2))
	
	elif batman.loaded_variant == (actor.my_facing + Vector2.DOWN):
		slash_1_cells.append(actor.coord + actor.my_facing + Vector2.DOWN)
		slash_1_cells.append(actor.coord + (Vector2.DOWN*2))
		slash_1_cells.append(actor.coord + (actor.my_facing*2))
		
		slash_2_cells.append(actor.coord + actor.my_facing + Vector2.DOWN)
		slash_2_cells.append(actor.coord + (actor.my_facing*2) + (Vector2.DOWN*2))
	
	add_cellset(slash_1_cells, ROWS.BAD)
	add_cellset(slash_2_cells, ROWS.BAD)
	
	pass

func ACT():
	slash_count += 1
	if   slash_count == 1: slash_1()
	elif slash_count == 2: slash_2()
	else: end_action()
	pass
	

func slash_1():
	# Prepare our slash *immediately* so that if an interruption happens based on dealing damage, we're already cued to do it
	batman.append_action(actor, resource_name)
	
	for cell in slash_1_cells:
		if !batman.grid_actors.has_cellv(cell): continue
		strife.damage_actor_at_coord(actor, cell, 2*batman.BASE_HP_FACTOR)
		strife.quick_vfx(cell, "spark_burst")
	
	end_action()
	pass

func slash_2():
	yield(utils.yt(0.375, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	for cell in slash_2_cells:
		if !batman.grid_actors.has_cellv(cell): continue
		strife.damage_actor_at_coord(actor, cell, 2*batman.BASE_HP_FACTOR)
		strife.quick_vfx(cell, "spark_burst")
	
	end_action()
	pass

