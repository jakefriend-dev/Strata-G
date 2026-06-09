extends Node


var default_halfboard_size: Vector2 = Vector2(3, 5)
const DETERMINISTIC: bool = false # When true, randomness is not initiated

enum {
	C_OOC,			# Out of combat - the turn system is not active, aka between fights
	
	C_BATTLE_SETUP,	# Exists from battle initiation through until first turn selection
	
	C_TRANSITION,	# Choose next turn-actor; upcycle numbers like turn count
	
	C_PRE_TURN,				# Announce turn start, , update shields etc
	C_TURN,					# The turn is 'live' until manually ended or interrupted
								# (self-death, or a win/lose condition)
								# This is the only state in which an actor has agency!
	C_END_TURN_NATURALLY,	# Check any end-of-turn effects, such as the tile being stood on
								# Skippable if interrupted!
	C_POST_TURN,			# The turn is in its wrap-up state
								# Mandatory stuff like action refreshes and data cleanup
	
	C_BATTLE_LOST,			# Only happens once, when player loses!
	C_BATTLE_WON,			# Only happens once, when the player wins!
	
}

var combatstate: int = C_OOC
# TURNSTATE exists to know the GRANDER SCHEME of turns, mainly if it's the player's or enemy's turn, plus some in-between stages

#enum istates {
#	NPT,				# "Not Player's Turn"
#	PC_BOARD,			# Player has tactical control
#	PLAYER_EXECUTE,	# The player's commands are being executed (like animation delays for switching characters, attack anims, etc); first we spend any consumed points, then we perform the action, then we check to see if the char is spent or not (if yes, force-pick the next unspent char, unless all chars are spent, in which case end the player's turn)
#}
#
#var inputstate: int = istates.NPT
var curr_actor: Actor = null # Whichever player OR enemy char whose turn it is
var acting_actor: Actor = null # Whichever player OR enemy char whose ACTION STEP it currently is
var curr_turndata: Dictionary = {} # The more complex packet that includes the actor itself, plus other references from initiative rolling
var round_count: int = 0 # per entire cycle of turns
var total_turns_taken: int = 0
var unique_actornames_observed: Dictionary = {} # So if an enemy spawns 3 rockets, then they all die, the next one would be Rocket_4 forever, and the turnqueue would still know Rocket_2 died

const BASE_HP_FACTOR: int = 4

var turncount: int = 0 # Starts at 1 for first turn and cycles upwards until resetting
var turnqueue: Array = [
	# Full of turndata dictionaries, already sorted in order!
	# Assumes all turntakers are ALIVE
		# actor						Null if no longer relevant, otherwise an Actor
		# init						Float; The original initiative roll (eg. 5.72013)
		# has_finished_turn			Bool that fires once its turn is complete
		# ofc_name					Direct from the actor's ofc_name
		# numerated_name			As "Doggo 1" with a space and all, even if there's only 1
		# numeration				Int; the 1 in Doggo 1
		# turncount_of_this_actor	Int; 1 by default and a boss could have 2 or 3
		# turnpos					Int; managed by batman but 
]
var living_actors: Array = [] # Does not count things like rocks that have no turns
var slain_actors: Array = [] # When turndata is deleted from turnqueue it goes here, to track things like XP and to keep turnqueue clear for living turntakers only.

var ghost_actors: Array = []
var grid_actors:   Array2D	# Initially this TEMPORARILY populates string names,
							# then is written over as actual instances. Note that this
							# IGNORES ghost actors, and REACTS to actor position changes
							# rather than having to be manually set.
var grid_claims:   Array2D
var grid_tiles:    Array2D
var grid_gpos:     Array2D
var grid_factions: Array2D
var targeted_tiles: Array = [] # Just a list of Vector2 coords

var default_party: Array = ["P2", "P1", "P3"] # Calls these scenes by name when initializing combat; the first one is always in the front and the last is always in the back.

signal set_up_board()
signal populate_gpos_data()
signal populate_actors()
signal update_all_tiletypes()
signal pre_turn_setup(actor)
signal new_round_started()
signal on_turn_ended_naturally()
signal on_turn_ended_via_interruption()
signal on_turn_exited()
signal targeted_tiles_updated()

enum factions {
	NEUTRAL,
	PLAYER,
	ENEMY,
}

# ACTION MANAGEMENT
var last_execution_frame: int = -1
var action_queue: Array = []
var curr_action: Array = []
var prev_action: Array = []
var timeout_action_time: float = (3.0/60.0) # How long between skipped actions if time has not passed
var timeout_turn_time: float = (12.0/60.0) # How long between ended turns if time has not passed
signal action_step_complete() # Should fire any time we do an individual action
signal all_action_steps_complete() # Should fire whenever ALL steps are done
var actions_are_processing: bool = false
var action_processing_time: float = 0.0

#var actionlog: Array = [] # Historical log of all processed AND FAILED actions! Strings only
var actionlog: Array = [] # Log of notable actions for on-screen visibility! Strings only
								# NEWEST first!
var log_retention: int = 32
signal action_log_updated()

var battle_details: Dictionary = {}
var field: Node2D # Owner of all battle stuff
var actors: YSort
var board: GridContainer # Owner of CELLS not everything

# Tile types refer to the GROUND, not any effect on that coordinate (such as oil).
enum tiletypes {
	# CORE TYPES
	
	NORMAL, 	#
	
	STEEL,		# Unbreakable; type cannot be changed
	
	PIT,    	# Can't be walked into naturally; like a wall without blocking projectiles or LOS
	
	# COMMITTED SPECIALS
	
	JAGGED,  	# Sharp and jagged; causes damage and AP loss when stepped on (this also repairs it)
	
	ICE,    	# Any movement direction that isn't a 'jump' causes continued sliding
	
	HOT,	   	# It hurts to enter this tile (each time), as fire damage
	
	SAND,		# Actors only sink on it if they END their turn on sand, unless lightweight
					# Perhaps can become mud with water effect
					# If sunk, immune to lightning damage
	
	POISON, 	# Poison damage is only taken if you END your turn here
					# Maybe this should be an effect, not a tile 'type'?
	
	# NOT SURE ABOUT COMMITTING TO THESE
	
	GRASS,		# Fire damage is doubled, which also destroys the grass
	
	MUD,    	# The tile 'sinks' immediately and slow everyone down; lightweights treat as sand
	
	WATER,  	# The tile 'sinks' and slows non-swimmers. Lightweights do NOT have immunity
	
	MAGNET,		# Actors adjacent to this block who are not ALREADY on a magnet are pulled on to it
					# Applied at the end of their turn?
	
	BOGROT,		# Poison and mud combined; poison only counts if you are sunk into the tile
	
	TRENCH,		# Provides 'cover,' so to speak, at the cost of some movement
					# You gain 1 bonus shield by entering it
					# You lose 1 bonus shield by exiting it (and 1 extra AP to climb out)
					# This gives the effect of "slightly protected by cover"
					# Maybe you can 'shoot over' sunk actors...?
	
	#ELEC,   	# 'Static' on the tile hurts when walking on ONCE, but doing so also discharges it
	#				# Also still affects hovering actors?
	#				# Maybe this should be an effect, not a tile 'type'.... yeahhh
	
	# LILYPAD: A type of water that can break into 'real' water tiles
	
	# CONVEYOR: Moves you (physically, not as force) 1 tile
	
	DNU
}
var tt_as_strings: Array = []

# ---

func _ready():
	connect("all_action_steps_complete", self, "prompt_next_turntaker_action")
	tt_as_strings = tiletypes.keys()
	print(tt_as_strings)
	pass

func _process(delta):
	monitor_action_processing_time(delta)
	pass



# BATTLE MANAGEMENT --------------------------------------------------------------------------------

### Battle setup

func test_new_combat(test: String):
	match test:
		"1":
			if !init_new_combat({
				"npc_positions": [
					[4, 3, "Beast"],
#					[6, 2, "Beast"],
#					[6, 4, "Beast"],
					[4, 1, "Rock"],
				],
				"tile_exceptions": {
					Vector2(3, 3): tiletypes.STEEL,
					Vector2(2, 1): tiletypes.HOT,
					Vector2(4, 1): tiletypes.HOT,
					Vector2(2, 4): tiletypes.ICE,
				},
			}):
				print("TURN MGR: test_new_combat(",test,") failed!")
				return
		"2":
			if !init_new_combat({
				"halfboard_size": Vector2(4, 4),
				"npc_positions": [
					[5, 1, "Thrower"],
					[8, 1, "Doggo"],
					[8, 2, "Thrower"],
					[6, 3, "Rock"],
				],
			}):
				return
	print("TURN MGR: test_new_combat(",test,") succeeded!")
	pass

func init_new_combat(new_battle_details: Dictionary) -> bool:
	
	if !DETERMINISTIC: randomize()
	
	# Validations!
	if !new_battle_details.has("npc_positions"): return false
	
	print("---\nTURN MGR: Initializing new combat!")
	curr_actor = null
	curr_turndata.clear()
	
	combatstate = C_BATTLE_SETUP
	battle_details = new_battle_details
	
	# Set up our board size!
	var local_board_size: Vector2 = default_halfboard_size
	
	if battle_details.has("halfboard_size"):
		local_board_size = battle_details["halfboard_size"]
	else:
		battle_details["halfboard_size"] = local_board_size
	local_board_size.x *= 2
	# And quickref
	var w: int = local_board_size.x
	var h: int = local_board_size.y
	
	battle_details["board_size"] = local_board_size
	
	# Set up all our Array2Ds
	for grid in ["grid_tiles", "grid_actors", "grid_gpos", "grid_factions", "grid_claims"]:
		set(grid, Array2D.new())
		get(grid).resizev(local_board_size)
		get(grid).onebased = true
	flush_actionqueue() # Save this until AFTER the claims grid exists
	
	# Set up our tile data!
	var tile_default: int = tiletypes.NORMAL
	if battle_details.has("tile_default"):
		tile_default = battle_details["tile_default"]
		
	var tile_exceptions: Dictionary = {}
	if battle_details.has("tile_exceptions"):
		tile_exceptions = battle_details["tile_exceptions"]
	
	for x in w:
		for y in h:
			var coord: Vector2 = Vector2(x+1, y+1)
			if tile_exceptions.has(coord):
				grid_tiles.set_cellv(coord, tile_exceptions[coord])
			else:
				grid_tiles.set_cellv(coord, tile_default)
	
#	print("TURN: Grid tiles set as ",grid_tiles)
	
	# Set up our faction data (disabling custom factions for now)
	var use_custom_factions: bool = false
	if battle_details.has("custom_factions"):
		use_custom_factions = true
	if use_custom_factions:
		pass
	else: # Defaults; even horizontal division
		for y in h: for x in w:
			if (x < (w/2)):
				grid_factions.set_cell(x+1, y+1, factions.PLAYER)
			else:
				grid_factions.set_cell(x+1, y+1, factions.ENEMY)
	
	# Set up all actors, starting with PCs
	
	# DATA-PLACE PARTY MEMBERS
	
	# IF battle details involve custom party starting positions, use those. Otherwise, use defaults.
	var use_custom_pc_positions: bool = false
	if battle_details.has("pc_positions"):
		if battle_details["pc_positions"].size() == 3:
			use_custom_pc_positions = true
			var pc_count: int = 0
			for set in battle_details["pc_positions"]: if set is Array: # It's an array of two-value arrays, X and Y
				if !grid_actors.has_cell(set[0], set[1]):
					print("TURN MGR: Failed to place PC ",default_party[pc_count]," because cell ",set[0],", ",set[1]," does not exist")
				if grid_actors.get_cell(set[0], set[1]) == null:
					grid_actors.set_cell(set[0], set[1], default_party[pc_count])
				else:
					print("TURN MGR: Failed to place PC ",default_party[pc_count]," because cell ",set[0],", ",set[1]," was already occupied")
				pc_count += 1
			print("TURN MGR: Total of ",pc_count," PCs custom-placed")
	
	if !use_custom_pc_positions:
		# Default is just standing in a row
		# Probably want to un-hardcode this at some point
		grid_actors.set_cell(3, 2, default_party[0])
		grid_actors.set_cell(2, 2, default_party[1])
		grid_actors.set_cell(1, 2, default_party[2])
		print("TURN MGR: 3 PCs default-placed")
	
	# DATA-PLACE ENEMIES (AND KEY OBSTACLES)
	
	var npc_count: int = 0
	var error_count: int = 0
	for set in battle_details["npc_positions"]: if set is Array: # It's an array of three-value arrays: name X and Y
		if grid_actors.get_cell(set[0], set[1]) == null:
			grid_actors.set_cell(set[0], set[1], set[2])
		else:
			print("TURN MGR: Failed to place NPC ",set[2]," because cell ",set[0],", ",set[1]," was already occupied")
			error_count += 1
		npc_count += 1
		pass
	
	print("TURN MGR: ",npc_count-error_count," NPCs placed, ",error_count," errors")
#	print("TURN MGR: All actors (by name). Results:",grid_actors)
	
	emit_signal("set_up_board")
	yield(VisualServer, "frame_post_draw") # Only exists to let Control-based nodes set their actual position data; bypass-able once we're sure values won't change though
	emit_signal("populate_gpos_data")
	emit_signal("populate_actors")
	print("TURN MGR: All actor data matched to nodes. Results:",grid_actors)
	
	roll_initiative()
	perform_local_pre_combat_setup()
	cycle_to_next_turn() # This ACTUALLY STARTS the fight!
	
#	print("TURN: GPos data is:",grid_gpos)
	
	
	
		
	return true
	pass

func roll_initiative():
	turnqueue.clear()
	
	unique_actornames_observed.clear()
	
	var actorset: Array = grid_actors.get_dataset_values_list()
# warning-ignore:unused_variable
	var actorcount: int = 0
	
	for actor in actorset:
		var initset: Array = actor.get_initiative() # Size 0-3; 0 for rocks etc
		if !initset.empty():
			actorcount += 1 # We just don't count rocks
		
		var count_of_type: int = 1
		var n: String = actor.ofc_name
		if !unique_actornames_observed.has(n):
			unique_actornames_observed[n] = 1
		else:
			count_of_type = unique_actornames_observed[n] + 1
			unique_actornames_observed[n] = count_of_type
		var numerated_name: String = str(n," ",count_of_type)
		actor.numerated_name = numerated_name
		
		# Go through each turn PER each actor
		var initcount: int = 0
		for init in initset:
			initcount += 1
			var turndata: Dictionary = {}
			
			turndata["actor"] = actor
			turndata["init"] = init
			turndata["has_finished_turn"] = false
			
			turndata["ofc_name"] = n
			turndata["numerated_name"] = numerated_name
			turndata["numeration"] = count_of_type
			turndata["turncount_of_this_actor"] = initcount # Typically 1, could be 2 or 3 for bosses
			
			turnqueue.append(turndata)
		pass
	
	turnqueue.sort_custom(self, "sort_turnqueue_by_init")
	
	# Now assign an int position, so that we can insert turns "behind" a specific actor for things like missiles later! You know, if we want.
	
	var count: int = 0
	for turndata in turnqueue: if turndata is Dictionary:
		count += 1
		turndata["turnpos"] = count
	
	field.update_turn_display()
	for actor in actors.get_children():
		actor.update_bui()
	
	print("BATMAN: Initiative rolled!")
#	print("BATMAN: Initiative rolled, turnqueue looks like:\n",turnqueue)
	pass

func perform_local_pre_combat_setup():
	for actor in living_actors:
		if actor.has_method("pre_combat_setup"):
			actor.call("pre_combat_setup")
	pass



### Turn management

func cycle_to_next_turn():
	combatstate = C_TRANSITION
	
	var is_new_round: bool = false
	if turncount == 0: # It's our first round
		is_new_round = true
	else:
		clean_up_turnqueue() # Always do this, each new turn after the initial. Remember that this also updates turncount and turnqueue.size()!
		
		if turncount >= turnqueue.size(): # We've concluded this round - we are ALREADY at size before incrementing therefore we will exceed size after incrementing
			is_new_round = true
	
	total_turns_taken += 1 # Happens regardless
	if is_new_round:
		round_count += 1
		turncount = 1
		curr_actor = null
		field.update_targeting()
		emit_signal("new_round_started")
		update_action_log(str("ROUND [",round_count,"] - BEGIN!"))
		yield(utils.yt(0.75, self), "timeout")
	else:
		turncount += 1
	
	var found_next_actor: bool = false
	for turndata in turnqueue:
		if turndata["turnpos"] == turncount:
			found_next_actor = true
			curr_turndata = turndata
			curr_actor = turndata["actor"]
			break
	
	if !found_next_actor:
		print("BATMAN: Failed to find next actor when cycle_to_next_turn()!")
		return
	
	# Final setup! We've cleared validations!
	
#	print("BATMAN: cycle_to_next_turn() = [",get_printable_roundturncount(),": ",get_printable_turntaker_name(curr_turndata),"]")
	
	field.update_targeting()
	flush_actionqueue()
	field.update_turn_display()
	
	combatstate = C_PRE_TURN
	emit_signal("pre_turn_setup", curr_actor)
	if utils.valid(curr_actor):
		if curr_actor.has_method("pre_turn_setup"):
			curr_actor.call("pre_turn_setup")
	
	yield(utils.yt(timeout_turn_time, self), "timeout")
	
	combatstate = C_TURN
	strife.TILE_event_turn_started_on(curr_actor, curr_actor.coord)
	curr_actor.choose_action()
	pass

func end_turn(): # Includes post-turn; assumes NO interruption
	if last_execution_frame == get_tree().get_frame():
		yield(utils.yt(timeout_turn_time, self), "timeout")
	
	combatstate = C_END_TURN_NATURALLY
	emit_signal("on_turn_ended_naturally")
	
	# Do post-turn effects here
	strife.TILE_event_turn_ended_on(curr_actor, curr_actor.coord)
	
	# ^^^
	
	exit_turn()
	pass

func exit_turn(): # IMMEDIATELY ends the turn as an interruption, no post-turn (use for death)
	var turn_exited_via_interruption: bool = (
		bool(combatstate != C_END_TURN_NATURALLY)
		)
	combatstate = C_POST_TURN
	
	if turn_exited_via_interruption:
		emit_signal("on_turn_ended_via_interruption")
	emit_signal("on_turn_exited")
	
	# Wipe out the current actionqueue
	flush_actionqueue()
	
	if utils.valid(curr_actor):
		
		curr_actor.master_post_turn_teardown()
		if curr_actor.has_method("post_turn_teardown"):
			curr_actor.call("post_turn_teardown")
	
	cycle_to_next_turn() # Includes turnqueue cleaning and disabling ongoing behaviour!
	pass

func clean_up_turnqueue(): # Ensures any eg. null actors are removed; refreshes turnpos
	# The simplest way is just to pass everything to a replacement list
	var new_turnqueue: Array = []
	
#	var prev_turncount: int = turncount
#	var prev_actor: Actor = curr_actor
	var prev_turndata: Dictionary = curr_turndata
	var new_turncount: int = turncount
	
	var turnpos: int = 0
	for turndata in turnqueue: if turndata is Dictionary:
		
		var current_flag: bool = (turndata == prev_turndata)
		
		var actor: Actor = turndata["actor"]
		if !utils.valid(actor):
			if current_flag: new_turncount = (turnpos + 1)
			continue
		if !actor.active:
			if current_flag: new_turncount = (turnpos + 1)
			continue
		turnpos += 1
		if current_flag: new_turncount = turnpos
		turndata["turnpos"] = turnpos
		new_turnqueue.append(turndata)
	
	if new_turncount != turncount:
		print("BATMAN: Turncount updated from ",turncount," to ",new_turncount," during clean_up_turnqueue()")
	turncount = new_turncount
	
	turnqueue = []
	turnqueue = new_turnqueue
	pass

func insert_turndata(new_turndata: Dictionary, to_position: int):
	# Everything AT/BEHIND this position has to have its turnpos incremented
	# If we want to insert BEFORE just use the thing-after's position, and if we want to insert AFTER use the thing-before's position -1
	
	# THIS ASSUMES WE ARE OTHERWISE VALIDATED BTW, besides turnpos I mean!
	# Just a safety validation
	new_turndata["turnpos"] = to_position
	
	# First, iterate 
	for existing_turndata in turnqueue:
		if existing_turndata["turnpos"] >= to_position:
			existing_turndata["turnpos"] = existing_turndata["turnpos"]+1
	
	# Next, add the new data
	turnqueue.append(new_turndata)
	
	# Then sort!
	turnqueue.sort_custom(self, "sort_turnqueue_by_turnpos")
	
	# The question now is... do we iterate our turncount?
	# I think if we're inserting BEFORE the current turn we should.
	# So if our turn is 5 before insertion...
		# Inserting at 4 bumps the current turntaker to 6, so turncount should invisibly increment
		# Inserting at 5 does the same
		# Inserting at 6 KEEPS the current turntaker's spot and the new turntaker acts next
	# Therefore we increment if the new number is LOWER OR EQUAL TO the turncount!
	if to_position <= turncount:
		turncount += 1
	
	for actor in actors.get_children():
		actor.update_bui()
	
	pass

func get_first_turndata_by_actor(actor: Actor) -> Dictionary:
	for turndata in turnqueue:
		if turndata["actor"] == actor:
			return turndata
	return {}
	pass

func get_all_turndata_by_actor(actor: Actor) -> Array:
	# Multiple turns means an array!
	var results: Array = []
	for turndata in turnqueue:
		if turndata["actor"] == actor:
			results.append(turndata)
	return results
	pass

func remove_all_turns_of_actor(actor: Actor):
	# The simplest way is just to pass everything to a replacement list
	var new_turnqueue: Array = []
	var prev_turndata: Dictionary = curr_turndata
	var new_turncount: int = turncount
	
	var turnpos: int = 0
	for turndata in turnqueue: if turndata is Dictionary:
		
		var current_flag: bool = (turndata == prev_turndata)
		
		if turndata["actor"] == actor:
			if current_flag: new_turncount = (turnpos + 1)
			continue
		
		turnpos += 1
		if current_flag: new_turncount = turnpos
		turndata["turnpos"] = turnpos
		new_turnqueue.append(turndata)
	
	if new_turncount != turncount:
		print("BATMAN: Turncount updated from ",turncount," to ",new_turncount," during remove_all_turns_of_actor()")
	turncount = new_turncount
	
	turnqueue = []
	turnqueue = new_turnqueue
	pass

func is_my_turn(actor: Actor) -> bool: # Specifically, if this actor is allowed to continue acting!
	if !utils.valid(actor): return false
	if curr_actor != actor: return false
	if !actor.active: return false
	if combatstate != C_TURN: return false
	return true
	pass

func sort_turnqueue_by_init(a: Dictionary, b: Dictionary) -> bool:
	# True if turndata A should act ahead of turndata B
	return a["init"] > b["init"]
	pass

func sort_turnqueue_by_turnpos(a: Dictionary, b: Dictionary) -> bool:
	# True if turndata A should act ahead of turndata B
	return a["turnpos"] > b["turnpos"]
	pass

func get_printable_roundturncount() -> String:
	var text: String = str("r",round_count,".",turncount)
	return text
	pass

func get_printable_turntaker_name(turndata: Dictionary) -> String:
	var name_unnum: String = turndata["ofc_name"]
	var name_num: String = turndata["numerated_name"]
	
	if !unique_actornames_observed.has(name_unnum):
		return name_unnum
	elif unique_actornames_observed[name_unnum] == 1:
		return name_unnum
	
	return name_num
	pass



### Action management

func vet_action(action: Array) -> bool:
	# We expect 2-3 values: A valid actor, a valid method in that actor's script, and *optionally*, an array of param data for the method. The array is allowed to be missing or empty, and can have whatever in it. HOWEVER, in any situation where no paramset is sent, we add an empty array for consistency. A validated action DOES have 3 params.
	
	if action.size() != 2 and action.size() != 3:
		print("BATMAN: vet_action(",action,") failed: Array is the wrong size")
		return false
	
	if not action[0] is Actor:
		print("BATMAN: vet_action(",action,") failed: First param is not an Actor")
		return false
	
	var actor: Actor = action[0]
	
	if actor == null:
		print("BATMAN: vet_action(",action,") failed: Actor is null")
		return false
	
	if !actor.active:
		print("BATMAN: vet_action(",action,") failed: Actor is not active")
		return false
	
	if not action[1] is String:
		print("BATMAN: vet_action(",action,") failed: Second param is not a string (for methodname)")
		return false
	
	var methodname: String = action[1]
	
	if methodname == "":
		print("BATMAN: vet_action(",action,") failed: Method name is blank")
		return false
	
	# Actors need to have the action in their script OR class chain
	if !actor.has_method(str("ACT_"+methodname)):
		print("BATMAN: vet_action(",action,") failed: Actor does not have method in its script or class-chain")
		return false
	
	if action.size() == 3:
		if not action[2] is Array:
			print("BATMAN: vet_action(",action,") failed: Third param is not an Array")
			return false
	
	return true
	pass

func append_action(actor: Actor, methodname: String, paramset: Array = []):
	var action: Array = [actor, methodname, paramset]
	if !vet_action(action):
		return
	
	# Validations complete
	action_queue.append(action)
	pass

func reaction(actor: Actor, methodname: String, paramset: Array = []):
	insert_action(0, actor, methodname, paramset)
	pass

func insert_action(position: int, actor: Actor, methodname: String, paramset: Array = []):
	var action: Array = [actor, methodname, paramset]
	if !vet_action(action):
		return
	
	if position < 0:
		print("BATMAN: Invalid index insert_action(",action,", ",position,"), adjusting up to 0!")
		position = 0
	elif position > action_queue.size():
		print("BATMAN: Invalid index insert_action(",action,", ",position,"), appending instead!")
		append_action(actor, methodname, paramset)
		return
	
	# Validations complete
	action_queue.insert(position, action)
	pass

func progress_action_queue(): # Calls ONE next action, or if there is none, skips
	last_execution_frame = get_tree().get_frame()
	acting_actor = null
	
	if action_queue.empty(): # No actions queued when this was called! Time to move on
		
		if curr_actor.has_method("post_all_action_prep"):
			curr_actor.call("post_all_action_prep")
		
		end_turn()
		return
	
	# Final checks on if the actor is STILL valid, given some delays since vet_action()
	var unvalidated_action: Array = action_queue.pop_front()
	var actor: Actor = unvalidated_action[0]
	if !utils.valid(actor):
		end_action()
		return
	if !actor.active:
		end_action()
		return
	
	# Actor is valid, so action is as well! Update trackers
	prev_action = []
	prev_action = curr_action
	curr_action = []
	curr_action = unvalidated_action
	
	action_processing_time = 0.0
	actions_are_processing = true
	
	# Gather data...
	var raw_methodname: String = curr_action[1]
	var methodname: String = str("ACT_"+raw_methodname)
	var paramset: Array = curr_action[2]
	acting_actor = actor
	if !actor.has_method(methodname):
		print("MAJOR ERROR! A non-player character does not have the called method ",methodname,"()")
		
		pass
	
	# Log the action BEFORE executing
	var logline: String = str("[",actor.ofc_name,"] ",raw_methodname)
	update_action_log(logline)
	
	# Execute!
	if paramset.empty():
		actor.call(methodname)
	else:
		# We can't know how many parameters the method is expecting; we have to expect issue upon failure, alas.
		actor.callv(methodname, paramset)
	
	# Great success. It's the actor's job to cue end_action() from here, or for an interruption to step_signal() instead.
	pass

func update_action_log(new_logline: String):
	actionlog.insert(0, new_logline)
	if actionlog.size() > log_retention:
		actionlog.resize(log_retention)
	
	emit_signal("action_log_updated")
	pass

func monitor_action_processing_time(delta: float):
	if !actions_are_processing: return
	
	action_processing_time += delta
	pass

func prompt_next_turntaker_action():
	if combatstate == C_TURN:
		if utils.valid(curr_actor):
			if curr_actor.alive_check():
				curr_actor.choose_action()
				return
		# Branch where current actor is no longer valid; most likely because it died mid-turn
		end_turn()
	pass

func skip_action(): end_action() # Just a shortcut

func end_action(): # The call that an action 'step' has ended, or needs to be skipped
	if combatstate != C_TURN: return
	
	# The action_step signals here should NEVER fire the same frame this method is called! If so, we need to wait at LEAST 1 frame before proceeding.
	if last_execution_frame == get_tree().get_frame():
		yield(utils.yt(timeout_action_time, self), "timeout")
	
	actions_are_processing = false
#	print("Action processing time logged: ",action_processing_time)
	
	emit_signal("action_step_complete")
	acting_actor = null
	
	if action_queue.empty():
#		print("BATMAN: action_queue has emptied!")
		emit_signal("all_action_steps_complete") # Will try and prompt NPCs to make another move
		return
	
	# Since there are more actions, let's process one!
	progress_action_queue()
	pass

func flush_actionqueue(): # Run to wipe any stored-between-turns data
	release_most_claims()
	
	acting_actor = null
	action_queue.clear()
	curr_action = []
	prev_action = []
	last_execution_frame = -1
	pass

func is_my_action(actor: Actor) -> bool: # Specifically, if this actor is allowed to continue acting!
	
	if !utils.valid(actor): return false
	if !actor.alive_check(): return false
	if acting_actor != actor: return false
	if !actor.active: return false
	if combatstate != C_TURN: return false
	return true
	pass



# TILE TARGETING AND TILETYPES -------------------------------------------------

func update_targeted_tiles():
	targeted_tiles = []
	
	for actor in living_actors: if actor is Actor: if actor.active:
		var local_targeted_tiles: Array = actor.targeted_tiles
		for target in local_targeted_tiles: if target is Vector2:
			if !grid_tiles.has_cellv(target):
				continue # Mini validation
			
			if !targeted_tiles.has(target):
				targeted_tiles.append(target)
	
	emit_signal("targeted_tiles_updated")
	pass



# ---


# -

# Note that this only clears the FIRST previous cell! Also, new_coord is already applied to actor.coord before this method is called
func change_actor_grid_coord(actor: Actor, new_coord: Vector2):
	var occupant: Actor = batman.grid_actors.get_cellv(new_coord)
	if occupant != null:
		print("BATMAN: change_actor_grid_coord(",actor,", ",new_coord,") when OCCUPIED already by ",occupant,"! Error, error, breakpoint!")
		
		pass
	
	var dataset: Array = batman.grid_actors.get_dataset_with_coords()
	var old_coord: Vector2
	for set in dataset:
		if set[0] == actor:
			old_coord = set[1]
			if old_coord == new_coord:
				print("BATMAN: ERROR, tried to change actor grid coord to the same as it was?")
				return false
			
			# This is the normal 'success' condition!
			batman.grid_actors.set_cellv(old_coord, null)
			batman.grid_actors.set_cellv(new_coord, actor)
			return true
	
	if actor.just_exited_ghost_mode: # Allow a bypass if we are newly returning to the grid!
		batman.grid_actors.set_cellv(new_coord, actor)
		return true
	
	print("BATMAN: ERROR, tried to change actor grid coord for actor: ",actor," when it wasn't already on the grid and DIDN'T just exit ghost_mode? old: ",old_coord," and new: ",new_coord)
	
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

func kill_actor(actor: Actor):
	var should_change_turns: bool = (actor == curr_actor)
	
	# Prevent it from executing actions
	actor.active = false
	if actor.is_in_group("actors"):
		actor.remove_from_group("actors")
	if actor.is_in_group("live_actors"):
		actor.remove_from_group("live_actors")
	
	# Clear the actor from the board and all tracking lists
	remove_actor_from_actorgrid(actor)
	if ghost_actors.has(actor):
		ghost_actors.erase(actor)
	if living_actors.has(actor):
		living_actors.erase(actor)
	slain_actors.append(actor.ofc_name) # This can maybe be improved later if enemies have local XP
	
	# Remove the actor from the turnqueue
	remove_all_turns_of_actor(actor)
	field.update_turn_display()
	
	# Wipe its tile claims
	release_actor_claims(actor)
	
	# Clear its targeting data
	actor.release_targeted_tiles()
	
	# Actually delete it! If it has an on-death method, let it do so itself; otherwise we do it
	if actor.has_method("WHEN_killed"):
		actor.call("WHEN_killed")
	else:
		actor.visible = false
		actor.queue_free()
	
	if should_change_turns:
		yield(utils.yt(timeout_action_time, self), "timeout")
		exit_turn()
	pass

func get_all_current_players() -> Array:
	var results: Array = []
	for actor in living_actors: if actor is Actor: if actor.active:
		if actor.faction == factions.PLAYER:
			results.append(actor)
	return results
	pass

func get_all_current_enemies() -> Array:
	var results: Array = []
	for actor in living_actors: if actor is Actor: if actor.active:
		if actor.faction == factions.ENEMY:
			results.append(actor)
	return results
	pass

# ---

func can_player_input() -> bool:
#	if inputstate != istates.PLAYER_CONTROL:
#		return false
	if combatstate != C_TURN:
		return false
	if curr_actor == null:
		return false
	if curr_actor.faction != factions.PLAYER:
		return false
	
	return true
	pass

func get_board_size() -> Vector2:
	if battle_details.has("board_size"):
		return battle_details["board_size"]
	return Vector2.ZERO
func get_halfboard_size() -> Vector2:
	if battle_details.has("halfboard_size"):
		return battle_details["halfboard_size"]
	return Vector2.ZERO

func must_player_turn_be_over() -> bool: # Asked after any player action is executed
	# The turn is auto-over IF all PC characters are spent
	# Spent means: No move or action points remain (or not enough AP to use any valid action), or downed
#	if pc_actors_spent.size() == 3:
#		return true
	return false

func must_battle_be_won() -> bool: # Asked after any enemy is damaged/defeated
#	return foe_actors_defeated.size() == foe_actors.size()
	return false

func must_battle_be_lost() -> bool: # Asked after any PC is damaged/defeated
	return false



