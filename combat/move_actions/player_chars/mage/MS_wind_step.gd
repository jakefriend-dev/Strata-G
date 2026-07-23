extends MoveAction

var dest: Vector2 = Vector2.ZERO

func PREVIEW():
	var target: Vector2 = actor.coord + batman.loaded_variant
	
	if !batman.grid_actors.has_cellv(target):
		error_text = "Dest position off-battlefield"
		return
	
	if !support.is_tile_traversable_exact(actor, target):
		add_arrow(actor.coord, target, ROWS.ERROR)
		add_cell(target, ROWS.ERROR)
		error_text = "Can't move into that tile"
		return
	
	add_arrow(actor.coord, target, ROWS.NEUTRAL)
	add_cell(target, ROWS.NEUTRAL)
	dest = target
	passfail = true
	pass

func ACT():
	var dur: float = actor.tile_walk_speed
#	var target: Vector2 = get_first_cell_by_MPD_type(ROWS.NEUTRAL)
#	print("target: ",target)
	
	actor.hotslide(dest, dur)
	
	yield(utils.yt(dur, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	end_action()
	pass
