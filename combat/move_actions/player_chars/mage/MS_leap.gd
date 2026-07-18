extends MoveAction

var DIST: int = 2

# Only uncomment this method if you want to bypass "normal" variant loading
func LOAD_VARIANTS():
	for vec in plausible_variants:
		if support.is_tile_traversable_exact(actor, actor.coord + (vec * DIST)):
			actualized_variants.append(vec)
	pass


func PREVIEW():
	
	var check_vector: Vector2 = batman.loaded_variant
	var check_cell: Vector2 = actor.coord + (DIST * check_vector)
	
	if !support.is_tile_traversable_exact(actor, check_cell):
		error_text = "No clear landing option"
		return
	
	add_cell(check_cell, ROWS.NEUTRAL)
	passfail = true
	pass

func ACT():
	
	var target: Vector2 = get_first_cell_by_MPD_type(ROWS.NEUTRAL)
	
	actor.ghost_mode(true)
	actor.claim_tile(target)
	
	var dur: float = 0.375
	actor.hotjump(target, dur)
	
	yield(utils.yt(dur, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	actor.ghost_mode(false)
	end_action()
	pass

