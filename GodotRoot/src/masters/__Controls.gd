extends Node

# For input monitoring and the like!
var multi_input_lock: bool = false # Prevent multiple actions being acecpted too closely together
#signal valid_player_input(input_action_namestring)

enum istates {
	CANNOT_ACT,
	READY_FOR_PLAYER_INPUT,
}
var inputstate: int = istates.CANNOT_ACT

const deadzone: float = 0.8
var stick_left_active: bool = false
var stick_left_vangle: Vector2
var stick_left_gangle: Vector2
var stick_right_active: bool = false
var stick_right_vangle: Vector2
var stick_right_gangle: Vector2

# ---

func _process(_d):
	monitor_gamepad_sticks()
	monitor_inputs()
func _physics_process(_delta):
	multi_input_lock = false
#	if stick_left_active:
#		stick_left_active = false
##		if Input.is_action_pressed("player_cycle_next"):
##			Input.action_release("player_cycle_next")
##		if Input.is_action_pressed("player_cycle_prev"):
##			Input.action_release("player_cycle_prev")
#	if stick_right_active:
#		stick_right_active = false

# -

func monitor_gamepad_sticks():
	if multi_input_lock: return
	
	stick_left_vangle = Vector2.ZERO
	
	var left_h: float = Input.get_joy_axis(0, JOY_AXIS_0)
	if abs(left_h) > deadzone:
		if left_h < 0:
			stick_left_gangle.x = -1
			if !Input.is_action_pressed("player_cycle_prev"):
				Input.action_press("player_cycle_prev")
		else:
			stick_left_gangle.x = 1
			if !Input.is_action_pressed("player_cycle_next"):
				Input.action_press("player_cycle_next")
		stick_left_vangle.x = left_h
		stick_left_active = true
	elif stick_left_active:
		stick_left_active = false
		if Input.is_action_pressed("player_cycle_prev"):
			Input.action_release("player_cycle_prev")
		if Input.is_action_pressed("player_cycle_next"):
			Input.action_release("player_cycle_next")
		stick_left_vangle.x = 0
		stick_left_gangle.x = 0
	
#	var left_v: float = Input.get_joy_axis(0, JOY_AXIS_1)
#	if abs(left_v) > deadzone:
#		if left_v < 0:
#			stick_left_gangle.y = -1
#		else:
#			stick_left_gangle.y = 1
#		stick_left_vangle.y = left_v
#		stick_left_active = true
#
#	#
#	#
#	#
#
#	stick_right_vangle = Vector2.ZERO
#
#	var right_h: float = Input.get_joy_axis(0, JOY_AXIS_2)
#	if abs(right_h) > deadzone:
#		if right_h < 0:
#			stick_right_gangle.x = -1
#		else:
#			stick_right_gangle.x = 1
#		stick_right_vangle.x = right_h
#		stick_right_active = true
#	var right_v: float = Input.get_joy_axis(0, JOY_AXIS_3)
#	if abs(right_v) > deadzone:
#		if right_v < 0:
#			stick_right_gangle.y = -1
#		else:
#			stick_right_gangle.y = 1
#		stick_right_vangle.y = right_v
#		stick_right_active = true
	pass

# JOY_AXIS_0 = 0
#Gamepad left stick horizontal axis.
#● JOY_AXIS_1 = 1
#Gamepad left stick vertical axis.
#● JOY_AXIS_2 = 2
#Gamepad right stick horizontal axis.
#● JOY_AXIS_3 = 3
#Gamepad right stick vertical axis.


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
		if Input.is_action_just_pressed("dev_3"):
			multi_input_lock = true
			batman.test_new_combat("3")
			return
		return
	
	# Misc dev things
	pass
	
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





