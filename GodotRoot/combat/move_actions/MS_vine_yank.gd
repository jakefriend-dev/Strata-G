extends MoveAction

var DIST: int = 3

func LOAD_VARIANTS():
	# Because we're checking BEHIND us, check one tile to the front - we only really care about if a row exists above or below us, not any particular cell position.
	for vec in plausible_variants:
		if batman.grid_actors.has_cellv(actor.coord + vec + actor.my_facing):
			actualized_variants.append(vec)
	pass

func PREVIEW(): # Options are 0, 1, 2
	var unoccupieds: Array = support.list_all_unoccupied_tiles_in_dir(actor.coord, actor.my_facing, DIST)
	if !unoccupieds.empty():
		add_arrow(actor.coord, unoccupieds.back(), ROWS.PASS)
	
	var victim: Actor = support.find_nearest_actor_in_dir(actor.coord, actor.my_facing, DIST)
	if !utils.actorpass(victim):
#		print("Yank preview fail; no victim")
		return
	
	# If victim is within 3 tiles...
	
	add_actor(victim, ROWS.NEUTRAL)
	
	var check_vector: Vector2 = batman.loaded_m_varvec
#	var check_vector: Vector2 = actor.their_facing
#	if variant == 2: check_vector += Vector2.UP
#	if variant == 3: check_vector += Vector2.DOWN
	var check_coord: Vector2 = victim.coord + check_vector
	
	if !support.is_tile_traversable_exact(victim, check_coord):
		add_arrow(victim.coord, check_coord, ROWS.ERROR)
#		print("Yank preview fail; victim can't traverse destination tile")
		return
	
	if !strife.is_affected_by_force(victim):
		add_arrow(victim.coord, check_coord, ROWS.ERROR)
#		print("Yank preview fail; victim is not affected by force")
		return
	
	# Success case!
	add_arrow(victim.coord, check_coord, ROWS.NEUTRAL)
#	print("successsss")
	passfail = true
	pass

func ACT():
	# We KNOW there' a victim, because if there wasn't, we couldn't have passed the preview check
	var victim: Actor = get_first_actor_by_MPD_type(ROWS.NEUTRAL)
	
	# Data setup!
	var motion: Vector2 = actor.their_facing
	if variant == 2: motion += Vector2.UP
	if variant == 3: motion += Vector2.DOWN
	
	var dest_coord: Vector2 = victim.coord + motion
	if !support.is_tile_traversable_exact(victim, dest_coord):
		dest_coord = victim.coord
	
	# Visuals!
	strife.quick_effect(victim, "spark_burst")
	
	yield(utils.yt(0.25, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	strife.quick_effect(victim, "dust")
	if dest_coord != victim.coord:
		victim.ACT_be_external_motioned(motion, 0, actor, false)
	
	yield(utils.yt(0.375, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	end_action()
	pass
