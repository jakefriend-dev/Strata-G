extends Node


var default_halfboard_size: Vector2 = Vector2(3, 5)

enum {
	C_OOC,			# Out of combat - the turn system is not active, aka between fights
	
	C_BATTLE_SETUP,	# Exists from battle initiation through until first turn selection
	
	C_TRANSITION,	# Choose next turn-actor; upcycle numbers like turn count
	
	C_PRE_TURN,		# Announce turn start, , update shields etc
	C_TURN,			# The turn is 'live' until manually ended or interrupted (self-death, or a win/lose condition) - this is the only state in which an actor has agency!
	C_POST_TURN,		# Check any end-of-turn effects, such as the tile being stood on
	
	C_BATTLE_LOST,	# Only happens once, when player loses!
	C_BATTLE_WON,	# Only happens once, when the player wins!
	
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
var curr_actor: Actor = null # Whichever player OR enemy char is current
var curr_turndata: Dictionary = {} # The more complex packet that includes the actor itself, plus other references from initiative rolling
var round_count: int = 0 # per entire cycle of turns
var total_turns_taken: int = 0
var unique_actornames_observed: Dictionary = {} # So if an enemy spawns 3 rockets, then they all die, the next one would be Rocket_4 forever, and the turnqueue would still know Rocket_2 died

const BASE_HP_UNIT: int = 4

var turncount: int = 0 # Starts at 1 for first turn and cycles upwards until resetting
var turnqueue: Array = [
	# Full of turndata dictionaries, already sorted in order!
	# Assumes all turntakers are ALIVE
		# actor						Null if no longer relevant, otherwise an Actor
		# init						Float; The original initiative roll (eg. 5.72013)
		# has_finished_turn			Bool that fires once its turn is complete
		# ofc_name					Direct from the actor's ofc_name
		# numerated_name			As "Doggo 1" with a space and all
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

var default_party: Array = ["P2", "P1", "P3"] # Calls these scenes by name when initializing combat; the first one is always in the front and the last is always in the back.

signal set_up_board()
signal populate_gpos_data()
signal populate_actors()
signal update_all_tiletypes()
signal pre_turn_refresh(actor)

enum factions {
	NEUTRAL,
	PLAYER,
	ENEMY,
}

var battle_details: Dictionary = {}
var field: Node2D # Owner of all battle stuff
var actors: YSort
var board: GridContainer # Owner of CELLS not everything

# Tile types refer to the GROUND, not any effect on that coordinate (such as oil).
enum tiletypes {
	NORMAL, 	#
	
	CRACK,  	# Normal, but creates pit when EXITED
					# Also a cracking effect on an already-cracked tile would create a pit instead
					# Also-also, featherweights don't break the tiles when leaving
	
	PIT,    	# Can't be walked into naturally; CAN be knocked into it for instant KO
	
	STEEL,		# Unbreakable; unchangeable without magic
	
	GRASS,		# Fire damage is doubled, which also destroys the grass
	
	EMBER,   	# It hurts to enter this tile (each time), as fire damage
	
	FLOOD,  	# The tile 'sinks' and slows non-swimmers. Lightweights do NOT have immunity
	
	SAND,		# Actors only sink on it if they END their turn on sand, unless lightweight
					# Perhaps can become mud with water effect
					# If sunk, immune to lightning damage
	
	MUD,    	# The tile 'sinks' immediately and slow everyone down; lightweights treat as sand
	
	ICE,    	# Any movement direction that isn't a 'jump' causes continued sliding
	
	POISON, 	# Poison damage is only taken if you END your turn here
					# Maybe this should be an effect, not a tile 'type'?
	
	MAGNET,		# Actors adjacent to this block who are not ALREADY on a magnet are pulled on to it
					# Applied at the end of their turn?
	
	BOGROT,		# Poison and mud combined; poison only counts if you are sunk into the tile
	
	
	#ELEC,   	# 'Static' on the tile hurts when walking on ONCE, but doing so also discharges it
	#				# Also still affects hovering actors?
	#				# Maybe this should be an effect, not a tile 'type'.... yeahhh
	
	DNU
}

var multi_input_lock: bool = false # Prevent multiple actions being acecpted too closely together
var action_lock: bool = false # On any successful action, even by an enemy, yield until all actions are complete!


# ---


func _process(_d): monitor_inputs()
func monitor_inputs():
	if multi_input_lock: return
#	if action_lock: return
	
	if Input.is_action_just_pressed("dev_1"):
		multi_input_lock = true
		test_new_combat("1")
		return
	if Input.is_action_just_pressed("dev_2"):
		multi_input_lock = true
		test_new_combat("2")
		return
#	if Input.is_action_just_pressed("dev_3"):
#		multi_input_lock = true
#		var doggo: Actor = act.get_first_actor_by_name("Doggo")
#		if doggo == null: return
#		doggo.ready_turn_actions()
#		return
#	if Input.is_action_just_pressed("dev_4"):
#		multi_input_lock = true
#		var beast: Actor = act.get_first_actor_by_name("Beast")
#		if beast == null: return
#		beast.ready_turn_actions()
#		return
	
	if battle_details.empty(): return
#	if !can_player_input(): return
	
	if Input.is_action_just_pressed("player_move_up"):
		multi_input_lock = true
		if act.quick_player_move(curr_actor, Vector2.UP, true):
			action_lock = true
			yield(act, "all_action_steps_complete")
			action_lock = false
		return
	if Input.is_action_just_pressed("player_move_down"):
		multi_input_lock = true
		if act.quick_player_move(curr_actor, Vector2.DOWN, true):
			action_lock = true
			yield(act, "all_action_steps_complete")
			action_lock = false
		return
	if Input.is_action_just_pressed("player_move_left"):
		multi_input_lock = true
		if act.quick_player_move(curr_actor, Vector2.LEFT):
			action_lock = true
			yield(act, "all_action_steps_complete")
			action_lock = false
		return
	if Input.is_action_just_pressed("player_move_right"):
		multi_input_lock = true
		if act.quick_player_move(curr_actor, Vector2.RIGHT):
			action_lock = true
			yield(act, "all_action_steps_complete")
			action_lock = false
		return
	
	if Input.is_action_just_pressed("player_complete"):
		multi_input_lock = true
		cycle_to_next_turn()
		return
	pass

func _physics_process(_delta):
	multi_input_lock = false
	pass

func test_new_combat(test: String):
	match test:
		"1":
			if !init_new_combat({
				"npc_positions": [
					[4, 3, "Beast"],
					[6, 2, "Doggo"],
					[4, 3, "Doggo"],
					[4, 1, "Rock"],
				],
				"tile_exceptions": {
					Vector2(3, 3): 2,
					Vector2(2, 1): 1,
					Vector2(2, 0): 1,
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
	act.flush() # Save this until AFTER the claims grid exists
	
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
	cycle_to_next_turn() # This ACTUALLY STARTS the fight!
	
#	print("TURN: GPos data is:",grid_gpos)
	
	
	
		
	return true
	pass

# TURN MANAGEMENT ----------------------------------------------------------------------------------

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
	
	
	
	turnqueue.sort_custom(self, "sort_turnqueue_by_init")
	
	# Now assign an int position, so that we can insert turns "behind" a specific actor for things like missiles later! You know, if we want.
	
	var count: int = 0
	for turndata in turnqueue: if turndata is Dictionary:
		count += 1
		turndata["turnpos"] = count
	
	print("BATMAN: Initiative rolled!")
#	print("BATMAN: Initiative rolled, turnqueue looks like:\n",turnqueue)
	pass

func end_turn():
	combatstate = C_POST_TURN
	
	# Do post-turn stuff
	
	interrupt_turn()
	pass

func interrupt_turn():
	# Wipe out the current actionqueue
	act.flush()
	if utils.valid(curr_actor):
		if curr_actor.has_method("on_turn_reset"):
			curr_actor.call("on_turn_reset")
	
	cycle_to_next_turn() # Includes turnqueue cleaning and disabling ongoing behaviour!
	pass

func cycle_to_next_turn():
	combatstate = C_TRANSITION
	
	var is_new_round: bool = false
	if turncount == 0: # It's our first round
		is_new_round = true
	else:
		clean_up_turnqueue() # Always do this, each new turn after the initial. Remember that this also updates turncount and turnqueue.size()!
		
		if turncount >= turnqueue.size(): # We've concluded this round - we are ALREADY at size before incrementing therefore we will exceed size after incrementing
			is_new_round = true
	
	if is_new_round:
		round_count += 1
		turncount = 1
	else:
		turncount += 1
	total_turns_taken += 1 # Happens regardless
	
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
	
	# Final setup!
	
	print("BATMAN: cycle_to_next_turn() = [",get_printable_roundturncount(),": ",get_printable_turntaker_name(curr_turndata),"]")
	
	field.update_targeting()
	
	act.flush()
	
	combatstate = C_PRE_TURN
	emit_signal("pre_turn_refresh", curr_actor)
	# Nothin' here yet!
	
	combatstate = C_TURN
	if !curr_actor.has_method("begin_turn"):
#		print("BATMAN: Error! Actor ",curr_actor," doesn't have a begin_turn() method, skipping!")
		yield(utils.yt(0.75, self), "timeout")
		cycle_to_next_turn()
		return
	
	curr_actor.begin_turn()
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

func sort_turnqueue_by_init(a: Dictionary, b: Dictionary) -> bool:
	# True if turndata A should act ahead of turndata B
	return a["init"] > b["init"]
	pass

func sort_turnqueue_by_turnpos(a: Dictionary, b: Dictionary) -> bool:
	# True if turndata A should act ahead of turndata B
	return a["turnpos"] > b["turnpos"]
	pass

# ---

func kill_actor(actor: Actor):
	# Prevent it from executing actions
	actor.active = false
	
	# Clear the actor from the board and all tracking lists
	act.remove_actor_from_actorgrid(actor)
	if ghost_actors.has(actor):
		ghost_actors.erase(actor)
	if living_actors.has(actor):
		living_actors.erase(actor)
	slain_actors.append(actor.ofc_name) # This can maybe be improved later if enemies have local XP
	
	# Remove the actor from the turnqueue
	remove_all_turns_of_actor(actor)
	
	# Wipe its tile claims
	act.release_actor_claims(actor)
	
	# Actually delete it! If it has an on-death method, let it do so itself; otherwise we do it
	if actor.has_method("WHEN_killed"):
		actor.call("WHEN_killed")
	else:
		actor.visible = false
		actor.queue_free()
	pass

# ---

func is_my_turn(actor: Actor) -> bool: # Specifically, if this actor is allowed to continue acting!
	if curr_actor != actor: return false
	if !actor.active: return false
	if combatstate != C_TURN: return false
	return true
	pass

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



