extends MoveAction



func PREVIEW():
	var tiletype: int = batman.grid_tiles.get_cellv(actor.coord)
	if tiletype == batman.tiletypes.SHRUB: # Won't re-cast on overgrowth!
		add_cell(actor.coord, ROWS.ERROR)
		error_text = "Already on Overgrowth tile"
		return
	elif tiletype == batman.tiletypes.MAGIC: # Can't be changed!
		add_cell(actor.coord, ROWS.ERROR)
		error_text = "Magic tiletype can't be changed"
		return
	
	add_actor(actor, ROWS.NEUTRAL)
	passfail = true
	pass

func ACT():
	support.change_tiletype_single(actor.coord, batman.tiletypes.SHRUB)
	
	end_action()
	pass

