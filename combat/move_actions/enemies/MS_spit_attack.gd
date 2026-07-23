extends MoveAction



func PREVIEW():
	var picked_tiles: Array = []
	
	# First, always choose at least 1 tile a player is on
	var victims: Array = batman.get_all_opposing_actor_units(actor)
	if victims.empty():
		end_telegraph()
		return
	
	victims.shuffle()
	picked_tiles.append(victims[0].coord)
	
	var other_tiles: Array = support.get_all_tiles_of_THEIR_faction(actor)
	other_tiles.erase(picked_tiles[0]) # No repeats!
	other_tiles.shuffle()
	
	picked_tiles.append(other_tiles.pop_front()) # Always a 2nd bullet
	picked_tiles.append(other_tiles.pop_front()) # Always a 3rd bullet
	if rand_range(0.0, 1.0) <= 0.25:
		picked_tiles.append(other_tiles.pop_front()) # Small chance of a 4th bullet
	
	for tile in picked_tiles:
		add_cell(tile, ROWS.BAD)
		add_arrow(actor.coord, tile, ROWS.BAD)
	
	passfail = true
	end_telegraph()
	pass

func RE_PREVIEW():
	# This must be run on any 'change' event (health, impact, reposition, etc) once the telegraph is in place. If it returns FALSE, the telegraph breaks, and (if it was required, which they usually are), the main move cannot be used.
	
	# passfail must be flipped back to false before re-previewing!
	
	# ...if there is no "RE_TELEGRAPH" can we simply instead 1. clear all data and 2. run TELEGRAPH again? Let's find out with Lunge Stomp!
	
	clear_all_arrows_by_type(ROWS.BAD)
	for tile in get_all_cells_by_MPD_type(ROWS.BAD):
		add_arrow(actor.coord, tile, ROWS.BAD)
	
	passfail = true
	pass

func ACT():
	for target in get_all_cells_by_MPD_type(ROWS.BAD):
		strife.damage_actor_at_coord(actor, target, actor.dmg(1))
		if utils.actorpass(batman.grid_actors.get_cellv(target)):
			actor.log_hit()
	
	print(actor.name,"'s SPIT ATTACK fires at: ",actor.get_tree().get_frame())
	yield(utils.yt(0.75, actor), "timeout")
	if !batman.is_my_action(actor): return
	print(actor.name,"'s SPIT ATTACK after 0.75sec delay: ",actor.get_tree().get_frame())
	
	actor.clear_telegraphed_move()
	end_action()
	pass

