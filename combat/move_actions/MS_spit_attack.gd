extends MoveAction

#var DIST: int = 3

# Only uncomment this method if you want to bypass "normal" variant loading
#func LOAD_VARIANTS():
#	for vec in plausible_variants:
#		if batman.grid_actors.has_cellv(actor.coord + vec + Vector2(DIST, 0)):
#			actualized_variants.append(vec)
#	pass

func PREVIEW():
	pass

func TELEGRAPH():
	var picked_tiles: Array = []
	
	# First, always choose at least 1 tile a player is on
	var victims: Array = batman.get_all_opposing_actor_units(actor)
	if victims.empty():
		end_action()
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
	
	telegraph_pass = true
	pass

func RE_TELEGRAPH() -> bool:
	# This must be run on any 'change' event (health, impact, reposition, etc) once the telegraph is in place. If it returns FALSE, the telegraph breaks, and (if it was required, which they usually are), the main move cannot be used.
	
	clear_all_arrows_by_type(ROWS.BAD)
	for tile in get_all_cells_by_MPD_type(ROWS.BAD):
		add_arrow(actor.coord, tile, ROWS.BAD)
	
	return true
	pass

func ACT():
	for target in get_all_cells_by_MPD_type(ROWS.BAD):
		strife.damage_actor_at_coord(actor, target, actor.dmg(1))
	
	end_action()
	pass

