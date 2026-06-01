extends Node

var tween: Tween
var trans: int = Tween.TRANS_QUINT

signal actor_collision_attempt(actor_attacking, actor_defending) # Can be used for things like missile collisions

var field: Node2D # Owner of all battle stuff
var actors: YSort
var board: GridContainer # Owner of CELLS not everything

# ---

func _ready():
	tween = Tween.new()
	add_child(tween)
	pass

# AVAILABILITY & TRAVERSABILITY --------------------------------------------------------------------

	# (ghosts are not considered in these checks)
	
	# OCCUPIED: The tile has an actor in it
	# AVAILABLE: The tile has *neither* an actor nor a claim
	# TRAVERSABLE: The tile is available AND a specific actor is capable of being there
		# (ie. it's not a "pit but I can't hover" situation, or a faction bounds issue)

func get_all_tiles_in_dir(og_cell: Vector2, dir: Vector2) -> Array:
	if dir == Vector2.ZERO: return []
	
	var coords_in_dir: Array = []
	var check_cell: Vector2 = og_cell
	
	while true:
		check_cell += dir
		if batman.grid_tiles.has_cellv(check_cell):
			coords_in_dir.append(check_cell)
		else:
			break
	
	return coords_in_dir
	pass

func list_all_traversible_tiles_in_dir(dir: Vector2, actor: Actor) -> Array:
	var og_cell: Vector2 = actor.coord
	var all_cells_in_dur: Array = get_all_tiles_in_dir(og_cell, dir)
	return list_all_traversible_tiles_in_set(all_cells_in_dur, actor)

# Returns successfully-claimed tiles IN ORDER, breaking on first issue
func list_all_traversible_tiles_in_set(exact_coords: Array, actor: Actor) -> Array:
	var claimed_cells: Array = []
	
	for exact_coord in exact_coords:
		if (batman.grid_claims.get_cellv(exact_coord) == null or batman.grid_claims.get_cellv(exact_coord) == self):
			if is_tile_traversable_exact(actor, exact_coord):
				batman.grid_claims.set_cellv(exact_coord, actor)
				claimed_cells.append(exact_coord)
	
	return claimed_cells
	pass

func is_tile_available(exact_coord: Vector2, exception_actor: Actor = null) -> bool:
	# When and ONLY when exception_actor is populated, we'll allow it to return itself.
	
	var found_actor: Actor = batman.grid_actors.get_cellv(exact_coord)
	if found_actor != null:
		if exception_actor == null:
			return false
		elif exception_actor != found_actor:
			return false
	
	var found_claimant: Actor = batman.grid_claims.get_cellv(exact_coord)
	if found_claimant != null:
		if exception_actor == null:
			return false
		elif exception_actor != found_claimant:
			return false
	
	return true

# PLAYER SHORTCUTS ---------------------------------------------------------------------------------

# MOVE (ORTHAGONAL/ADJACENT) -----------------------------------------------------------------------

func hotmove(actor: Actor, to_coord: Vector2, dur: float):
	tween.interpolate_property(actor, "position", null, batman.grid_gpos.get_cellv(to_coord), dur,Tween.TRANS_CIRC, Tween.EASE_IN_OUT)
	tween.start()
	pass

func hotjump(actor: Actor, to_coord: Vector2, dur: float, height: float = 100.0):
	tween.interpolate_property(actor, "position", null, batman.grid_gpos.get_cellv(to_coord), dur,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.interpolate_property(actor.vis_object, "position:y", null, -height, dur/2.0,Tween.TRANS_CUBIC, Tween.EASE_OUT)
	tween.interpolate_property(actor.vis_object, "position:y", -height, 0.0, dur/2.0,Tween.TRANS_CUBIC, Tween.EASE_IN, dur/2.0)
	tween.start()
	pass


# MUST be called when a move 'officially' changes our data position!
#func update_actor_coord_data(actor: Actor, newpos: Vector2) -> bool:
#	if !batman.grid_actors.has_cellv(newpos):
#		print("ACT: ERROR, Invalid coord! update_actor_coord_data(",actor,", ",newpos,")")
#		return false
#
#	var oldpos: Vector2 = actor.coord
#	if batman.grid_actors.get_cellv(oldpos) != actor:
#		print("ACT: ERROR, Actor not data-recognized at old coords! update_actor_coord_data(",actor,", ",newpos,")")
#		return false
#
#	var occupant: Actor = batman.grid_actors.get_cellv(newpos)
#	if occupant != null:
#
#		# Could be intentional for something like a missile collision - emit a signal, and if it IS valid, anyone hooked into it can do what needs doing and if either actor dies (the missile, again), it can retrigger this func manually after an actor is killed to clear space
#		emit_signal("actor_collision_attempt", actor, occupant)
#		print("ACT: ERROR (maybe?), there is already an Actor at dest coords! (",actor,", ",newpos,")")
#		return false
#
#	actor.coord = newpos
#	batman.grid_actors.set_cellv(oldpos, null)
#	batman.grid_actors.set_cellv(newpos, actor)
#
#	return true
#	pass

# ATTACKS ------------------------------------------------------------------------------------------

func damage_actor_at_coord(attacker: Actor, exact_coord: Vector2, damage: int, is_melee: bool, friendly_fire: bool = true):
	var victim: Actor = batman.grid_actors.get_cellv(exact_coord)
	if victim == null:
		return
	
	if victim.faction == attacker.faction:
		if !friendly_fire:
			return
	
	victim.receive_damage(damage, is_melee)
	pass

# TILE ADJUSTMENTS ---------------------------------------------------------------------------------

func change_tiletype_single(coord: Vector2, to_tiletype: int, can_change_pits: bool = false): # Just a shorthand
	change_tiletype_mass([coord], to_tiletype, can_change_pits)
	pass

# For multiple tiletypes, use multiple calls
func change_tiletype_mass(coordset: Array, to_tiletype: int, can_change_pits: bool = false):
	# Prepare 'actual' changes, including custom logic
	var impact_dict: Dictionary = {} # Vector keys, int values for tiletype
	
	# Validate the deisred changes and see what's actually viable
	for coord in coordset:
		
		# We don't normally change pits
		if batman.grid_tiles.get_cellv(coord) == batman.tiletypes.PIT:
			if !can_change_pits:
				continue
		
		# HACK: For now, we're removing the pit function entirely
		elif to_tiletype == batman.tiletypes.PIT:
			continue
		
#		# Make sure an actor cannot be pitted
#		elif to_tiletype == batman.tiletypes.PIT:
#			if batman.grid_actors.get_cellv(coord) != null: # Yes, there's an actor!
#				if batman.grid_tiles.get_cellv(coord) != batman.tiletypes.JAGGED:
#					# Only bother 'cracking' if it's not already cracked
#					# (Otherwise, this is skipped)
#					impact_dict[coord] = batman.tiletypes.JAGGED
#				continue
#
#		# Make sure a re-cracked unoccupied tile becomes a pit instead
#		elif to_tiletype == batman.tiletypes.JAGGED:
#			if batman.grid_tiles.get_cellv(coord) == batman.tiletypes.JAGGED:
#				if batman.grid_actors.get_cellv(coord) == null: # Unoccupied pre-cracked tile!
#					impact_dict[coord] = batman.tiletypes.PIT
#					continue
		
		# If no other conditions are met, we process as-is!
		impact_dict[coord] = to_tiletype
		pass
	
	if impact_dict.empty():
		return
	
	# At this point, everything in the impact_dict can and should be changed!
	# Note that they might not all be the same tiletype anymore.
	
	# Apply actual changes
	for coord in impact_dict.keys():
		batman.grid_tiles.set_cellv(coord, impact_dict[coord])
	
	print("Preparing tilechanges:\n",impact_dict)
	batman.emit_signal("update_all_tiletypes")
	pass


# SUPPORT QUERIES ----------------------------------------------------------------------------------

func vet_actormove_optionset_relative(actor: Actor, og_options: Array) -> Array:
	return master_vet_actormove_optionset(actor, og_options, true)
func vet_actormove_optionset_exact(actor: Actor, og_options: Array) -> Array:
	return master_vet_actormove_optionset(actor, og_options, true)
func master_vet_actormove_optionset(actor: Actor, og_options: Array, is_relative: bool = true) -> Array:
	var valid_options: Array = []

	# We don't want to CHANGE the coord to be exact if relative, because they need to return the same way they were sent!
	for coord in og_options: if coord is Vector2:
		if is_relative:
			if is_tile_traversable_relative(actor, coord):
				valid_options.append(coord)
		else:
			if is_tile_traversable_exact(actor, coord):
				valid_options.append(coord)

	return valid_options
	pass

func is_tile_traversable_relative(actor: Actor, motion: Vector2, ignore_ghost: bool = false) -> bool:
	return is_tile_traversable_exact(actor, actor.coord + motion, ignore_ghost)
	
func is_tile_traversable_exact(actor: Actor, target: Vector2, ignore_ghost: bool = false) -> bool:
	var _start_coord: Vector2 = actor.coord
	var end_coord: Vector2 = target
	
	# Can't move off the grid
	if !batman.grid_tiles.has_cellv(end_coord):
#		print("ACT: iamp[1] Cell does not exist on board!")
		return false
	
	# IN MOST CIRCUMSTANCES, you can't enter an unavailable space!
	if !actor.is_ghost and !ignore_ghost:
		if !is_tile_available(end_coord):
#			print("ACT: iamp[2] Cell is unavailable!")
			return false
	
	# Can't move on to other factions' cells
		# (unless you're neutral? or a non-enemy like a missile?)
		# Maybe make missiles etc Neutral to represent 'friendly fire'
	if !actor.allowed_over_faction_lines:
		if actor.faction == batman.factions.PLAYER:
			if batman.grid_factions.get_cellv(end_coord) != batman.factions.PLAYER:
#				print("ACT: iamp[3a] Player cannot exit its faction area!")
				return false
		if actor.faction == batman.factions.ENEMY:
			if batman.grid_factions.get_cellv(end_coord) != batman.factions.ENEMY:
#				print("ACT: iamp[3b] Enemy cannot exit its faction area!")
				return false
	
	# Can only move on pits IF you can hover
	if batman.grid_tiles.get_cellv(end_coord) == batman.tiletypes.PIT:
		if !actor.is_hovering:
#			print("ACT: cmev[4] Dest is pit but actor can't hover!")
			return false
	
	return true
	pass

# -

# Note that this only clears the FIRST previous cell!
func change_actor_coord(actor: Actor, new_coord: Vector2):
	var dataset: Array = batman.grid_actors.get_dataset_with_coords()
	var old_coord: Vector2
	for set in dataset:
		if set[0] == actor:
			old_coord = set[1]
			if old_coord == new_coord:
				print("ACT: ERROR, tried to change actor grid coord to the same as it was?")
				return false
			batman.grid_actors.set_cellv(old_coord, null)
			batman.grid_actors.set_cellv(new_coord, actor)
			return true
	
	print("ACT: ERROR, tried to change actor grid coord when it wasn't already on the grid?")
	return false
	pass

func remove_actor_from_actorgrid(actor):
	if not actor is Actor: return
	for set in batman.grid_actors.get_dataset_with_coords():
		if set[0] == actor:
			batman.grid_actors.set_cellv(set[1], null)
	pass

func release_all_claims():
	var dataset: Array = batman.grid_claims.get_dataset_with_coords()
	for set in dataset:
		batman.grid_claims.set_cellv(set[1], null)
	pass

func release_most_claims(): # Allows SOME actors to keep their claims
	
	var dataset: Array = batman.grid_claims.get_dataset_with_coords()
	for set in dataset:
		var actor: Actor = set[0]
		if actor.keep_claims_at_eot:
			continue
		batman.grid_claims.set_cellv(set[1], null)
	pass

func release_actor_claims(actor: Actor):
	var dataset: Array = batman.grid_claims.get_dataset_with_coords()
	for set in dataset:
		if set[0] == actor:
			batman.grid_claims.set_cellv(set[1], null)
	pass

# -

func can_see_PC_in_dir(og_coord: Vector2, dir: Vector2) -> bool:
	return (find_nearest_PC_in_dir(og_coord, dir) != null)
func can_see_ENEMY_in_dir(og_coord: Vector2, dir: Vector2) -> bool:
	return (find_nearest_ENEMY_in_dir(og_coord, dir) != null)
func find_nearest_PC_in_dir(og_coord: Vector2, dir: Vector2) -> Actor:
	return find_nearest_actor_in_dir(og_coord, dir, batman.factions.PLAYER)
func find_nearest_ENEMY_in_dir(og_coord: Vector2, dir: Vector2) -> Actor:
	return find_nearest_actor_in_dir(og_coord, dir, batman.factions.ENEMY)
func find_nearest_actor_in_dir(og_coord: Vector2, dir: Vector2, must_be_faction: int = -1) -> Actor:
	var check_coord: Vector2 = og_coord
	
	while true:
		check_coord += dir
		if !batman.grid_actors.has_cellv(check_coord):
			break
		var occupant: Actor = batman.grid_actors.get_cellv(check_coord)
		if occupant == null:
			continue
		
		# Can specify that it must be a certain faction; otherwise it'll default just return the first, period
		if must_be_faction != -1:
			if occupant.faction != must_be_faction:
				continue
		
		return occupant
	
	return null
	pass

func get_dist_between_actors(first_actor: Actor, second_actor: Actor) -> Vector2:
	# We assume these are already validated!
	var dist: Vector2 = second_actor.coord - first_actor.coord
	return dist.abs()
	pass

func get_vector_from_actor_a_to_b(first_actor: Actor, second_actor: Actor) -> Vector2:
	# We assume these are already validated!
	var dist: Vector2 = second_actor.coord - first_actor.coord
	return dist
	pass

func get_first_actor_by_name(nstring: String, must_be_alive: bool = true) -> Actor:
	for a in actors.get_children(): if a is Actor:
		if a.ofc_name == nstring:
			if must_be_alive:
				if a.health > 0:
					return a
			else: return a
	
	return null
	pass

func get_rand_adj_tile_for_actormoving(og_tile: Vector2, actor: Actor) -> Vector2:
	return master_get_rand_adj_tile(og_tile, false, actor)
func get_rand_adj_tile_unoccupied(og_tile: Vector2) -> Vector2:
	return master_get_rand_adj_tile(og_tile, true)
func get_rand_adj_tile_any(og_tile: Vector2) -> Vector2:
	return master_get_rand_adj_tile(og_tile)
func master_get_rand_adj_tile(og_tile: Vector2, occupation_check: bool = false, relevant_actor: Actor = null) -> Vector2:
	var opts: Array = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	
	# Only check within the bounds of the board
	for adj in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		if !batman.grid_tiles.has_cellv(og_tile + adj):
			opts.erase(adj)
	
	# Means it should fail if it's already occupied
	if relevant_actor != null:
		for dir in opts.duplicate():
			if !is_tile_traversable_relative(relevant_actor, dir):
				opts.erase(dir)
	
	# We don't bother with this if there's a relevant actor, because the necessary check gets handled there - this is if occupation matters and there's NOT a relevant actor (I guess?)
	elif occupation_check:
		for dir in opts.duplicate():
			var checkcoord: Vector2 = og_tile + dir
			if !batman.grid_actors.get_cellv(checkcoord) == null:
				opts.erase(dir)
	
	# Sending the OG tile is the failure fallback
	if opts.empty():
		print("ACT: Could not find a valid random adjacent tile for ",og_tile,", returning OG!")
		return og_tile
	
	opts.shuffle()
	return og_tile + opts[0]
	pass

func get_rand_faction_tile_for_actormoving(actor: Actor, faction: int, ignore_ghost: bool = false) -> Vector2: # NON adjacent specific!
	var opts: Array = get_all_tiles_by_faction(faction)
	var valid_opts: Array = []
	for coord in opts:
		if is_tile_traversable_exact(actor, coord, ignore_ghost): # Handles all our validations
			valid_opts.append(coord)
	
	if valid_opts.empty():
		return actor.coord # The fallback is always just 'stay where you are'
	
	valid_opts.shuffle()
	return valid_opts[0]

# Note that these arrays do NOT contain the center tile itself!
func get_adj_orthagonal_tiles(center_tile: Vector2, are_pits_allowed: bool = false, must_be_faction: int = -1) -> Array:
	return master_get_adj_tiles(center_tile, true,  are_pits_allowed, must_be_faction)
func get_adj_diagonal_tiles(center_tile: Vector2, are_pits_allowed: bool = false, must_be_faction: int = -1) -> Array:
	return master_get_adj_tiles(center_tile, false, are_pits_allowed, must_be_faction)
func get_adj_3x3_tiles(center_tile: Vector2, are_pits_allowed: bool = false, must_be_faction: int = -1) -> Array:
	var all: Array = []
	all.append_array(master_get_adj_tiles(center_tile, true,  are_pits_allowed, must_be_faction))
	all.append_array(master_get_adj_tiles(center_tile, false, are_pits_allowed, must_be_faction))
	return all

func master_get_adj_tiles(center_tile: Vector2, type_is_orthag: bool, are_pits_allowed: bool, must_be_faction: int) -> Array:
	var viable_set: Array = []
	
	var surrounders: Array = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	if !type_is_orthag:
		surrounders = [
			Vector2.UP + Vector2.LEFT,
			Vector2.UP + Vector2.RIGHT,
			Vector2.DOWN + Vector2.LEFT,
			Vector2.DOWN + Vector2.RIGHT]
	
	for surr in surrounders:
		var coord: Vector2 = center_tile + surr
		if !batman.grid_tiles.has_cellv(coord):
			continue
		if !are_pits_allowed:
			if batman.grid_tiles.get_cellv(coord) == batman.tiletypes.PIT:
				continue
		if must_be_faction != -1:
			if batman.grid_factions.get_cellv(coord) != must_be_faction:
				continue
		viable_set.append(coord)
	
	return viable_set

func get_all_tiles_by_faction(faction: int) -> Array:
	var results: Array = []
	var dataset: Array = batman.grid_factions.get_dataset_with_coords()
	for entry in dataset:
		if entry[0] == faction:
			if !results.has(entry[1]):
				results.append(entry[1])
	return results
	pass
