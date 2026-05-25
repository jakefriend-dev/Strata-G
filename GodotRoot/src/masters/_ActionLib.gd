extends Node

var tween: Tween
var trans: int = Tween.TRANS_QUINT

var min_dur: float = 0.10 # In theory, only relevant for enemies, not the player
var std_dur: float = 0.25

var curr_actor: Actor
var action_queue: Array = []

var noted_coord_A: Vector2 = Vector2(-99, -99) # Used for things like 'move continuously *until*...'

signal action_step_complete() # Should fire any time we do an individual action OR each step in a multi-step action -
signal all_action_steps_complete() # Should fire whenever ALL steps are done

var field: Node2D # Owner of all battle stuff
var actors: YSort
var board: GridContainer # Owner of CELLS not everything

var actionlog: Array = [] # Log of all processed AND FAILED actions!
var log_retention: int = 10

# ---

func _ready():
	tween = Tween.new()
	add_child(tween)
	pass

# PROCESSING ---------------------------------------------------------------------------------------

func step_signal():
	emit_signal("action_step_complete")
	process_action_queue()
	pass

func flush(): # Run to wipe any stored-between-actions data
	curr_actor = null
	noted_coord_A = Vector2(-99, -99)
	pass

func start_action_queue(actor: Actor):
	flush()
	curr_actor = actor
	process_action_queue()
	pass

func process_action_queue():
	if action_queue.empty():
		print("ACT: action_queue has emptied!")
		emit_signal("all_action_steps_complete")
		return
	
#	print("ACT: process_action_queue() when queue is: ",action_queue)
	
	var queued_data = action_queue[0]
	action_queue.remove(0)
	
	if not queued_data is Array:
		skip_processing_action("The next action isn't an array")
		return
	
	var this_action: Array = queued_data
	
	if this_action.size() < 2:
		skip_processing_action("The next action isn't large enough for min. details")
		return
	if not this_action[0] is Actor:
		skip_processing_action("The next action doesn't have a valid actor (class)")
		return
	if not this_action[1] is String:
		skip_processing_action("The next action doesn't have a valid action string (class)")
		return
	
	# Set up basic details
	var actor: Actor = this_action[0]
	var action: String = this_action[1]
	var deets: Dictionary = {}
	if this_action.size() > 2:
		if this_action[2] is Dictionary:
			deets = this_action[2]
	# While flags aren't MANDATORY, it's easier to expect them and validate up front
	var flags: Array = []
	if deets.has("flags"):
		if deets["flags"] is Array:
			for flag in deets["flags"]:
				if flag is String:
					flags.append(flag)
				else:
					print("ACT: Ignoring flag [",flag,"] because it is not a string (and needs to be)")
	
	if action == "move":
		if !deets.has("motion"):
			skip_processing_action("No motion sent to move")
			return
		if not deets["motion"] is Vector2:
			skip_processing_action("Motion for move is not a vector")
			return
		
		var motion: Vector2 = deets["motion"]
		var continuous: bool = flags.has("continuous")
		var note_starting: bool = flags.has("note_starting")
		var ignore_tile_faction: bool = flags.has("ignore_tile_faction")
		if !attempt_move_actor(actor, motion, continuous, note_starting, ignore_tile_faction):
			skip_processing_action()
			update_action_log(this_action, false)
			return
		update_action_log(this_action, true)
		if continuous:
			# Re-fire any valid continuous move!
			var repeating_action: Array = this_action
			if note_starting:
				flags.erase("note_starting")
				deets["flags"] = flags
				repeating_action[2] = deets
#			print("About to log repeating action: ",repeating_action)
			action_queue.insert(0, repeating_action)
		pass
	#End Move
	
	elif action == "attack":
		# Validations for datatypes
		if !deets.has("relative_targets") and !deets.has("exact_targets"):
			skip_processing_action("No targets sent to attack")
			return
		if deets.has("relative_targets") and not deets["relative_targets"] is Array:
			skip_processing_action("Relative targets for attack is not an array")
			return
		if deets.has("exact_targets") and not deets["exact_targets"] is Array:
			skip_processing_action("Exact targets for attack is not an array")
			return
		
		# Validations for attacks
		var valid_exact_targets: Array = []
		
		if deets.has("relative_targets"):
			for reltarget in deets["relative_targets"]:
				if not reltarget is Vector2:
					print("Skipping invalid relative-target [",reltarget,"] for attack, not a Vec2")
					continue
				var target: Vector2 = actor.coord + reltarget
				if valid_exact_targets.has(target): # No duplicates!
					continue
				valid_exact_targets.append(target)
		
		if deets.has("exact_targets"):
			for target in deets["exact_targets"]:
				if not target is Vector2:
					print("Skipping invalid exact-target [",target,"] for attack")
					continue
				if valid_exact_targets.has(target): # No duplicates!
					continue
				valid_exact_targets.append(target)
		
		deets["exact_targets"] = valid_exact_targets
		print("Potential attack targets are: ",valid_exact_targets)
		
		var skip_if_no_target: bool = flags.has("skip_if_no_target")
		if skip_if_no_target:
			var any_target_found: bool = false
			for target in deets["exact_targets"]:
				if turn.grid_actors.has_cellv(target):
					if turn.grid_actors.get_cellv(target) != null:
						if flags.has("friendly_fire"):
							any_target_found = true
						elif turn.grid_actors.get_cellv(target).faction != actor.faction:
							any_target_found = true
			if !any_target_found:
				skip_processing_action("No targets found for attack when having targets is mandatory; legit skip")
				update_action_log(this_action, false)
				return
			# [PUT THE ACTUAL ATTACK ATTEMPT HERE]
			print("A target was found, damage would be done if damage was implemented")
			# Maybe move the validity check too
			update_action_log(this_action, true)
			step_signal()
		else:
			# [PUT THE ACTUAL ATTACK ATTEMPT HERE]
			# Maybe move the validity check too
			update_action_log(this_action, true)
			step_signal()
			pass
		pass
	#End Attack
	
	else:
		skip_processing_action("Action ["+action+"] is not valid")
		return
	
	# Successful process!
	pass

func skip_processing_action(error_reason: String = ""):
	if error_reason != "":
		print("ACT: process_action_queue() skipping action because: "+error_reason)
	process_action_queue()
	pass

func update_action_log(action: Array, passfail: bool):
	if actionlog.size() >= log_retention:
		var _oldest_log = actionlog.pop_front()
	
#	var new_entry: String = ""
#	if passfail:
#		new_entry += "[+PASS+]"
#	else:
#		new_entry += "[-FAIL-]"
#	new_entry += " "
#	new_entry += str(action)
	
	var new_entry: Array = [passfail, action]
	
	actionlog.append(new_entry)
	pass

# TURN-RELATED MASTERS -----------------------------------------------------------------------------

func skip_turn(actor: Actor):
	start_action_queue(actor)
	pass

# PLAYER SHORTCUTS ---------------------------------------------------------------------------------

func quick_player_move(actor: Actor, motion: Vector2, continuous: bool = false):
	prep_normal_move(actor, motion, continuous)
	start_action_queue(actor)
	pass

# MOVE (ORTHAGONAL/ADJACENT) -----------------------------------------------------------------------

func prep_normal_move(
	actor: Actor,
	motion: Vector2,
	continuous: bool = false,
	note_starting_coord: bool = false,
	allowed_to_cross_faction_lines: bool = false
	):
		var action: Array = [actor, "move"]
		var deets: Dictionary = {"motion": motion, "flags": []}
		if continuous:
			deets["flags"].append("continuous")
		if note_starting_coord:
			deets["flags"].append("note_starting") # This marks it, typically so you can continuous move back to it
		if allowed_to_cross_faction_lines:
			deets["flags"].append("ignore_tile_faction")
		action.append(deets)
		
		action_queue.append(action)
		pass

func prep_random_move_actor(actor, continuous: bool = false, note_starting_coord: bool = false):
	var action: Array = [actor, "move"]
	var motion: Vector2 = get_rand_adj_tile_for_actormoving(actor.coord, actor)
	motion -= actor.coord # Make it relative!
	var deets: Dictionary = {"motion": motion, "flags": []}
	if continuous:
		deets["flags"].append("continuous")
	if note_starting_coord:
		deets["flags"].append("note_starting")
	action.append(deets)
	
	action_queue.append(action)
	pass

func attempt_move_actor(actor: Actor, motion: Vector2, continuous: bool = false, note_starting_coord: bool = false, ignore_tile_faction: bool = false) -> bool:
	if note_starting_coord:
		noted_coord_A = curr_actor.coord
		print("Noting coord: ",noted_coord_A)
	
	# If we've been told to stop, stop!
	if continuous and !note_starting_coord:
		if curr_actor.coord == noted_coord_A:
			print("ACT: Ceasing continuous motion because we've arrived at the stop target!")
			noted_coord_A = Vector2(-99, -99)
			return false
	
	# If no move remaining, ignore!
	# MISSING
	
	# If unable to move, ignore!
	if !can_move_relative_vector(actor, motion, ignore_tile_faction):
		print("ACT: Cannot move ",actor.ofc_name," to ",actor.coord + motion)
		return false
	
	# Otherwise, move!
	do_move_actor(actor, motion, continuous)
	return true
	pass

func do_move_actor(actor: Actor, motion: Vector2, continuous: bool = false): # Assumes you have ALREADY done the validation!
	var old_coord: Vector2 = actor.coord
	var new_coord: Vector2 = old_coord + motion
	actor.coord = new_coord
	turn.grid_actors.set_cellv(old_coord, null)
	turn.grid_actors.set_cellv(new_coord, actor)
	var new_gpos: Vector2 = turn.grid_gpos.get_cellv(new_coord)
	
	print("Moved actor ",actor.ofc_name," to new coord ",new_coord)
	
	tween.interpolate_property(actor, "position", null, new_gpos, std_dur, trans, Tween.EASE_OUT)
	tween.start()
	
	yield(utils.yt(min_dur, self), "unwait")
	
	if continuous:
		# SCRUBBED: Continuous movement is now handled at processing by reinserting the SAME action back into the stack, as the only way to ensure all parameters of the first move are carried forward. That said, this param still has to be sent here so that if continuous motion is already accounted for, it isn't double-accounted for by ice.
####		# Different because it CONTINUES TO BE CONTINUOUS
####		action_queue.insert(0, [actor, "move", {"motion": motion, "flags": ["continuous"]}])
		pass
	elif turn.grid_tiles.get_cellv(new_coord) == turn.tiletypes.ICE:
		# Different because it is only ONE additional slip
		action_queue.insert(0, [actor, "move", {"motion": motion}])
	step_signal()
	pass

# ATTACKS ------------------------------------------------------------------------------------------

func prep_simple_attack(actor: Actor, perform_if_targetless: bool, allow_friendly_fire: bool):
	var action: Array = [actor, "attack"]
	
	var relative_target: Vector2
	if actor.is_facing_left: relative_target = Vector2.LEFT
	else: relative_target = Vector2.RIGHT
	
	var deets: Dictionary = {"relative_targets": [relative_target], "flags": []}
	if !perform_if_targetless:
		deets["flags"].append("skip_if_no_target")
	if allow_friendly_fire:
		deets["flags"].append("friendly_fire")
	action.append(deets)
	
	action_queue.append(action)
	pass

# SUPPORT QUERIES ----------------------------------------------------------------------------------

func vet_move_targetset(actor: Actor, og_options: Array, is_relative: bool = true, allowed_over_faction_lines: bool = false) -> Array:
	var valid_options: Array = []
	
	# We don't want to CHANGE the coord to be exact if relative, because they need to return the same way they were sent!
	for coord in og_options: if coord is Vector2:
		if is_relative:
			if can_move_relative_vector(actor, coord, allowed_over_faction_lines):
				valid_options.append(coord)
		else:
			if can_move_exact_vector(actor, coord, allowed_over_faction_lines):
				valid_options.append(coord)
	
	return valid_options
	pass

func can_move_relative_vector(actor: Actor, motion: Vector2, allowed_over_faction_lines: bool = false) -> bool:
	return can_move_exact_vector(actor, actor.coord + motion, allowed_over_faction_lines)
	
func can_move_exact_vector(actor: Actor, target: Vector2, allowed_over_faction_lines: bool = false) -> bool:
	var _start_coord: Vector2 = actor.coord
	var end_coord: Vector2 = target
	
	# Can't move off the grid
	if !turn.grid_tiles.has_cellv(end_coord):
		print("ACT: cmev[1] Cell does not exist on board!")
		return false
		
	# Can't move into *any* other actors, period
	if turn.grid_actors.get_cellv(end_coord) != null:
		print("ACT: cmev[2] Actor occupies destination!")
		return false
	
	# Can't move on to other factions' cells
		# (unless you're neutral? or a non-enemy like a missile?)
		# Maybe make missiles etc Neutral to represent 'friendly fire'
	if !allowed_over_faction_lines:
		if actor.faction == turn.factions.PLAYER:
			if turn.grid_factions.get_cellv(end_coord) != turn.factions.PLAYER:
				print("ACT: cmev[3a] Player cannot exit player faction area!")
				return false
		if actor.faction == turn.factions.ENEMY:
			if turn.grid_factions.get_cellv(end_coord) != turn.factions.ENEMY:
				print("ACT: cmev[3b] Enemy cannot exit enemy faction area!")
				return false
		
	
	# Can only move on pits IF you can hover
	if turn.grid_tiles.get_cellv(end_coord) == turn.tiletypes.PIT:
		if !actor.is_hovering:
			print("ACT: cmev[4] Dest is pit but actor can't hover!")
			return false
	
	return true
	pass

func find_first_PC_in_dir(og_coord: Vector2, dir: Vector2) -> Actor:
	var result: Actor = find_first_actor_in_dir(og_coord, dir)
	if result != null:
		if result.faction == turn.factions.PLAYER:
			return result
		
	return null
	pass

func find_first_ENEMY_in_dir(og_coord: Vector2, dir: Vector2) -> Actor:
	var result: Actor = find_first_actor_in_dir(og_coord, dir)
	if result != null:
		if result.faction == turn.factions.ENEMY:
			return result
		
	return null
	pass

func find_first_actor_in_dir(og_coord: Vector2, dir: Vector2) -> Actor:
	var check_coord: Vector2 = og_coord
	
	while true:
		check_coord += dir
		if !turn.grid_actors.has_cellv(check_coord):
			break
		var occupant: Actor = turn.grid_actors.get_cellv(check_coord)
		if occupant != null:
			return occupant
	
	return null
	pass

func get_first_actor_by_name(nstring: String, must_be_alive: bool = true) -> Actor:
	for a in actors.get_children(): if a is Actor:
		if a.ofc_name == nstring:
			if must_be_alive:
				if a.hp > 0:
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
		if !turn.grid_tiles.has_cellv(og_tile + adj):
			opts.erase(adj)
	
	# Means it should fail if it's already occupied
	if relevant_actor != null:
		for dir in opts.duplicate():
			if !can_move_relative_vector(relevant_actor, dir):
				opts.erase(dir)
	
	# We don't bother with this if there's a relevant actor, because the necessary check gets handled there
	elif occupation_check:
		for dir in opts.duplicate():
			var checkcoord: Vector2 = og_tile + dir
			if !turn.grid_actors.get_cellv(checkcoord) == null:
				opts.erase(dir)
	
	# Sending the OG tile is the failure fallback
	if opts.empty():
		print("ACT: Could not find a valid random adjacent tile for ",og_tile,", returning OG!")
		return og_tile
	
	opts.shuffle()
	return og_tile + opts[0]
	pass




