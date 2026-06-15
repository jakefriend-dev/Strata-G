extends MoveAction

var DIST: int = 3

func LOAD_VARIANTS():
	for vec in plausible_variants:
		if batman.grid_actors.has_cellv(actor.coord + vec + Vector2(DIST, 0)):
			actualized_variants.append(vec)
	pass

func PREVIEW():
	var target: Vector2 = actor.coord + (actor.my_facing*DIST)
#	target = target.round()
	if !batman.grid_actors.has_cellv(target):
		return
	add_cell(target, ROWS.BAD)
	passfail = true
	pass

func ACT():
	var target: Vector2 = get_first_cell_by_MPD_type(ROWS.BAD)
	strife.damage_actor_at_coord(actor, target, 1*batman.BASE_HP_FACTOR, ["elem_WATER"])
	support.change_tiletype_single(target, batman.tiletypes.ICE)
	
	end_action()
	pass
