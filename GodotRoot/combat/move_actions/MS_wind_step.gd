extends MoveAction

var dest: Vector2 = Vector2.ZERO

func PREVIEW():
#	var all_rels: Array = [
#		Vector2( 1,  1),
#		Vector2(-1,  1),
#		Vector2(-1, -1),
#		Vector2( 1, -1)
#	]
	
#	var rel = all_rels[variant-1]
#	var target: Vector2 = actor.coord + rel
	var target: Vector2 = actor.coord + batman.loaded_variant
#	print("target: ",target)
	
	if !batman.grid_actors.has_cellv(target):
		return
	
	if !support.is_tile_traversable_exact(actor, target):
		add_arrow(actor.coord, target, ROWS.ERROR)
		add_cell(target, ROWS.ERROR)
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
	
	actor.hotmove(dest, dur)
	
	yield(utils.yt(dur, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	end_action()
	pass
