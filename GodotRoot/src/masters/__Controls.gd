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
	
	# Misc dev things
#	if Input.is_action_just_pressed("dev_3"):
#		multi_input_lock = true
#		var actor: Actor = support.get_first_actor_by_name("Sniper")
#		if utils.actorpass(actor):
#			actor.APD.clear()
#			actor.PREVIEW_yank(0)
#			print(actor.name," APD: ",actor.APD.sets)
#		return
	
	# Mid-turn 'live' behaviour
	if batman.combatstate == batman.C_TURN:
		if inputstate != istates.READY_FOR_PLAYER_INPUT: return
		
		var actor: Actor = batman.curr_actor
		if !utils.actorpass(actor): return
		if not actor is ActorPlayer: return
		inputcheck_player_combat_turn(actor)
		return
		
	pass

func inputcheck_player_combat_turn(actor: ActorPlayer):
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
	
	# Use the currently selected attack (and option)
	if Input.is_action_just_pressed("player_select"):
		multi_input_lock = true
		actor.attempt_player_char_action()
		return
	
	# Select a new move/option
	if Input.is_action_just_pressed("player_cycle_next"):
		multi_input_lock = true
		if Input.is_action_pressed("player_modifier_skills"):
			batman.cycle_player_actop_subops_forward()
		else:
			batman.cycle_player_actops_forward()
		return
	if Input.is_action_just_pressed("player_cycle_prev"):
		multi_input_lock = true
		if Input.is_action_pressed("player_modifier_skills"):
			batman.cycle_player_actop_subops_backward()
		else:
			batman.cycle_player_actops_backward()
		return
	
	# End turn
	if Input.is_action_just_pressed("player_complete"):
		multi_input_lock = true
		actor.emit_signal("player_action_submitted")
		return
	pass





