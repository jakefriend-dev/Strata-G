extends Node

var tags: Dictionary = {}

var orthags: Array = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
var diags: Array = [
	Vector2(-1, -1),
	Vector2(-1,  1),
	Vector2( 1, -1),
	Vector2( 1,  1)
	]

func _ready():
	import_tags_tsv()
	pass

func import_tags_tsv():
	tags.clear()
	
	# Prep the file
	var tsvpath = "res://tsv/Tags.tsv"
	var file: File = File.new()
	file.open(tsvpath, File.READ)
#	var line: int = -1 # 0-based; FILE line whether valid or not
	
	while !file.eof_reached():
#		line += 1
#		if line == 0: continue # Ignore header
		
		var row: Array = file.get_line().split("\t")
		
		var dnu: String = str(row[0])
		if dnu != "": continue # No organization GSheet data!
		
		var type: String = str(row[1])
		var key: String = str(row[2])
		var display_name: String = str(row[3])
		var display_desc: String = str(row[4])
		var subtags_text: String = str(row[5])
		
		if (type == "" or key == "" or display_name == "" or display_desc == ""):
			# Invalid line; either intentionally blank or data is not completely filled in
			continue
		
		subtags_text = subtags_text.replace(" ", "")
		var subtags: Array = subtags_text.split(",")
		
		var entry: Dictionary = {}
		entry["key"] = key # Redundancy, I know
		entry["type"] = type
		entry["display_name"] = display_name
		entry["display_desc"] = display_desc
		entry["subtags"] = []
		entry["subtags"] = subtags
		
		tags[key] = {}
		tags[key] = entry
		# Great work! Next line!
		continue
	
	file.close()
	
#	print("SUPPORT: Tags are ",tags)
	pass

# AVAILABILITY & TRAVERSABILITY ------------------------------------------------

	# (ghosts are not considered in these checks)
	
	# OCCUPIED: The tile has an actor in it
	# AVAILABLE: The tile has *neither* an actor nor a claim
	# TRAVERSABLE: The tile is available AND a specific actor is capable of being there
		# (ie. it's not a "pit but I can't hover" situation, or a faction bounds issue)

func log_actorhit_if_occupied(actor: Actor, coord: Vector2):
	if is_cellv_occupied(coord):
		actor.log_hit()
	return

func is_cellv_occupied(coord: Vector2) -> bool:
	if !batman.grid_actors.has_cellv(coord): return false # Off the grid
	
	# Valid actor exists (normally)
	var actor: Actor = batman.grid_actors.get_cellv(coord)
	if actor != null:
		if utils.actorpass(actor):
			return true
	
	# If not on the grid, let's check ghost actors!
	for ghost in batman.ghost_actors:
		if ghost.coord == coord:
			if utils.actorpass(ghost):
				return true
	
	return false
	pass

func get_actor_at_cellv(coord: Vector2) -> Actor:
	if !batman.grid_actors.has_cellv(coord): return null # Off the grid
	
	# Valid actor exists (normally)
	var actor: Actor = batman.grid_actors.get_cellv(coord)
	if actor != null:
		if utils.actorpass(actor):
			return actor
	
	# If not on the grid, let's check ghost actors!
	for ghost in batman.ghost_actors:
		if ghost.coord == coord:
			if utils.actorpass(ghost):
				return ghost
	
	return null
	pass

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

func list_all_unoccupied_tiles_in_dir(og_cell: Vector2, dir: Vector2, tile_limit: int = -1) -> Array:
	if dir == Vector2.ZERO: return []
	
	var coords_in_dir: Array = []
	var check_cell: Vector2 = og_cell
	
	var count: int = 0
	while true:
		check_cell += dir
		if batman.grid_tiles.has_cellv(check_cell):
			if !utils.valid(batman.grid_actors.get_cellv(check_cell)):
				coords_in_dir.append(check_cell)
				count += 1
				if tile_limit > 0 and count == tile_limit: break
				continue
		break
	
	return coords_in_dir
	pass

func list_all_traversible_tiles_in_dir(dir: Vector2, actor: Actor) -> Array:
	var og_cell: Vector2 = actor.coord
	var all_cells_in_dur: Array = get_all_tiles_in_dir(og_cell, dir)
	return list_all_traversible_tiles_in_set(all_cells_in_dur, actor)

# Returns successfully-claimed tiles IN ORDER, breaking on first issue
func list_all_traversible_tiles_in_set(exact_coords: Array, actor: Actor) -> Array:
	var traversible_cells: Array = []
	
	for exact_coord in exact_coords:
		# Break if it's a non-empty cell that ISN'T US
		if batman.grid_claims.get_cellv(exact_coord) != null:
			if batman.grid_claims.get_cellv(exact_coord) != self:
				break
		# Break if it's not traversable
		if !is_tile_traversable_exact(actor, exact_coord):
			break
		
		# Otherwise, it's good!
		traversible_cells.append(exact_coord)
	
	return traversible_cells
	pass

func is_tile_available(exact_coord: Vector2, exception_actors: Array = []) -> bool:
	# When and ONLY when exception_actor is populated, we'll allow it to return itself.
	
	var found_actor: Actor = batman.grid_actors.get_cellv(exact_coord)
	if found_actor != null:
		if !exception_actors.has(found_actor):
			print("SUPPORT: is_tile_available(",exact_coord,") found actor: ",found_actor)
			return false
	
	var found_claimant: Actor = batman.grid_claims.get_cellv(exact_coord)
	if found_claimant != null:
		if !exception_actors.has(found_claimant):
			print("SUPPORT: is_tile_available(",exact_coord,") found claim by actor: ",found_claimant)
			return false
	
	return true

# PLAYER SHORTCUTS ---------------------------------------------------------------------------------

# MOVE (ORTHAGONAL/ADJACENT) -----------------------------------------------------------------------

# TILE ADJUSTMENTS ---------------------------------------------------------------------------------

func change_tiletype_single(coord: Vector2, to_tiletype: int, restrictions_override: bool = false): # Just a shorthand
	change_tiletype_mass([coord], to_tiletype, restrictions_override)
	pass

# For multiple tiletypes, use multiple calls
func change_tiletype_mass(coordset: Array, to_tiletype: int, restrictions_override: bool = false):
	# Prepare 'actual' changes, including custom logic
	var impact_dict: Dictionary = {} # Vector keys, int values for tiletype
	
	# Validate the deisred changes and see what's actually viable
	for coord in coordset:
		
		if !batman.grid_tiles.has_cellv(coord): continue
		
		var og_tiletype: int = batman.grid_tiles.get_cellv(coord)
		if og_tiletype == to_tiletype:
			continue
		
		# Steel should be immune
		if og_tiletype == batman.tiletypes.MAGIC:
			if !restrictions_override:
				continue
		
		# We don't normally change pits
		if og_tiletype == batman.tiletypes.PIT:
			if !restrictions_override:
				continue
		
		# We're removing the become-pit function entirely; it's from the start of a fight or never
		elif to_tiletype == batman.tiletypes.PIT:
			continue
		
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
	
#	print("Preparing tilechanges:\n",impact_dict)
	batman.emit_signal("update_all_tiletypes")
	strife.note_combatstate_event("tile_change")
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

func is_tile_traversable_relative(actor: Actor, motion: Vector2, any_faction_override: bool = false) -> bool:
	return is_tile_traversable_exact(actor, actor.coord + motion, any_faction_override)
	
func is_tile_traversable_exact(actor: Actor, target: Vector2, any_faction_override: bool = false) -> bool:
	var _start_coord: Vector2 = actor.coord
	var end_coord: Vector2 = target
	
	# Can't move off the grid
	if !batman.grid_tiles.has_cellv(end_coord):
#		print("ACT: iamp[1] Cell does not exist on board!")
		return false
	
#	if !actor.is_ghost and !ignore_ghost:
#		print("WOULD HAVE BEEN AN ISSUE HERE JFYI")
	
	# IN MOST CIRCUMSTANCES, you can't enter an unavailable space!
	if !actor.is_ghost:
		if !is_tile_available(end_coord):
#			print("ACT: iamp[2] Cell is unavailable!")
			return false
	
	# Can't move on to other factions' cells
		# (unless you're neutral? or a non-enemy like a missile?)
		# Maybe make missiles etc Neutral to represent 'friendly fire'
	if !actor.allowed_over_faction_lines and !any_faction_override:
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
		if actor.weight != actor.weightclasses.HOVER:
#			print("ACT: cmev[4] Dest is pit but actor can't hover!")
			return false
	
	return true
	pass

# -

func can_see_PC_in_dir(og_coord: Vector2, dir: Vector2) -> bool:
	return (find_nearest_PC_in_dir(og_coord, dir) != null)
func can_see_ENEMY_in_dir(og_coord: Vector2, dir: Vector2) -> bool:
	return (find_nearest_ENEMY_in_dir(og_coord, dir) != null)
func find_nearest_PC_in_dir(og_coord: Vector2, dir: Vector2, tile_limit: int = -1) -> Actor:
	return find_nearest_actor_in_dir(og_coord, dir, tile_limit, batman.factions.PLAYER)
func find_nearest_ENEMY_in_dir(og_coord: Vector2, dir: Vector2, tile_limit: int = -1) -> Actor:
	return find_nearest_actor_in_dir(og_coord, dir, tile_limit, batman.factions.ENEMY)
func find_nearest_actor_in_dir(og_coord: Vector2, dir: Vector2, tile_limit: int = -1, must_be_faction: int = -1) -> Actor:
	
	var check_coord: Vector2 = og_coord
	var count: int = -1
	while true:
		count += 1 # Makes it 0-based
		if tile_limit > 0 and count >= tile_limit: break
		
		check_coord += dir
		if !batman.grid_actors.has_cellv(check_coord):
			# Give up when we're OFF the grid as a failsafe
			break
		var occupant: Actor = batman.grid_actors.get_cellv(check_coord)
		if occupant == null:
			# Ignore empty tiles
			continue
		
		# Can specify that it must be a certain faction; otherwise it'll default just return the first, period
		if must_be_faction != -1:
			if occupant.faction != must_be_faction:
				# Ignore factionally-irrelevant actors
				continue
		
		return occupant
	
	return null
	pass

# NOT a hypoteneuse, a difference in positions!
func get_vecdist_between_actors(first_actor: Actor, second_actor: Actor) -> Vector2:
	# We assume these are already validated!
	var dist: Vector2 = second_actor.coord - first_actor.coord
	return dist.abs()
	pass

func get_vector_from_actor_a_to_b(first_actor: Actor, second_actor: Actor) -> Vector2:
	# We assume these are already validated!
	var dist: Vector2 = second_actor.coord - first_actor.coord
	return dist
	pass

func are_actors_adjacent(a: Actor, b: Actor) -> bool:
	if !utils.valid(a) or !utils.valid(b): return false
	
	if a.coord == b.coord: return true
	
	if a.coord == b.coord + Vector2.LEFT:  return true
	if a.coord == b.coord + Vector2.RIGHT: return true
	if a.coord == b.coord + Vector2.UP:    return true
	if a.coord == b.coord + Vector2.DOWN:  return true
	
	return false
	pass

func get_first_actor_by_name(nstring: String, must_be_alive: bool = true) -> Actor:
	for a in batman.actors.get_children(): if a is Actor:
		if a.display_name == nstring:
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

func get_rand_faction_tile_for_actormoving(actor: Actor, faction: int, regardless_of_ghost: bool = false) -> Vector2: # NON adjacent specific!
	var opts: Array = get_all_tiles_by_faction(faction)
	var valid_opts: Array = []
	for coord in opts:
		if coord == actor.coord: continue
		if is_tile_traversable_exact(actor, coord, regardless_of_ghost): # Handles all our validations
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
	
	var surrounders: Array = orthags.duplicate()
	if !type_is_orthag:
		surrounders = diags.duplicate()
	
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


func get_all_tiles_of_MY_faction(calling_actor: Actor) -> Array:
	return get_all_tiles_by_faction(calling_actor.faction)
	pass

func get_all_tiles_of_THEIR_faction(calling_actor: Actor) -> Array:
	var other_faction: int
	if calling_actor.faction == batman.factions.ENEMY:
		other_faction = batman.factions.PLAYER
	elif calling_actor.faction == batman.factions.PLAYER:
		other_faction = batman.factions.ENEMY
	return get_all_tiles_by_faction(other_faction)
	pass

func get_all_tiles_by_faction(faction: int) -> Array:
	var results: Array = []
	var dataset: Array = batman.grid_factions.get_dataset_with_coords()
	for entry in dataset:
		if entry[0] == faction:
			if !results.has(entry[1]):
				results.append(entry[1])
	return results
	pass

func is_arrow_a_line(start: Vector2, end: Vector2) -> bool:
	var motion: Vector2 = end - start
	return is_motion_a_line(motion)

func is_motion_a_line(motion: Vector2) -> bool:
	# Orthagonal cases
	if is_zero_approx(motion.x): return true
	if is_zero_approx(motion.y): return true
	
	# Diagonal cases
	if is_equal_approx(abs(motion.x), abs(motion.y)): return true
	
	# Otherwise, one non-zero number is waaay different from the rest
	return false

func lineize_motion(motion: Vector2) -> Vector2:
	
	# This crunches to EIGHT directions in a straight grid line
	# Basically, if either axis value is 0, it's an orthagonal line, and that counts
	# Otherwise, diagonal is the lesser of both abs(values)
	
	# So motion of -3, 14 would be reduced to -3, 3 (rather than averaged out, so to speak)
	
	# Orthagonal cases
	if is_zero_approx(motion.x): return motion
	if is_zero_approx(motion.y): return motion
	
	var vecneg: Vector2 = Vector2(1, 1)
	if motion.x < 0: vecneg.x = -1
	if motion.y < 0: vecneg.y = -1
	
	motion = motion.abs()
	var minval: int = int(round(min(motion.x, motion.y)))
	var new_motion: Vector2 = Vector2(minval * vecneg.x, minval * vecneg.y)
	
	return new_motion

func get_steps_in_vector_line_int(vector: Vector2) -> int:
	# Line cases
	if is_zero_approx(vector.x):
		return int(round(abs(vector.y)))
	if is_zero_approx(vector.y):
		return int(round(abs(vector.x)))
	
	# Diagonal cases (assume we're only feeding line-ized vectors?)
	return int(round(abs(vector.y))) # Y vs X doesn't matter if it's diagonal
	pass

# "Vector_int" is a vector that IS ints and also which steps by 1 int. Wordplay!
func step_vector_int_towards_zero(vector: Vector2, step: int = 1) -> Vector2:
	var new_vector: Vector2
	
	if vector.x < 0:
		new_vector.x = vector.x + step
	elif vector.x > 0:
		new_vector.x = vector.x - step
	
	if vector.y < 0:
		new_vector.x = vector.y + step
	elif vector.y > 0:
		new_vector.x = vector.y - step
	
	# Safeguard to ensure we don't have 0.00002
	if abs(round(new_vector.x)) < step: new_vector.x = 0
	if abs(round(new_vector.y)) < step: new_vector.y = 0
	
	return new_vector
	pass

func de_ghost_all_actors():
	for actor in batman.living_actors: if actor is Actor:
		if actor.is_ghost:
			actor.ghost_mode(false)
			actor.release_claims()
	pass

func quip(gpos: Vector2, text: String):
	var quip: Node2D = loader.res_quip.instance()
	quip.set("text", text)
	quip.set("position", gpos)
	
	batman.field.quip_par.add_child(quip)
	pass


