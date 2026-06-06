extends Node

# For input monitoring and the like!
var multi_input_lock: bool = false # Prevent multiple actions being acecpted too closely together
#signal valid_player_input(input_action_namestring)

enum istates {
	CANNOT_ACT,
	READY_FOR_PLAYER_INPUT,
}
var inputstate: int = istates.CANNOT_ACT

# ---

func _process(_d): monitor_inputs()
func _physics_process(_delta): multi_input_lock = false

func monitor_inputs():
	if multi_input_lock: return
	
	# Test setups
	if batman.combatstate == batman.C_OOC:
		if Input.is_action_just_pressed("dev_1"):
			multi_input_lock = true
			batman.test_new_combat("1")
			return
		if Input.is_action_just_pressed("dev_2"):
			multi_input_lock = true
			batman.test_new_combat("2")
			return
		return
	
	# Mid-turn 'live' behaviour
	if batman.combatstate == batman.C_TURN:
		if inputstate != istates.READY_FOR_PLAYER_INPUT: return
		
		var actor: Actor = batman.curr_actor
		if !utils.valid(actor): return
		if !actor.alive_check(): return
		if actor.faction != batman.factions.PLAYER: return
		
		# Orthagonal movement
		if Input.is_action_just_pressed("player_move_up"):
			multi_input_lock = true
			actor.attempt_player_char_move(Vector2.UP)
			return
		if Input.is_action_just_pressed("player_move_down"):
			multi_input_lock = true
			actor.attempt_player_char_move(Vector2.DOWN)
			return
		if Input.is_action_just_pressed("player_move_left"):
			multi_input_lock = true
			actor.attempt_player_char_move(Vector2.LEFT)
			return
		if Input.is_action_just_pressed("player_move_right"):
			multi_input_lock = true
			actor.attempt_player_char_move(Vector2.RIGHT)
			return
		
		if Input.is_action_just_pressed("player_basic_attack"):
			multi_input_lock = true
			actor.attempt_player_char_basicattack()
			return
		
		if Input.is_action_just_pressed("player_complete"):
			multi_input_lock = true
			actor.emit_signal("player_action_submitted")
			return
	pass







