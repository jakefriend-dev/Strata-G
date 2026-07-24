extends MoveAction

var seq: int = 1
var return_tile: Vector2

func PREVIEW():
	seq = 1
	if !support.is_tile_available(actor.coord + actor.my_facing):
		error_text = "Can't charge if in front of target already"
		return
	
	passfail = true
	pass

func ACT():
	match seq:
		1:
			seq += 1
			ACT_charge_forward()
			return
		2:
			seq += 1
			ACT_bite()
			return
		3:
			seq += 1
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
	if support.is_actor_on_own_frontline(actor):
		return_tile = actor.coord
		# We've already validated charge room, so this should be 100% clear; let's claim the tile in FRONT of us so we seem to move closer!
	else:
		return_tile = (actor.coord + actor.my_facing)
	var dest_coord: Vector2 = chargies.back()
	
	# Perform a visual movement to the destination cell!
	var dur: float = float(xdist)*0.1
	actor.hotcharge(dest_coord, dur)
	
	yield(utils.yt(dur, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	batman.append_action(actor, self)
	end_action()
	pass

func ACT_bite():
	strife.damage_actor_at_coord(actor, actor.coord + actor.my_facing, actor.dmg(base_damage))
	
	var dur: float = 0.125
	
	yield(utils.yt(dur, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	strife.emit_signal("actor_rest_event", actor) # Always remember this could in theory kill us
	if !utils.actorpass(actor): return
	if !batman.is_my_action(actor): return
	
	if actor.coord != return_tile:
		# Don't uncharge if we're already at our endpoint
		batman.append_action(actor, self)
	
	end_action()
	pass

func ACT_charge_back():
	# Safety check; we should not start from our claimed tile
	if actor.coord == return_tile:
		batman.skip_action()
		return
	
	var valid_xdist: float = abs(return_tile.x - actor.coord.x)
	
	# Perform a visual movement to the destination cell!
	var dur: float = valid_xdist*0.25
	actor.hotslide(return_tile, dur)
	
	yield(utils.yt(dur, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	actor.allowed_over_faction_lines = false
	
	end_action()
	pass





