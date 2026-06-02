extends Node

# For input monitoring and the like!
var multi_input_lock: bool = false # Prevent multiple actions being acecpted too closely together
signal valid_player_input(input_action_namestring)

const COST_MOVE: int = 1

# ---

func _process(_d): monitor_inputs()
func _physics_process(_delta): multi_input_lock = false

func monitor_inputs():
	if multi_input_lock: return
	
	if Input.is_action_just_pressed("dev_1"):
		multi_input_lock = true
		batman.test_new_combat("1")
		return
	if Input.is_action_just_pressed("dev_2"):
		multi_input_lock = true
		batman.test_new_combat("2")
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
	
	# Mid-turn 'live' behaviour
	if batman.combatstate == batman.C_TURN:
		var actor: Actor = batman.curr_actor
		if !utils.valid(actor): return
		if !actor.alive_check(): return
		if actor.faction != batman.factions.PLAYER: return
	
		if Input.is_action_just_pressed("player_move_up"):
			attempt_player_char_move(Vector2.UP)
			multi_input_lock = true
			return
		if Input.is_action_just_pressed("player_move_down"):
			attempt_player_char_move(Vector2.DOWN)
			multi_input_lock = true
			return
		if Input.is_action_just_pressed("player_move_left"):
			attempt_player_char_move(Vector2.LEFT)
			multi_input_lock = true
			return
		if Input.is_action_just_pressed("player_move_right"):
			attempt_player_char_move(Vector2.RIGHT)
			multi_input_lock = true
			return
		
		if Input.is_action_just_pressed("player_complete"):
			multi_input_lock = true
			batman.cycle_to_next_turn()
			return
	pass

func attempt_player_char_move(dir: Vector2):
	var playerchar: Actor = batman.curr_actor
	if !playerchar.can_afford(COST_MOVE): return
	if !act.is_tile_traversable_relative(playerchar, dir): return
	
	# Should be valid, then!
	playerchar.spend(COST_MOVE)
	pass








