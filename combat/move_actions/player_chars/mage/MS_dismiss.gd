extends MoveAction



func PREVIEW():
	var unoccupieds: Array = support.list_all_unoccupied_tiles_in_dir(actor.coord, actor.my_facing)
	if !unoccupieds.empty():
		add_arrow(actor.coord, unoccupieds.back(), ROWS.PASS)
	
	var victim: Actor = support.find_nearest_actor_in_dir(actor.coord, actor.my_facing)
	if !utils.actorpass(victim):
		error_text = "No target in line of sight"
		return
	
	# An actor exists!
	
	if strife.is_unmovable(victim):
		add_actor(victim, ROWS.ERROR)
		error_text = "Target is unmovable"
		return
	
	var check_vector: Vector2 = batman.loaded_variant
	var check_coord: Vector2 = victim.coord + check_vector
	
	if !support.is_tile_traversable_exact(victim, check_coord):
		add_actor(victim, ROWS.ERROR)
		add_arrow(victim.coord, check_coord, ROWS.ERROR)
#		print("Yank preview fail; victim can't traverse destination tile")
		error_text = "Target can't be moved there"
		return
	
	# Success case!
	add_actor(victim, ROWS.NEUTRAL)
	add_arrow(victim.coord, check_coord, ROWS.NEUTRAL)
#	print("successsss")
	passfail = true
	pass

func ACT():
	# We KNOW there' a victim, because if there wasn't, we couldn't have passed the preview check
	var victim: Actor = get_first_actor_by_MPD_type(ROWS.NEUTRAL)
	actor.log_hit()
	
	# Data setup!
	var motion: Vector2 = batman.loaded_variant
	
	var dest_coord: Vector2 = victim.coord + motion
#	print("dest_coord A: ",dest_coord)
#	if !support.is_tile_traversable_exact(victim, dest_coord):
#		dest_coord = victim.coord
#		print("dest_coord B: ",dest_coord)
	
	# Visuals!
	strife.quick_vfx(victim, "spark_burst")
	
	yield(utils.yt(0.25, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	strife.quick_vfx(victim, "dust")
#	print("dest_coord C: ",dest_coord," and victim.coord: ",victim.coord," and motion: ",motion)
	if dest_coord != victim.coord:
		victim.hotslide(dest_coord, 0.25)
#		victim.ACT_be_external_motioned(motion, 0, actor, false)
	
	yield(utils.yt(0.375, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	end_action()
	pass
