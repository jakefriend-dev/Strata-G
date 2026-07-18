extends MoveAction

#var DIST: int = 3

# Only uncomment this method if you want to bypass "normal" variant loading
#func LOAD_VARIANTS():
#	for vec in plausible_variants:
#		if batman.grid_actors.has_cellv(actor.coord + vec + Vector2(DIST, 0)):
#			actualized_variants.append(vec)
#	pass


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

