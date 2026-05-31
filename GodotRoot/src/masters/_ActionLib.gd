extends Node

var tween: Tween
var trans: int = Tween.TRANS_QUINT

var timeout_time: float = (3.0/60.0) # How long between skipped actions if time has not passed
var min_dur: float = 0.10 # In theory, only relevant for enemies, not the player
var std_dur: float = 0.25

var last_execution_frame: int = -1
var action_queue: Array = []
var curr_action: Array = []
var prev_action: Array = []

signal action_step_complete() # Should fire any time we do an individual action OR each step in a multi-step action -
signal all_action_steps_complete() # Should fire whenever ALL steps are done

signal actor_collision_attempt(actor_attacking, actor_defending) # Can be used for things like missile collisions

var field: Node2D # Owner of all battle stuff
var actors: YSort
var board: GridContainer # Owner of CELLS not everything

var actionlog: Array = [] # Historical log of all processed AND FAILED actions! Strings only
var log_retention: int = 10

# ---

func _ready():
	tween = Tween.new()
	add_child(tween)
	pass

# PROCESSING ---------------------------------------------------------------------------------------

func flush(): # Run to wipe any stored-between-turns data
	release_most_claims()
	
	action_queue.clear()
	curr_action = []
	prev_action = []
	last_execution_frame = -1
	pass

func vet_action(action: Array) -> bool:
	# We expect 2-3 values: A valid actor, a valid method in that actor's script, and *optionally*, an array of param data for the method. The array is allowed to be missing or empty, and can have whatever in it. HOWEVER, in any situation where no paramset is sent, we add an empty array for consistency. A validated action DOES have 3 params.
	
	if action.size() != 2 and action.size() != 3:
		print("ACT: vet_action(",action,") failed: Array is the wrong size")
		return false
	
	if not action[0] is Actor:
		print("ACT: vet_action(",action,") failed: First param is not an Actor")
		return false
	
	var actor: Actor = action[0]
	
	if actor == null:
		print("ACT: vet_action(",action,") failed: Actor is null")
		return false
	
	if !actor.active:
		print("ACT: vet_action(",action,") failed: Actor is not active")
		return false
	
	if not action[1] is String:
		print("ACT: vet_action(",action,") failed: Second param is not a string (for methodname)")
		return false
	
	var methodname: String = action[1]
	
	if methodname == "":
		print("ACT: vet_action(",action,") failed: Method name is blank")
		return false
	
	if !actor.has_method(str("ACT_"+methodname)):
		print("ACT: vet_action(",action,") failed: Actor does not have method")
		return false
	
	if action.size() == 3:
		if not action[2] is Array:
			print("ACT: vet_action(",action,") failed: Third param is not an Array")
			return false
	
	return true
	pass

func append_action(actor: Actor, methodname: String, paramset: Array = []):
	var action: Array = [actor, methodname, paramset]
	if !vet.action(action):
		return
	
	# Validations complete
	action_queue.append(action)
	pass

func insert_action(position: int, actor: Actor, methodname: String, paramset: Array = []):
	var action: Array = [actor, methodname, paramset]
	if !vet_action(action):
		return
	
	if position < 0:
		print("ACT: Invalid index insert_action(",action,", ",position,"), adjusting up to 0!")
		position = 0
	elif position > action_queue.size():
		print("ACT: Invalid index insert_action(",action,", ",position,"), appending instead!")
		append_action(actor, methodname, paramset)
		return
	
	# Validations complete
	action_queue.insert(position, action)
	pass

# For quick-running a single action!
func execute_action(actor: Actor, methodname: String, paramset: Array = []): 
	insert_action(0, actor, methodname, paramset)
	progress_action_queue()
	pass

func progress_action_queue(): # Calls ONE next action, or if there is none, skips
	last_execution_frame = get_tree().get_frame()
	
	if action_queue.empty():
		step_signal()
		return
	
	# Final checks on if the actor is STILL valid, given some delays since vet_action()
	var unvalidated_action: Array = action_queue.pop_front()
	var actor: Actor = unvalidated_action[0]
	if actor == null:
		step_signal()
		return
	if !actor.active:
		step_signal()
		return
	
	# Actor is valid, so action is as well! Update trackers
	prev_action = []
	prev_action = curr_action
	curr_action = []
	curr_action = unvalidated_action
	
	# Gather data...
	var methodname: String = str("ACT_"+curr_action[1])
	var paramset: Array = curr_action[2]
	
	# Log the action BEFORE executing
	var logstring: String = str(curr_action)
	actionlog.insert(0, logstring)
	if actionlog.size() > log_retention:
		actionlog.resize(log_retention)
	
	# Execute!
	if paramset.empty():
		actor.call(methodname)
	else:
		# We can't know how many parameters the method is expecting; we have to expect issue upon failure, alas.
		actor.callv(methodname, paramset)
	
	# Great success. It's the actor's job to cue end_action() from here, or for an interruption to step_signal() instead.
	pass

func step_signal(): # The call that an action 'step' has ended, or needs to be skipped
	# The action_step signals here should NEVER fire the same frame this method is called! If so, we need to wait at LEAST 1 frame before proceeding.
	if last_execution_frame == get_tree().get_frame():
		yield(utils.yt(timeout_time, self), "timeout")
	
	emit_signal("action_step_complete")
	if action_queue.empty():
#		print("ACT: action_queue has emptied!")
		emit_signal("all_action_steps_complete")
		return
	
	# Since there are more actions, let's process one!
	progress_action_queue()
	pass


# TURN-RELATED MASTERS -----------------------------------------------------------------------------

# Just shortcuts that might be easier to remember.
func end_action():  step_signal()
func skip_action(): step_signal()


# PLAYER SHORTCUTS ---------------------------------------------------------------------------------

# MOVE (ORTHAGONAL/ADJACENT) -----------------------------------------------------------------------

func hotmove(actor: Actor, to_coord: Vector2, dur: float):
	tween.interpolate_property(actor, "position", null, batman.grid_gpos.get_cellv(to_coord), dur,Tween.TRANS_CIRC, Tween.EASE_IN_OUT)
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

func damage_actor_at_coord(attacker: Actor, exact_coord: Vector2, damage: int, friendly_fire: bool = true):
	var victim: Actor = batman.grid_actors.get_cellv(exact_coord)
	if victim == null:
		return
	
	if victim.faction == attacker.faction:
		if !friendly_fire:
			return
	
	victim.receive_damage(damage)
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
		
		# Make sure an actor cannot be pitted
		elif to_tiletype == batman.tiletypes.PIT:
			if batman.grid_actors.get_cellv(coord) != null: # Yes, there's an actor!
				if batman.grid_tiles.get_cellv(coord) != batman.tiletypes.CRACK:
					# Only bother 'cracking' if it's not already cracked
					# (Otherwise, this is skipped)
					impact_dict[coord] = batman.tiletypes.CRACK
				continue
		
		# Make sure a re-cracked unoccupied tile becomes a pit instead
		elif to_tiletype == batman.tiletypes.CRACK:
			if batman.grid_tiles.get_cellv(coord) == batman.tiletypes.CRACK:
				if batman.grid_actors.get_cellv(coord) == null: # Unoccupied pre-cracked tile!
					impact_dict[coord] = batman.tiletypes.PIT
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
	
	print("Preparing tilechanges:\n",impact_dict)
	batman.emit_signal("update_all_tiletypes")
	pass


# SUPPORT QUERIES ----------------------------------------------------------------------------------

func vet_actormove_optionset_relative(actor: Actor, og_options: Array, allowed_over_faction_lines: bool = false) -> Array:
	return master_vet_actormove_optionset(actor, og_options, true, allowed_over_faction_lines)
func vet_actormove_optionset_exact(actor: Actor, og_options: Array, allowed_over_faction_lines: bool = false) -> Array:
	return master_vet_actormove_optionset(actor, og_options, true, allowed_over_faction_lines)
func master_vet_actormove_optionset(actor: Actor, og_options: Array, is_relative: bool = true, allowed_over_faction_lines: bool = false) -> Array:
	var valid_options: Array = []

	# We don't want to CHANGE the coord to be exact if relative, because they need to return the same way they were sent!
	for coord in og_options: if coord is Vector2:
		if is_relative:
			if is_actormove_possible_relative(actor, coord, allowed_over_faction_lines):
				valid_options.append(coord)
		else:
			if is_actormove_possible_exact(actor, coord, allowed_over_faction_lines):
				valid_options.append(coord)

	return valid_options
	pass

func is_actormove_possible_relative(actor: Actor, motion: Vector2, allowed_over_faction_lines: bool = false) -> bool:
	return is_actormove_possible_exact(actor, actor.coord + motion, allowed_over_faction_lines)
	
func is_actormove_possible_exact(actor: Actor, target: Vector2, allowed_over_faction_lines: bool = false) -> bool:
	var _start_coord: Vector2 = actor.coord
	var end_coord: Vector2 = target
	
	# Can't move off the grid
	if !batman.grid_tiles.has_cellv(end_coord):
#		print("ACT: iamp[1] Cell does not exist on board!")
		return false
		
	# Can't move into *any* other actors, period
	if batman.grid_actors.get_cellv(end_coord) != null:
#		print("ACT: iamp[2] Other actor occupies destination!")
		return false
	
	# Can't move on to other factions' cells
		# (unless you're neutral? or a non-enemy like a missile?)
		# Maybe make missiles etc Neutral to represent 'friendly fire'
	if !allowed_over_faction_lines:
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
			if !is_actormove_possible_relative(relevant_actor, dir):
				opts.erase(dir)
	
	# We don't bother with this if there's a relevant actor, because the necessary check gets handled there
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

func get_rand_faction_tile_for_actormoving(actor: Actor, faction: int) -> Vector2: # NON adjacent specific!
	var opts: Array = get_all_tiles_by_faction(faction)
	var valid_opts: Array = []
	for coord in opts:
		if is_actormove_possible_exact(actor, coord, true): # Handles all our validations
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
