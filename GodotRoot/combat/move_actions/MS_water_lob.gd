extends MoveAction

var DIST: int = 3

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
	
	end_action()
	pass
