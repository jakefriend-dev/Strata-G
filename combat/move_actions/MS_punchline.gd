extends MoveAction

#var DIST: int = 3

# Only uncomment this method if you want to bypass "normal" variant loading
func LOAD_VARIANTS():
	for enemy in batman.get_all_opposing_actor_units(actor):
		actualized_variants.append(enemy.coord)
	pass


func PREVIEW():
	
	if actualized_variants.empty():
		error_text = "No possible targets"
		return
	
	var victim_cell: Vector2 = batman.loaded_variant
	var victim: Actor = batman.grid_actors.get_cellv(victim_cell)
	
	if !utils.actorpass(victim):
		# Shouldn't be possible? We JUST validated in LOAD_VARIANTS()
		error_text = "Target is invalid"
		return
	
	add_actor(victim, ROWS.BAD)
	passfail = true
	pass

func ACT():
	var victim: Actor = get_first_actor_by_MPD_type(ROWS.BAD)
	
	if utils.actorpass(victim):
		strife.quick_vfx(victim, "quick_bad")
		victim.spend(2)
	
	var allies: Array = batman.get_all_allied_actor_units(actor)
	for ally in allies:
		strife.quick_vfx(ally, "quick_good")
		ally.add_action_points(1)
	
	end_action()
	pass

