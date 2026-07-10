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
var stick_LX_active: bool = false
var stick_LY_active: bool = false
var stick_left_vangle: Vector2
var stick_left_gangle: Vector2
var stick_right_active: bool = false
var stick_right_vangle: Vector2
var stick_right_gangle: Vector2

# ---

func _process(_d):
	monitor_gamepad_sticks()
	monitor_inputs_CORE()
func _physics_process(_delta):
	multi_input_lock = false

# -

func monitor_gamepad_sticks():
	if multi_input_lock: return
	
	monitor_L_stick(JOY_AXIS_1, "player_cycle_prev", "player_cycle_next")
	monitor_L_stick(JOY_AXIS_0, "player_subcycle_prev", "player_subcycle_next")
	monitor_R_stick()
	
# JOY_AXIS_0 = 0
#Gamepad left stick horizontal axis.
#● JOY_AXIS_1 = 1
#Gamepad left stick vertical axis.
#● JOY_AXIS_2 = 2
#Gamepad right stick horizontal axis.
#● JOY_AXIS_3 = 3
#Gamepad right stick vertical axis.
	
	pass

func monitor_L_stick(joy_axis: int, dec_action: String, inc_action: String):
	var h_not_v: bool = (joy_axis == JOY_AXIS_0 or joy_axis == JOY_AXIS_2)
	
	var vecstep: int = 0
	var tilt: float = Input.get_joy_axis(0, joy_axis)
	var stick_active: bool = false
	if h_not_v:
		stick_active = stick_LX_active
	else:
		stick_active = stick_LY_active
	
	if abs(tilt) > deadzone:
		if tilt < 0:
			vecstep = -1
			if !Input.is_action_pressed(dec_action) and !stick_active:
				Input.action_press(dec_action)
		else:
			vecstep = 1
			if !Input.is_action_pressed(inc_action) and !stick_active:
				Input.action_press(inc_action)
		stick_active = true
		
	else: # Tilt doesn't exceed deadzone
		if stick_active:
			stick_active = false
			if Input.is_action_pressed(dec_action):
				Input.action_release(dec_action)
			if Input.is_action_pressed(inc_action):
				Input.action_release(inc_action)
		vecstep = 0
		tilt = 0.0
	
	if h_not_v:
		stick_LX_active = stick_active
		stick_left_vangle.x = vecstep
		stick_left_gangle.x = tilt
	else:
		stick_LY_active = stick_active
		stick_left_vangle.y = vecstep
		stick_left_gangle.y = tilt
	pass

func monitor_R_stick():
	var vecstep_x: int = 0
	var vecstep_y: int = 0
	var tilt: Vector2 = Vector2(
		Input.get_joy_axis(0, JOY_AXIS_2),
		Input.get_joy_axis(0, JOY_AXIS_3)
		)
	
	if tilt.length() > deadzone:
		var tx: float = abs(tilt.x)
		if tx > deadzone:
			if tilt.x > 0:
				vecstep_x = 1
			elif tilt.x < 0:
				vecstep_x = -1
		var ty: float = abs(tilt.y)
		if ty > deadzone:
			if tilt.y > 0:
				vecstep_y = 1
			elif tilt.y < 0:
				vecstep_y = -1
		if !stick_right_active:
			batman.attempt_to_change_player_variant(tilt)
		stick_right_active = true
	
	else: # Tilt doesn't exceed deadzone
		if stick_right_active:
			stick_right_active = false
			tilt = Vector2.ZERO
	
	# These are mostly just tracking; I don't think they're used in the same way
	stick_right_gangle = tilt
	stick_right_vangle = Vector2(vecstep_x, vecstep_y)
	pass

func monitor_inputs_CORE():
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
	elif (batman.combatstate != batman.C_BATTLE_SETUP and batman.combatstate != batman.C_OOC):
		# We are DEFINITELY *in* battle
		if Input.is_action_just_pressed("ui_cancel"):
			multi_input_lock = true
			print("---\nCONTROLS: Resetting combat to landing page!")
			utils.change_master_scene("landing")
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
	if Input.is_action_pressed("player_modifier"):
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
		
		# End of ALL modifier code
		return
	
	if Input.is_action_just_pressed("dev_0"):
		if utils.actorpass(batman.curr_actor):
			batman.curr_actor.add_action_points(1)
		multi_input_lock = true
		return
	
	# Move selection (2D grid)
	if Input.is_action_just_pressed("player_move_up"):
		multi_input_lock = true
		batman.change_movewindow_selrow(-1)
		return
	if Input.is_action_just_pressed("player_move_down"):
		multi_input_lock = true
		batman.change_movewindow_selrow(1)
		return
	if Input.is_action_just_pressed("player_move_left"):
		multi_input_lock = true
		batman.change_movewindow_selcol(-1)
		return
	if Input.is_action_just_pressed("player_move_right"):
		multi_input_lock = true
		batman.change_movewindow_selcol(1)
		return
	
	# Use the currently selected attack (and option)
	if Input.is_action_just_pressed("player_select"):
		multi_input_lock = true
		actor.attempt_player_char_action()
		return
	
	# Select a variant
	if Input.is_action_just_pressed("player_aim_TL"):
		multi_input_lock = true
		batman.attempt_to_change_player_variant(Vector2.UP + Vector2.LEFT)
		return
	if Input.is_action_just_pressed("player_aim_TC"):
		multi_input_lock = true
		batman.attempt_to_change_player_variant(Vector2.UP)
		return
	if Input.is_action_just_pressed("player_aim_TR"):
		multi_input_lock = true
		batman.attempt_to_change_player_variant(Vector2.UP + Vector2.RIGHT)
		return
	if Input.is_action_just_pressed("player_aim_CL"):
		multi_input_lock = true
		batman.attempt_to_change_player_variant(Vector2.LEFT)
		return
	if Input.is_action_just_pressed("player_aim_CC"):
		multi_input_lock = true
		batman.attempt_to_change_player_variant(Vector2.ZERO, true)
		return
	if Input.is_action_just_pressed("player_aim_CR"):
		multi_input_lock = true
		batman.attempt_to_change_player_variant(Vector2.RIGHT)
		return
	if Input.is_action_just_pressed("player_aim_BL"):
		multi_input_lock = true
		batman.attempt_to_change_player_variant(Vector2.DOWN + Vector2.LEFT)
		return
	if Input.is_action_just_pressed("player_aim_BC"):
		multi_input_lock = true
		batman.attempt_to_change_player_variant(Vector2.DOWN)
		return
	if Input.is_action_just_pressed("player_aim_BR"):
		multi_input_lock = true
		batman.attempt_to_change_player_variant(Vector2.DOWN + Vector2.RIGHT)
		return
	
	# End turn
	if Input.is_action_just_pressed("player_complete"):
		multi_input_lock = true
		actor.emit_signal("player_action_submitted")
		return
	pass






