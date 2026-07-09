extends MoveAction

var seq: int = 0
var backmost_cell: Vector2
var frontmost_cell: Vector2
var og_cell: Vector2
var dist_1: float # OG to backmost
var dist_2: float # backmost to frontmost
var dist_3: float # frontmost to OG

# ---

func LOAD_VARIANTS():
	for vec in plausible_variants: # Force add the forward-facing variant, no matter what
		actualized_variants.append(vec)
	pass

func PREVIEW():
	seq = 0
	dist_1 = 0
	dist_2 = 0
	dist_3 = 0
	
	# First get the tile farthest BEHIND us
	
	var unoccupied_behind: Array = support.list_all_unoccupied_tiles_in_dir(
		actor.coord, actor.their_facing)
	var movable_behind: Array = []
	
	for cell in unoccupied_behind:
		if !support.is_tile_traversable_exact(actor, cell):
			break
		movable_behind.append(cell)
	backmost_cell = actor.coord # Fallback
	if !movable_behind.empty():
		backmost_cell = movable_behind.back()
	
	# Then get the tile farthest AHEAD of us
	
	var unoccupied_ahead: Array = support.list_all_unoccupied_tiles_in_dir(
		actor.coord, actor.my_facing)
	var movable_ahead: Array = []
	
	actor.allowed_over_faction_lines = true
	for cell in unoccupied_ahead:
		if !support.is_tile_traversable_exact(actor, cell):
			break
		movable_ahead.append(cell)
	actor.allowed_over_faction_lines = false
	frontmost_cell = actor.coord # Fallback
	if !movable_ahead.empty():
		frontmost_cell = movable_ahead.back()
	
	if frontmost_cell == backmost_cell:
		# We aren't able to charge, at all - no action to undertake!
		add_cell(actor.coord, ROWS.ERROR)
		return
	
	##################
	
	# Otherwise, we're able to charge at LEAST one tile! Gather basic data now:
	passfail = true
	dist_2 = frontmost_cell.x - backmost_cell.x
	og_cell = actor.coord
	
	if backmost_cell != actor.coord:
#		add_arrow(actor.coord, backmost_cell, ROWS.NEUTRAL)
		dist_1 = actor.coord.x - backmost_cell.x
	if frontmost_cell != actor.coord:
		dist_3 = frontmost_cell.x - actor.coord.x
	add_arrow(backmost_cell, frontmost_cell, ROWS.NEUTRAL)
	
	# Do we have a target?
	var victim_cell: Vector2 = frontmost_cell + actor.my_facing
	var victim: Actor = support.get_actor_at_cellv(victim_cell)
	if victim == null:
		# A bit odd, but *technically* we could use this without an actual victim...
		return
	
	# Let's try and figure out if we're knocking someone back
	var charge_dist: int = frontmost_cell.x - backmost_cell.x
	
	if !strife.is_affected_by_force(victim): # Pure damage!
		add_actor(victim, ROWS.BAD)
		return
	
	var postvictim_unoccupieds: Array = support.list_all_unoccupied_tiles_in_dir(
		victim_cell, actor.my_facing)
	var vic_traversibles: Array = []
	for pvuc in postvictim_unoccupieds:
		if !support.is_tile_traversable_exact(victim, pvuc):
			break
		vic_traversibles.append(pvuc)
	
	if vic_traversibles.size() > charge_dist: # Can't charge further than player has!
		vic_traversibles.resize(charge_dist)
	
	if vic_traversibles.empty():
		add_actor(victim, ROWS.BAD)
		return
	
	# Now we know the victim is going to move backwards, so let's give them an arrow, too.
	add_arrow(victim.coord, vic_traversibles.back(), ROWS.NEUTRAL)
	
	# If the vic's going to be taking impact damage on arrival, imply that!
	if vic_traversibles.size() < charge_dist:
		add_cell(vic_traversibles.back(), ROWS.BAD)
	
	pass

func ACT():
	seq += 1
	
	if seq == 1 and actor.coord == backmost_cell: # Skip the stepback
		seq = 2
	if seq == 3 and actor.coord == og_cell: # Skip the return
		seq = -1
	
	match seq:
		
		1: # Move backwards
			var dur1: float = actor.tile_walk_speed * dist_1
			var dur2: float = dur1 + actor.tile_walk_speed
			actor.hotmove(backmost_cell, dur1)
			
			yield(utils.yt(dur2, actor), "timeout") # Waits extra long before the charge
			if !batman.is_my_action(actor): return
			
			if frontmost_cell != actor.coord:
				batman.append_action(actor, resource_name)
			pass
		
		2: # Charge forwards (end by delivering impact)
			var dur: float = 0.05 * dist_2
			actor.allowed_over_faction_lines = true
			actor.hotmove(frontmost_cell, dur)
			
			yield(utils.yt(dur, actor), "timeout")
			if !batman.is_my_action(actor): return
			
			var victim: Actor = support.get_actor_at_cellv(actor.coord + actor.my_facing)
			if victim != null:
				if strife.is_affected_by_force(victim):
					strife.do_impact_motion(actor, victim, Vector2(dist_2, 0), ["travel_damage"])
				else:
					strife.do_impact_damage(actor, victim, actor.dmg(dist_2))
			
			if og_cell != actor.coord:
				batman.append_action(actor, resource_name)
			pass
		
		3: # Return to original position
			yield(utils.yt(actor.tile_walk_speed, actor), "timeout")
			if !batman.is_my_action(actor): return
			
			var dur: float = actor.tile_walk_speed * dist_3
			actor.allowed_over_faction_lines = true
			actor.hotmove(og_cell, dur)
			
			yield(utils.yt(dur, actor), "timeout")
			if !batman.is_my_action(actor): return
			
			actor.allowed_over_faction_lines = false
			pass
	
	end_action()
	pass

