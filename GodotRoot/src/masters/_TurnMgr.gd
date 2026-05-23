extends Node


var HALFBOARD_SIZE: Array = [3, 5]

enum {
	T_OOC,			# Out of combat - the turn system is not active, aka between fights
	
	T_BATTLE_INTRO,	# Only happens once when the battle is won!
	
	T_START,		# Announce turn start, upcycle numbers like turn count, update shields etc
	T_PLAYER_ACT,		# The player choose their actions
	T_PLAYER_END,		# Before the enemy's turn (not sure if/why important)
	T_FOE_ACT,		# Enemies are, in turn, executing their actions
	T_FOE_MOVE,	# Enemies are, in turn, picking a new location to move to
	T_COMPLETE		# After the enemy's turn; if players are alive we loop to TURN_START next
	
	T_BATTLE_LOST,	# Only happens once, when player loses! Generally called by enemy turn
	T_BATTLE_WON,	# Only happens once, when the player wins! Generally called by player turn
}

var turnstate: int = T_OOC
# TURNSTATE exists to know the GRANDER SCHEME of turns, mainly if it's the player's or enemy's turn, plus some in-between stages

enum {
	A_NPT,				# "Not Player's Turn"
	A_PLAYER_CONTROL,		# Player has tactical control
	A_PLAYER_EXECUTE,		# The player's commands are being executed (like animation delays for switching characters, attack anims, etc); first we spend any consumed points, then we perform the action, then we check to see if the char is spent or not (if yes, force-pick the next unspent char, unless all chars are spent, in which case end the player's turn)
}

var actionstate: int = A_NPT
var curr_actor = null # Whichever player OR enemy char is current

var pc_actors: Array = [] # When a PC no longer has move OR AP remaining, it gets added to pc_actors_spent
var pc_actors_spent: Array = [] # Clears at end of each turn

var foe_actors: Array = []
var foe_actors_spent: Array = [] # When an enemy has performed its action(s), it goes in here
var foe_actors_defeated: Array = [] # When an enemy is dead, it goes in here

var default_party: Array = ["P2", "P1", "P3"] # Calls these scenes by name when initializing combat; the first one is always in the front and the last is always in the back.

signal set_up_board()
signal populate_gpos_data()
signal populate_actors()

enum factions {
	NEUTRAL,
	PLAYER,
	ENEMY,
}

var grid_actors:   Array2D	# Initially this TEMPORARILY populates string names,
								# then is written over as actual instances
var grid_tiles:    Array2D
var grid_gpos:     Array2D
var grid_factions: Array2D

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
	
	DNU
	#ELEC,   	# 'Static' on the tile hurts when walking on ONCE, but doing so also discharges it
	#				# Also still affects hovering actors?
	#				# Maybe this should be an effect, not a tile 'type'.... yeahhh
}

var multi_input_lock: bool = false # Prevent multiple actions being acecpted too closely together
var action_lock: bool = false # On any successful action, even by an enemy, yield until all actions are complete!


# ---


func _process(_d): monitor_inputs()
func monitor_inputs():
	if multi_input_lock: return
	if action_lock: return
	
	if Input.is_action_just_pressed("dev_1"):
		multi_input_lock = true
		test_new_combat("1")
		return
	if Input.is_action_just_pressed("dev_2"):
		multi_input_lock = true
		test_new_combat("2")
		return
	if Input.is_action_just_pressed("dev_3"):
		multi_input_lock = true
		var doggo: Actor = act.get_first_actor_by_name("Doggo")
		if doggo == null: return
		doggo.ready_turn_actions()
		return
	
	if battle_details.empty(): return
	
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
		cycle_next_player()
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
					[3, 2, "Beast"],
					[5, 1, "Doggo"],
					[3, 2, "Doggo"],
					[3, 0, "Rock"],
				],
#				"tile_exceptions": {
#					Vector2(3, 3): 2,
#					Vector2(2, 1): 1,
#					Vector2(2, 0): 1,
#				},
			}):
				print("TURN MGR: test_new_combat(",test,") failed!")
				return
		"2":
			if !init_new_combat({
				"halfboard_size": [4, 4],
				"npc_positions": [
					[4, 0, "Thrower"],
					[6, 0, "Doggo"],
					[7, 1, "Thrower"],
					[5, 2, "Rock"],
				],
			}):
				return
	print("TURN MGR: test_new_combat(",test,") succeeded!")
	pass

func init_new_combat(new_battle_details: Dictionary) -> bool:
	curr_actor = null
	pc_actors.clear()
	pc_actors_spent.clear()
	foe_actors.clear()
	foe_actors_defeated.clear()
	foe_actors_spent.clear()
	
	
	# Validations!
	if !new_battle_details.has("npc_positions"): return false
	
	print("---\nTURN MGR: Initializing new combat!")
	battle_details = new_battle_details
	
	# Set up our board size!
	var local_board_size: Array = HALFBOARD_SIZE.duplicate()
	
	if battle_details.has("halfboard_size"):
		local_board_size = battle_details["halfboard_size"]
	else:
		battle_details["halfboard_size"] = local_board_size
	local_board_size[0] = int(local_board_size[0]*2)
	# And quickref
	var w: int = local_board_size[0]
	var h: int = local_board_size[1]
	
	battle_details["board_size"] = local_board_size
	
	# Set up all our Array2Ds
	for grid in ["grid_tiles", "grid_actors", "grid_gpos", "grid_factions"]:
		set(grid, Array2D.new())
		get(grid).resize(local_board_size[0], local_board_size[1])
	
	# Set up our tile data!
	var tile_default: int = tiletypes.NORMAL
	if battle_details.has("tile_default"):
		tile_default = battle_details["tile_default"]
		
	var tile_exceptions: Dictionary = {}
	if battle_details.has("tile_exceptions"):
		tile_exceptions = battle_details["tile_exceptions"]
	
	for x in local_board_size[0]:
		for y in local_board_size[1]:
			var coord: Vector2 = Vector2(x, y)
			if tile_exceptions.has(coord):
				grid_tiles.set_cellv(coord, tile_exceptions[coord])
			else:
				grid_tiles.set_cellv(coord, tile_default)
	
#	print("TURN: Grid tiles set as ",grid_tiles)
	
	# Set up our faction data (disabling custom factions for now)
	var use_custom_factions: bool = false
#	if battle_details.has("custom_factions"):
#		use_custom_factions = true
	if use_custom_factions:
		pass
	else: # Defaults; even horizontal division
		for y in h: for x in w:
			if (x < (w/2)):
				grid_factions.set_cell(x, y, factions.PLAYER)
			else:
				grid_factions.set_cell(x, y, factions.ENEMY)
	
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
		grid_actors.set_cell(2, 1, default_party[0])
		grid_actors.set_cell(1, 1, default_party[1])
		grid_actors.set_cell(0, 1, default_party[2])
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
#	yield(VisualServer, "frame_pre_draw")
	yield(VisualServer, "frame_post_draw")
	emit_signal("populate_gpos_data")
	emit_signal("populate_actors")
	print("TURN MGR: All actor data matched to nodes. Results:",grid_actors)
	
#	print("TURN: GPos data is:",grid_gpos)
	
	
	
		
	return true
	pass

# ---

func cycle_next_player():
	var seq: int = pc_actors.find(curr_actor)
	
	var valid: bool = false
	
	while !valid:
		seq += 1
		if seq >= pc_actors.size():
			seq = 0
		
		var next_pc: Actor = pc_actors[seq]
		
		# Ignore anyone dead or incapable of moving/actions (not implemented yet)
		if pc_actors_spent.has(next_pc):
			continue
		
		# Otherwise, valid
		valid = true
		curr_actor = next_pc
		break
	
	field.update_targeting()
	print("TURN: Cycled to next pc: ",curr_actor)
	pass

# ---

func can_player_input() -> bool:
	if turnstate == T_PLAYER_ACT:
		if actionstate == A_PLAYER_CONTROL:
			return true
	
	return false
	pass

func must_player_turn_be_over() -> bool: # Asked after any player action is executed
	# The turn is auto-over IF all PC characters are spent
	# Spent means: No move or action points remain (or not enough AP to use any valid action), or downed
	if pc_actors_spent.size() == 3:
		return true
	return false

func must_battle_be_won() -> bool: # Asked after any enemy is damaged/defeated
	return foe_actors_defeated.size() == foe_actors.size()

func must_battle_be_lost() -> bool: # Asked after any PC is damaged/defeated
	return false



