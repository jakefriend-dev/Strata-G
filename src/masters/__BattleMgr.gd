extends Node

const USE_ACTION_CRACKING: bool = true # Disable or enable functionality

var default_halfboard_size: Vector2 = Vector2(3, 5)
const DETERMINISTIC: bool = false # When true, randomness is not initiated
const CELL_SIZE: Vector2 = Vector2(64.0, 48.0)
const CELL_ROW_OFFSET: float = 24.0 # Each column southward moves +offset X position
const CELL_CENTER_OFFSET: Vector2 = Vector2(44.0, 24.0) # Any top-left cell corner + this = centerPOS
const BOARD_CENTERPOINT: Vector2 = Vector2(320.0, 236.0)
const TRAVEL_MARGIN: Vector2 = Vector2(8, 6) # Used for measuring 'when' an actor officially changes coordinates
var board_topleft: Vector2 # Used as a reference for where cell 1, 1 begins (top-left)

enum { # Combat states
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

var curr_actor: Actor = null # Whichever player OR enemy char whose turn it is
var acting_actor: Actor = null # Whichever player OR enemy char whose ACTION STEP it currently is
var curr_turndata: Dictionary = {} # The more complex packet that includes the actor itself, plus other references from initiative rolling
var round_count: int = 0 # per entire cycle of turns
var total_turns_taken: int = 0
var unique_actornames_observed: Dictionary = {} # So if an enemy spawns 3 rockets, then they all die, the next one would be Rocket_4 forever, and the turnqueue would still know Rocket_2 died

# For player actors only!
var loaded_moveset: Array = []
var loaded_move: MoveAction = null
var loaded_m_index: int = 0 # The position we're "at" within the moveset list
var loaded_variant: Vector2 = Vector2.ZERO

# For move selection
var moveselcol: int = 0 # 0-based; up to 1
var moveselrow: int = 0 # 0-based; up to 3

signal action_option_view_changed(move_is_newly_selected_bool)
signal new_action_preview_data_readied(MPD)

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
var living_actors: Array = [] # DOES count things like rocks that have no turns, since they have health
var slain_actors: Array = [] # When turndata is deleted from turnqueue it goes here, to track things like XP and to keep turnqueue clear for living turntakers only.

var ghost_actors: Array = []
var grid_actors:   Array2D	# Initially this TEMPORARILY populates string names,
							# then is written over as actual instances. Note that this
							# IGNORES ghost actors, and REACTS to actor position changes
							# rather than having to be manually set.
var grid_claims:   Array2D
var grid_tiles:    Array2D
var grid_gpos:     Array2D
var grid_rects:    Array2D
var grid_factions: Array2D
var targeted_tiles: Array = [] # Just a list of Vector2 coords

var default_party: Array = ["Knight", "Bard", "Mage"] # Calls these scenes by name when initializing combat; the first one is always in the front and the last is always in the back.

signal set_up_board()
#signal populate_gpos_data()
signal populate_actors()
signal update_all_tiletypes()
signal pre_turn_setup(actor)
signal new_round_started()
signal on_turn_ended_naturally()
signal on_turn_ended_via_interruption()
signal on_turn_exited()
signal targeted_tiles_updated()
signal update_all_preview_drawing()

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
signal any_actionstep_initiated()
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
var drawer: Node2D # Owner of all action preview drawing
var actors: YSort
var board: Node2D # Owner of CELLS not everything

# Tile types refer to the GROUND, not any effect on that coordinate (such as oil).
enum tiletypes {
	# BASIC TYPES -------------------------------------------
	
	NORMAL, 	#
	
	PIT,    	# Can't be walked into naturally; like a wall without blocking projectiles or LOS
					# (not sure we're using it but it's referenced in the code
					# so we may as well leave it be)
	
	MAGIC,		# Unbreakable & unchangeable
					# Magic attacks (inc elemental damage?) cast on it do +1 damage
	
	MAGNET,		# Actors adjacent to this block are pulled onto it when resting
					# Themed as 'lodestone'!
					# Ignored if ON a magnet, adjacent to MULTIPLE magnet, or occupied
					# Essentially, "1 free adjacent magnet" is when it works
	
	# TAG-MATCHED TYPES --------------------------------------
	
	ICE,    	# Any movement direction that isn't a 'jump' causes continued sliding
	
	HOT,	   	# 1 damage to END turn on this tile; +1 AP to START to on this tile
	
	SHRUB		# -1 AP on entering (unless immune), but inbound damage lowered while on tile
	
	TRENCH,		# Provides 'cover,' so to speak, at the cost of some movement
					# Line of sight affected (can't shoot on angle up/down)
					# Free to enter, 1AP to leave
					# Much more complex than the others so maybe we ignore for now!!
	
	WIND_TUNNEL,# Moves you (physically, not as force) 1 tile in a specific direction
					# when RESTED on (like a conveyor belt)
	
	STATIC,		# Your next action must be a REST (or ending your turn) to discharge movement.
					# Repaired on discharge.
	
	POISON, 	# Poison damage ticks on rest
	
	JAGGED,  	# Sharp and jagged; causes damage and AP loss when stepped on
					# Stepping on and 'triggering' the tile repairs it to Normal
	
	BLOOD,		# Can be consumed for special Blood Magic effects
	
	GLOWING,	# Heal at end of turn, but receive extra damage while on tile
					# (Because you're more visible)
	
	
	
	# NOT SURE ABOUT COMMITTING TO THESE
	
	RUNIC,		# I'm not sure about this one but... Can be used to trigger effects remotely, such as "damage all units on runic tiles" or even "adjacent to runic tiles"
					# Or perhaps: "Any damage/effect performed to someone on an enchanted tile also happens to any/everyone else on an enchanted tile? Quite situational though, and it means 1 is kind of meaningless
					# As simple as "receive double damage all the time" or something?
	
	SAND,		# Lose 1 AP on entry; it's just hard to walk on
	
	MUD,    	# The tile 'sinks' immediately and slow everyone down; lightweights treat as sand

#	GRASS,		# Fire damage is doubled, which also destroys the grass
	
#	WATER,  	# The tile 'sinks' and slows non-swimmers. Lightweights do NOT have immunity
	

	BOGROT,		# Poison and mud combined; poison only counts if you are sunk into the tile
	
	# LILYPAD: A type of water that can break into 'real' water tiles
	
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
		
		"1": # Manual battle 1
			init_new_combat({
				"halfboard_size": Vector2(3, 3),
				"npc_positions": [
					[5, 2, "Beast"],
#					[6, 2, "Beast"],
#					[6, 4, "Beast"],
					[4, 1, "Rock"],
				],
				"tile_exceptions": {
					Vector2(3, 3): tiletypes.MAGIC,
					Vector2(2, 1): tiletypes.HOT,
					Vector2(4, 3): tiletypes.HOT,
#					Vector2(2, 4): tiletypes.POISON,
				},
			})
		
		"2": # Manual battle 2
			init_new_combat({
				"halfboard_size": Vector2(4, 4),
				"npc_positions": [
					[5, 1, "Thrower"],
					[8, 1, "Doggo"],
					[8, 2, "Thrower"],
					[6, 3, "Rock"],
				],
			})
		
		"3": # Randomizer!
			set_up_random_combat()
	
#	print("BATMAN: test_new_combat(",test,") succeeded!")
	pass

func set_up_random_combat():
	var new_battle_details: Dictionary
	if !DETERMINISTIC: randomize()
	
	
	
	# Determine a random halfboard size
	var boardwidth: Array = [3, 4]
	var boardheight: Array = [3, 4, 5]
	boardwidth.shuffle()
	var size_x: int = boardwidth[0]
	if size_x == 3: boardheight.erase(3)
	boardheight.shuffle()
	var size_y: int = boardheight[0]
	var halfboard: Vector2 = Vector2(size_x, size_y)
	new_battle_details["halfboard_size"] = halfboard
	
	
	
	# Set up temp-board Array2Ds for the purpose of non-overlapping placement
	var tb_players: Array2D = Array2D.new()
	tb_players.resize(size_x, size_y)
	tb_players.onebased = true
	var tb_enemies: Array2D = Array2D.new()
	tb_enemies.resize(size_x, size_y)
	tb_enemies.onebased = true
	var tb_overall: Array2D = Array2D.new()
	tb_overall.resize(size_x*2, size_y)
	tb_overall.onebased = true
	
	# Randomly place PCs
	var pc_array: Array = []
	# X positions for all first
	var bard_x: int = utils.randi_bw(1, size_x)
	var tank_options: Array = [size_x, size_x - 1]
	tank_options.shuffle()
	var tank_x: int = tank_options[0]
	var mage_options: Array = [1, 2]
	mage_options.shuffle()
	var mage_x: int = mage_options[0]
	# Then Y positions
	var bard_y: int = utils.randi_bw(1, size_y)
	tank_options = utils.array_from_intmin_to_intmax(1, size_y)
	if tank_x == bard_x: if tank_options.has(bard_y): # Tank must consider bard...
		tank_options.erase(bard_y)
	tank_options.shuffle()
	var tank_y: int = tank_options[0]
	mage_options = utils.array_from_intmin_to_intmax(1, size_y)
	if mage_x == bard_x: if mage_options.has(bard_y): # Mage must consider bard...
		mage_options.erase(bard_y)
	if mage_x == tank_x: if mage_options.has(tank_y): # ...AND tank...
		mage_options.erase(tank_y)
	mage_options.shuffle()
	var mage_y: int = mage_options[0]
	# Then set (may need to reconsider this format)
	pc_array.append([bard_x, bard_y, "Bard"])
	pc_array.append([tank_x, tank_y, "Knight"])
	pc_array.append([mage_x, mage_y, "Mage"])
	tb_players.set_cell(bard_x, bard_y, "Bard")
	tb_players.set_cell(tank_x, tank_y, "Knight")
	tb_players.set_cell(mage_x, mage_y, "Mage")
	tb_overall.set_cell(bard_x, bard_y, "Bard")
	tb_overall.set_cell(tank_x, tank_y, "Knight")
	tb_overall.set_cell(mage_x, mage_y, "Mage")
	
	
	
	# Determine a 'spending cost' for this board's level of challenge
	var budget: int = size_x * size_y # Anywhere from 12 to 30
	# This is allowed to drop below 0; we'll just stop being able to 'buy' things then
	var npc_positions: Array = []
	
	
	
	# Now generate enemies
	var enemy_min: int = 2
	var enemy_max: int = int(budget/3)
	var enemy_upper_limit: int = 6
	if enemy_max > enemy_upper_limit:
		enemy_max = enemy_upper_limit
	var enemy_quota: int = utils.randi_bw(enemy_min, enemy_max)
	
	var unplaced_enemies: Array = []
	var enemy_values: Dictionary = {
		"Thrower": 2,
		"Doggo": 3,
		"Beast": 8,
	}
	var enemy_options: Array = enemy_values.keys()
	while enemy_quota > 0:
		enemy_options.shuffle()
		var enemy_name: String = enemy_options[0]
		budget -= enemy_values[enemy_name]
		unplaced_enemies.append(enemy_name)
		enemy_quota -= 1
	while !unplaced_enemies.empty():
		var x: int = utils.randi_bw(1, size_x)
		var y: int = utils.randi_bw(1, size_y)
		if tb_enemies.get_cell(x, y) != null: continue
		var this_enemy_name: String = unplaced_enemies.pop_front()
		tb_enemies.set_cell(x, y, this_enemy_name)
		tb_overall.set_cell(x+size_x, y, this_enemy_name)
		npc_positions.append([x+size_x, y, this_enemy_name])
	
	
	
	# Now place obstacles
	# Add a few rocks at random
	while budget > 5:
		if utils.coin_flip(): break
		budget -= 2
		var x: int = utils.randi_bw(1, size_x*2)
		var y: int = utils.randi_bw(1, size_y)
		if tb_overall.get_cell(x, y) != null: continue
		npc_positions.append([x, y, "Rock"])
	
	
	
	# Now place tiletypes (avoiding detrimental ones directly underneath anyone not immune to that type)
	
	# Okay, think we're good!
	new_battle_details["pc_positions"] = pc_array
	new_battle_details["npc_positions"] = npc_positions
	init_new_combat(new_battle_details)
	pass

func init_new_combat(new_battle_details: Dictionary):
	if !DETERMINISTIC: randomize()
	
	print("---\nBATMAN: Initializing new combat!")
	combatstate = C_BATTLE_SETUP
	flush_all_combat_details()
	
	battle_details = new_battle_details
	load_battle_details()
	math_out_board_gpos_cells()
	
	load_battle_field()
	
	roll_initiative()
	perform_local_pre_combat_setup()
	
	# This ACTUALLY STARTS the fight!
	cycle_to_next_turn() 
	
#	print("BATMAN: GPos data is:",grid_gpos)
	pass

func flush_all_combat_details():
	curr_actor = null
	acting_actor = null
	curr_turndata.clear()
	turnqueue.clear()
	battle_details = {}
	flush_actionqueue(false)
	living_actors.clear()
	slain_actors.clear()
	ghost_actors.clear()
	round_count = 0
	total_turns_taken = 0
	unique_actornames_observed.clear()
	turncount = 0
	loaded_moveset.clear()
	loaded_move = null
	loaded_m_index = 0
	loaded_variant = Vector2.ZERO
	targeted_tiles.clear()
	
	last_execution_frame = -1
	action_queue.clear()
	curr_action.clear()
	prev_action.clear()
	actions_are_processing = false
	action_processing_time = 0.0
	pass

func load_battle_details():
	
	# Non-dealbreaker validations!
	if !battle_details.has("npc_positions"):
#		return false
		print("BATMAN: fyi, battle_details had no NPCs")
		battle_details["npc_positions"] = []
	
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
#	print("local_board_size ",local_board_size)
	
	battle_details["board_size"] = local_board_size
	# Set up all our Array2Ds
	
	for grid in ["grid_tiles", "grid_actors", "grid_gpos", "grid_factions", "grid_claims", "grid_rects"]:
		set(grid, Array2D.new())
		get(grid).resizev(local_board_size)
		get(grid).onebased = true
	
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
	
#	print("BATMAN: Grid tiles set as ",grid_tiles)
	
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
	
	# DATA-PLACE PARTY MHOTS
	
	# IF battle details involve custom party starting positions, use those. Otherwise, use defaults.
	var use_custom_pc_positions: bool = false
	if battle_details.has("pc_positions"):
		if battle_details["pc_positions"].size() == 3:
			use_custom_pc_positions = true
			var pc_count: int = 0
			for set in battle_details["pc_positions"]: if set is Array: # It's an array of three-value arrays: [X, Y, name]
				var pc: String = set[2]
				if !grid_actors.has_cell(set[0], set[1]):
					print("BATMAN: Failed to place PC ",pc," because cell ",set[0],", ",set[1]," does not exist")
				if grid_actors.get_cell(set[0], set[1]) == null:
					grid_actors.set_cell(set[0], set[1], pc)
				else:
					print("BATMAN: Failed to place PC ",pc," because cell ",set[0],", ",set[1]," was already occupied")
				pc_count += 1
#			print("BATMAN: Total of ",pc_count," PCs custom-placed")
			pass
	
	if !use_custom_pc_positions:
		# Default is just standing in a row
		# Probably want to un-hardcode this at some point
		grid_actors.set_cell(3, 2, default_party[0])
		grid_actors.set_cell(2, 2, default_party[1])
		grid_actors.set_cell(1, 2, default_party[2])
#		print("BATMAN: 3 PCs default-placed")
	
	# DATA-PLACE ENEMIES (AND KEY OBSTACLES)
	
	var npc_count: int = 0
	var error_count: int = 0
	for set in battle_details["npc_positions"]: if set is Array: # It's an array of three-value arrays: name X and Y
		if grid_actors.get_cell(set[0], set[1]) == null:
			grid_actors.set_cell(set[0], set[1], set[2])
		else:
			print("BATMAN: Failed to place NPC ",set[2]," because cell ",set[0],", ",set[1]," was already occupied")
			error_count += 1
		npc_count += 1
		pass
	
#	print("BATMAN: ",npc_count-error_count," NPCs placed, ",error_count," errors")
#	print("BATMAN: All actors (by name). Results:",grid_actors)
	pass

func math_out_board_gpos_cells():
	var colcount: int = battle_details["board_size"].x
	var rowcount: int = battle_details["board_size"].y
	
	var total_size: Vector2
	total_size.y = CELL_SIZE.y * rowcount
	total_size.x = (CELL_SIZE.x * colcount) + (CELL_ROW_OFFSET * rowcount)
	
#	print("For XY board size ",colcount,":",rowcount,", total_size is ",total_size)
	
	board_topleft = BOARD_CENTERPOINT - (total_size/2.0)
	
# warning-ignore:unused_variable
	var index: int = 0 # 1-based
	var row: int = 0 # 1-based
	for y in rowcount:
		row += 1
		
		var col: int = 0 # 1-based
		for x in colcount:
			index += 1
			col += 1
			
			var coord: Vector2 = Vector2(col, row)
			var zcoord: Vector2 = Vector2(col-1, row-1) # 0based
			var cell_topleft: Vector2 = board_topleft
			cell_topleft += (CELL_SIZE*zcoord)
			cell_topleft.x += (CELL_ROW_OFFSET * (row-1))
			var cell_center: Vector2 = cell_topleft + CELL_CENTER_OFFSET
			
			grid_gpos.set_cellv(coord, cell_center)
			
			var rect: Rect2 = Rect2(cell_topleft + Vector2(12, 0), CELL_SIZE)
			grid_rects.set_cellv(coord, rect)
	pass

func load_battle_field():
	utils.change_master_scene("battlefield")
	emit_signal("set_up_board") # Places BattleCell scenes in BattleField
	emit_signal("populate_actors") # Actually puts the actor scenes on the board
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
			
#			print("BATMAN: Initially appending turndata: ",turndata)
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
	pre_prep_new_turn()
	pass

func pre_prep_new_turn(): # Always occurs after next turntaker identified
	field.update_targeting()
	flush_actionqueue()
	field.update_turn_display()
	
	combatstate = C_PRE_TURN
	emit_signal("pre_turn_setup", curr_actor)
	if utils.valid(curr_actor):
		if curr_actor.has_method("pre_turn_setup"):
			curr_actor.call("pre_turn_setup")
	
	moveselcol = 0
	moveselrow = 0
	field.movewindow.load_movewindow()
	field.movewindow.update_ap()
	
	if curr_actor is ActorPlayer:
		loaded_moveset = curr_actor.moveset.keys()
		loaded_move = field.movewindow.get_loaded_move() # Allowed to return null even when 'scripted' function
		curr_actor.prep_moveset_on_turn_start()
	
	yield(utils.yt(timeout_turn_time, self), "timeout")
	if !is_game_live(): return
	
	combatstate = C_TURN
	emit_signal("action_option_view_changed", true)
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
		if curr_actor is ActorPlayer:
			curr_actor.prep_moveset_on_turn_end()
	
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

func player_input_validation_checks() -> bool:
	if loaded_moveset.empty(): return false
	if not curr_actor is ActorPlayer: return false
	if combatstate != C_TURN: return false
	if !action_queue.empty(): return false
	return true


func change_movewindow_selrow(amount: int):
	if !player_input_validation_checks(): return
	moveselrow += amount
	if moveselrow > 3:
		moveselrow = 0
	elif moveselrow < 0:
		moveselrow = 3
	
	field.movewindow.refresh_all()
	loaded_move = field.movewindow.get_loaded_move() # Allowed to return null even when 'scripted' function
	emit_signal("action_option_view_changed", true)
	
	if loaded_move == null: emit_signal("new_action_preview_data_readied", null)
	pass

func change_movewindow_selcol(amount: int):
	if !player_input_validation_checks(): return
	moveselcol += amount
	if moveselcol > 1:
		moveselcol = 0
	elif moveselcol < 0:
		moveselcol = 1
	
	field.movewindow.refresh_all()
	loaded_move = field.movewindow.get_loaded_move() # Allowed to return null even when 'scripted' function
	emit_signal("action_option_view_changed", true)
	if loaded_move == null: emit_signal("new_action_preview_data_readied", null)
	pass

func assert_player_variant_against_move(move: MoveAction, is_brand_new_move_selected: bool):
	if move.actualized_variants.empty():
		loaded_variant = Vector2.ZERO
		return
	
	# We should only exercise this code WHEN THE MOVE IS FIRST LOADED/CHOSEN, not each preview
	if is_brand_new_move_selected and move.override_global_variant_on_move_load:
		if loaded_variant != move.starting_variant:
#			print("BATMAN: Overwriting loaded_variant to ",loaded_variant)
			pass
		loaded_variant = move.starting_variant
	
	if !move.actualized_variants.has(loaded_variant):
		loaded_variant = move.starting_variant
#		print("BATMAN: Overwriting loaded_variant to ",loaded_variant)
	pass

func attempt_to_change_player_variant(tilt: Vector2, treat_as_exact_override: bool = false):
	if !player_input_validation_checks(): return
	
	# First, figure out what rounded direction we're moving in
	# (Tilt should already be normalized)
	var IB_vec: Vector2 = tilt.round()
	if IB_vec.x == -0: IB_vec.x = 0
	if IB_vec.y == -0: IB_vec.y = 0
#	print("inbound vec: ",IB_vec)
	
	var prior_varvec: Vector2 = loaded_variant
	
	# Then determine if it's possible to take 1 step in that direction FROM our CURRENT variant vec // OR, if we use exact coords, just check if we can use this one
	
	var selection_style: int = loaded_move.selection_style
	if treat_as_exact_override: 
		if selection_style != MoveAction.inputstyles.CYCLE:
			selection_style = MoveAction.inputstyles.EXACT
	
	# EXACT vectors, or some numpad inputs
	if selection_style == MoveAction.inputstyles.EXACT:
		if loaded_move.actualized_variants.has(IB_vec):
			loaded_variant = IB_vec
	
	# CYCLE between possibilities (an Array of 0-to-infinite Vector2s)
	elif selection_style == MoveAction.inputstyles.CYCLE:
		loaded_move.cycle_index += 1
		if loaded_move.cycle_index >= (loaded_move.actualized_variants.size()):
			loaded_move.cycle_index = 0
		
		if !loaded_move.actualized_variants.empty():
			loaded_variant = loaded_move.actualized_variants[loaded_move.cycle_index]
		pass
	
	# RELATIVE vectors (the 'default' and fallback)
	else:
		var exact_vec: Vector2 = loaded_variant + IB_vec
		if loaded_move.actualized_variants.has(exact_vec):
			loaded_variant = exact_vec
		
		# We ALSO want to, ideally, cover a circumstance where we move orthagonally and there's nothing there.
		elif IB_vec.x == 0: # Orthagonal V!
			var vec_else_1: Vector2 = Vector2(-1, IB_vec.y)
			var vec_else_2: Vector2 = Vector2( 1, IB_vec.y)
			if   loaded_move.actualized_variants.has(loaded_variant + vec_else_1):
				loaded_variant += vec_else_1
				print("Fallback V1")
			elif loaded_move.actualized_variants.has(loaded_variant + vec_else_2):
				loaded_variant += vec_else_2
				print("Fallback V2")
			
		elif IB_vec.y == 0: # Orthagonal X!
			var vec_else_1: Vector2 = Vector2(IB_vec.x, -1)
			var vec_else_2: Vector2 = Vector2(IB_vec.x,  1)
			if   loaded_move.actualized_variants.has(loaded_variant + vec_else_1):
				loaded_variant += vec_else_1
				print("Fallback H1")
			elif loaded_move.actualized_variants.has(loaded_variant + vec_else_2):
				loaded_variant += vec_else_2
				print("Fallback H2")
		
		# And then if it's DIAGONAL, we want to also try both orthagonals, prioritizing up/down first
		
		# Ditto um... orthagonal? Or do we fall back on the EXACT VEC case in case of failure?
	
	
	# Then update the current preview, IF a change happened!
	if loaded_variant != prior_varvec:
#		print("CONFIRMED new loaded_variant ",loaded_variant)
		emit_signal("action_option_view_changed", false)
	pass

func cycle_player_variant_forward():
	pass

func cycle_player_variant_backward():
	pass

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
	var player_move_flag: bool = (actor is ActorPlayer && !Actor.global_moves.has(methodname))
	if player_move_flag:
		if !actor.moveset.has(methodname):
			print("BATMAN: vet_action(",action,") failed: ActorPlayer does not have a move called ",methodname," in its moveset!")
			return false
		var move: MoveAction = actor.moveset[methodname]
		if !move.has_method("ACT"):
			print("BATMAN: vet_action(",action,") failed: ActorPlayer's move ",move," does not have ACT() method!")
			return false
	else: # Player walking, or any enemy action
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
	
	# We're actually NOT calling utils.actorpass() here, because it might be useful to let actors do a final "on death" action!
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
	var player_flag: bool = (actor is ActorPlayer)
	
	var raw_methodname: String = curr_action[1]
	var methodname: String = str("ACT_"+raw_methodname)
	var logname: String = raw_methodname
	var paramset: Array = curr_action[2]
	
	# Check that there's a method that can be called!
	var caller = actor
	if player_flag:
		if !Actor.global_moves.has(raw_methodname):
			methodname = "ACT"
			caller = loaded_move
			logname = loaded_move.display_name
	if !caller.has_method(methodname):
		print("MAJOR ERROR! ",actor.ofc_name," (or its move) does not have the called method ",methodname,"()")
		
		pass
	
	# Validation cleared!
	acting_actor = actor # For async ref
	
	# Log the action BEFORE executing
	var logline: String = str("[",actor.ofc_name,"] --> ",logname)
	update_action_log(logline)
	emit_signal("any_actionstep_initiated")
	field.movewindow.refresh_all()
	
	# Execute!
	if paramset.empty():
		caller.call(methodname)
	else:
		# We can't know how many parameters the method is expecting; we have to expect issue upon failure, alas.
		caller.callv(methodname, paramset)
	
	# Great success. It's the actor's job to cue end_action() from here, or for an interruption to step_signal() instead.
	pass

func get_actionstep_method_name():
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
		if utils.actorpass(curr_actor):
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

func flush_actionqueue(also_release_claims: bool = true): # Run to wipe any stored-between-turns data
	if also_release_claims:
		release_most_claims()
	
	acting_actor = null
	action_queue.clear()
	curr_action = []
	prev_action = []
	last_execution_frame = -1
	
	loaded_moveset = []
	loaded_move = null
	loaded_m_index = 0
	loaded_variant = Vector2.ZERO
	emit_signal("action_option_view_changed", false)
	pass

func is_my_action(actor: Actor) -> bool: # Specifically, if this actor is allowed to continue acting!
	
	if !utils.actorpass(actor): return false
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
	strife.end_all_vfx_on_actor(actor)
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
	for actor in living_actors: if actor is Actor: if utils.actorpass(actor):
		if actor.faction == factions.PLAYER:
			results.append(actor)
	return results
	pass

func get_all_current_enemies() -> Array:
	var results: Array = []
	for actor in living_actors: if actor is Actor: if utils.actorpass(actor):
		if actor.faction == factions.ENEMY:
			results.append(actor)
	return results
	pass

func get_all_opposing_actor_units(calling_actor: Actor) -> Array:
	var same_faction: int = calling_actor.faction
	var results: Array = []
	
	for actor in living_actors: if actor is Actor: if utils.actorpass(actor):
		if actor.faction != same_faction:
			if actor.faction != factions.NEUTRAL:
				results.append(actor)
	
	return results

func get_all_allied_actor_units(calling_actor: Actor) -> Array:
	var same_faction: int = calling_actor.faction
	var results: Array = []
	
	for actor in living_actors: if actor is Actor: if utils.actorpass(actor):
		if actor.faction == same_faction:
			results.append(actor)
	
	return results

# ---

# Deprecated because we weren't using it!
#func can_player_input() -> bool:
##	if inputstate != istates.PLAYER_CONTROL:
##		return false
#	if combatstate != C_TURN:
#		return false
#	if curr_actor == null:
#		return false
#	if curr_actor.faction != factions.PLAYER:
#		return false
#
#	return true
#	pass

func get_board_size() -> Vector2:
	if battle_details.has("board_size"):
		return battle_details["board_size"]
	return Vector2.ZERO
func get_halfboard_size() -> Vector2:
	if battle_details.has("halfboard_size"):
		return battle_details["halfboard_size"]
	return Vector2.ZERO

func actorpos_to_tilecoord(actorpos: Vector2) -> Vector2:
	var relpos: Vector2 = actorpos - board_topleft
	var tpos: Vector2
	tpos.y = relpos.y/CELL_SIZE.y
	
	# Every 2 down is 1 across
	# We know relpos is already on the slanted board, so we need to "de-warp" it
	var warp: float = relpos.y/2.0
	var effective_x: float = relpos.x - warp
	tpos.x = effective_x/CELL_SIZE.x
	
	tpos = tpos.floor()
	tpos += Vector2(1, 1) # Always one-based!

	return tpos
	pass


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

func is_game_live() -> bool:
	if combatstate == C_OOC: return false
	if combatstate == C_BATTLE_SETUP: return false
	if combatstate == C_BATTLE_LOST: return false
	if combatstate == C_BATTLE_WON: return false
	return true

