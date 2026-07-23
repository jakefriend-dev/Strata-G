extends MoveAction

var seq: int = 1

func PREVIEW():
	seq = 1
#
#	var check_vector: Vector2 = batman.loaded_variant
#
#	var unoccupieds: Array = support.list_all_unoccupied_tiles_in_dir(actor.coord, check_vector)
#	if !unoccupieds.empty():
#		add_arrow(actor.coord, unoccupieds.back(), ROWS.PASS)
#
#	var victim: Actor = support.find_nearest_actor_in_dir(actor.coord, check_vector)
#	if !utils.actorpass(victim): return
#
#	add_actor(victim, ROWS.BAD)
#	passfail = true
	pass

func ACT():
	match seq:
		1:
			ACT_charge_forward()
			return
		2:
			ACT_charge_back()
			return
	end_action()
	pass

func ACT_charge_forward():
	actor.allowed_over_faction_lines = true
	var chargies: Array = support.list_all_traversible_tiles_in_dir(actor.my_facing, actor)
#	print("chargies: ",chargies)
	var xdist: int = chargies.size()
	
	if xdist == 0: # Just in case
		batman.skip_action()
		return
	
	# We're clear! Mark the endpoint and claim our og coord before moving
	actor.claim_tile()
	var dest_coord: Vector2 = chargies.back()
	
	# Perform a visual movement to the destination cell!
	var dur: float = float(xdist)*0.1
	actor.hotcharge(dest_coord, dur)
	
	yield(utils.yt(dur, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	end_action()
	pass

func ACT_charge_back():
	# Safety check; we should not start from our claimed tile
	if actor.coord == actor.claimed_tile:
		batman.skip_action()
		return
	
	var valid_xdist: float = abs(actor.claimed_tile.x - actor.coord.x)
	
	# Perform a visual movement to the destination cell!
	var dur: float = valid_xdist*0.1
	actor.hotslide(actor.claimed_tile, dur)
	
	yield(utils.yt(dur, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	actor.allowed_over_faction_lines = false
	
	end_action()
	pass





