extends MoveAction

var DIST: int = 3
var target: Vector2

func LOAD_VARIANTS():
	for vec in plausible_variants:
		if batman.grid_actors.has_cellv(actor.coord + vec + Vector2(DIST, 0)):
			actualized_variants.append(vec)
	pass

func PREVIEW():
	target = actor.coord + (actor.my_facing*DIST) + batman.loaded_variant
	
	for relvec in actualized_variants:
		var cell: Vector2 = actor.coord + (actor.my_facing*DIST) + relvec
		if !batman.grid_actors.has_cellv(cell):
			error_text = "Move target not on battlefield"
			return
		if cell == target:
			add_cell(cell, ROWS.BAD)
#			print("water lob PREVIEW target: ",cell)
			passfail = true
		else:
			add_cell(cell, ROWS.ERROR)
	pass

func ACT():
#	target = get_first_cell_by_MPD_type(ROWS.BAD)
#	print("water lob ACT target: ",target)
	strife.damage_actor_at_coord(actor, target, actor.dmg(base_damage), ["cold"])
	support.change_tiletype_single(target, batman.tiletypes.ICE)
	
	end_action()
	pass
