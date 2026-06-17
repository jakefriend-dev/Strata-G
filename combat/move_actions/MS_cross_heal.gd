extends MoveAction

#var DIST: int = 3

#func PREPARE_TOGGLE_OPTIONS():
#
#	# Orthag then diag
#	toggle_cell_options.append(support.get_adj_orthagonal_tiles(actor.coord, true))
#	toggle_cell_options.append(support.get_adj_diagonal_tiles(actor.coord, true))
#	pass

# Only uncomment this method if you want to bypass "normal" variant loading
#func LOAD_VARIANTS():
#	for vec in plausible_variants:
#		if batman.grid_actors.has_cellv(actor.coord + vec + Vector2(DIST, 0)):
#			actualized_variants.append(vec)
#	pass

func PREVIEW():
	
	var check_vector: Vector2 = batman.loaded_variant
	
	var orthag_shapes: Array = [Vector2.UP, Vector2.DOWN, Vector2.RIGHT, Vector2.LEFT]
	var diag_shapes: Array = [Vector2( 1,  1),Vector2(-1,  1),Vector2(-1, -1),Vector2( 1, -1)]
	var model_plus: bool = (orthag_shapes.has(check_vector))
	
	if model_plus:
		add_cellset(orthag_shapes, ROWS.GOOD, false)
	else:
		add_cellset(diag_shapes, ROWS.GOOD, false)
	
	pass

func ACT():
	var targets: Array = get_all_cells_by_MPD_type(ROWS.GOOD)
	for target in targets:
		strife.heal_actor_at_coord(actor, target, 2*batman.BASE_HP_FACTOR)
		strife.quick_effect(target, "spark_burst")
	
	end_action()
	pass

