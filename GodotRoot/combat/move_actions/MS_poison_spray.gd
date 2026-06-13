extends MoveAction


func PREVIEW():
	
	var near_rel: Vector2
	var check_array: Array = [] # Should be 4 coords each set
	match variant:
		1:
			check_array.append(Vector2(actor.my_facing.x,    0))
			check_array.append(Vector2(actor.my_facing.x*2,  0))
			check_array.append(Vector2(actor.my_facing.x*2,  1))
			check_array.append(Vector2(actor.my_facing.x*2, -1))
			near_rel = Vector2(actor.my_facing.x,    0)
		2:
			check_array.append(Vector2(actor.my_facing.x,   -1))
			check_array.append(Vector2(actor.my_facing.x,   -2))
			check_array.append(Vector2(actor.my_facing.x*2, -1))
			check_array.append(Vector2(actor.my_facing.x*2, -2))
			near_rel = Vector2(actor.my_facing.x,   -1)
		3:
			check_array.append(Vector2(actor.my_facing.x,    1))
			check_array.append(Vector2(actor.my_facing.x,    2))
			check_array.append(Vector2(actor.my_facing.x*2,  1))
			check_array.append(Vector2(actor.my_facing.x*2,  2))
			near_rel = Vector2(actor.my_facing.x,    1)
	
	var use_arrows: bool = false
	
	for relvec in check_array:
		
		var target: Vector2 = actor.coord + relvec
		if !batman.grid_actors.has_cellv(target):
			continue
		
		if relvec == near_rel:
			use_arrows = true
			add_arrow(actor.coord, target, ROWS.PASS)
		else:
			if use_arrows:
				var origin_coord: Vector2 = actor.coord + near_rel
				add_arrow(origin_coord, target, ROWS.BAD)
		add_cell(target, ROWS.BAD)
	
	pass

func ACT():
	for target in get_all_cells_by_MPD_type(ROWS.BAD, true):
		print("poison at target ",target)
		strife.damage_actor_at_coord(actor, target, 1*batman.BASE_HP_FACTOR, ["piercing", "elem_POISON"])
	
	end_action()
	pass
