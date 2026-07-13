extends MoveAction

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
	
	if victim.check_status("calcified"):
		error_text = "Target is already calcified"
		return
	
	add_actor(victim, ROWS.BAD)
	passfail = true
	pass

func ACT():
	var victim: Actor = get_first_actor_by_MPD_type(ROWS.BAD)
	
	if utils.actorpass(victim):
		# Again, shouldn't be possible, but w/e
		strife.quick_vfx(victim, "quick_bad")
		victim.start_status("calcified", "Calcified", "Cannot move willingly during its turn.", "bad", 1)
	
	end_action()
	pass

