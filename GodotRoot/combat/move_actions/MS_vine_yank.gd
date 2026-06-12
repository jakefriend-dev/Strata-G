extends MoveAction

func PREVIEW(): # Options are 0, 1, 2
	var unoccupieds: Array = support.list_all_unoccupied_tiles_in_dir(actor.coord, actor.my_facing)
	if !unoccupieds.empty():
		APD.add_arrow(actor.coord, unoccupieds.back(), acols.PASS)
	
	var victim: Actor = support.find_nearest_actor_in_dir(actor.coord, actor.my_facing)
	if !utils.actorpass(victim):
#		print("Yank preview fail; no victim")
		return
	
	APD.add_actor(victim, acols.NEUTRAL)
	
	var check_vector: Vector2 = actor.their_facing
	if option == 1: check_vector += Vector2.UP
	if option == 2: check_vector += Vector2.DOWN
	var check_coord: Vector2 = victim.coord + check_vector
	
	if !support.is_tile_traversable_exact(victim, check_coord):
		APD.add_arrow(victim.coord, check_coord, acols.ERROR)
#		print("Yank preview fail; victim can't traverse destination tile")
		return
	
	if !strife.is_affected_by_force(victim):
		APD.add_arrow(victim.coord, check_coord, acols.ERROR)
#		print("Yank preview fail; victim is not affected by force")
		return
	
	# Success case!
	APD.add_arrow(victim.coord, check_coord, acols.NEUTRAL)
#	print("successsss")
	APD.passfail = true
	pass

func ACT():
	# We KNOW there' a victim, because if there wasn't, we couldn't have passed the preview check
	var victim: Actor = APD.get_actor_by_type(acols.NEUTRAL)
	
	# Data setup!
	var motion: Vector2 = actor.their_facing
	if option == 1: motion += Vector2.UP
	if option == 2: motion += Vector2.DOWN
	
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
