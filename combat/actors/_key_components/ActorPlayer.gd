extends Actor
class_name ActorPlayer

#var moveset: Dictionary = {} # Post-validation
#var move_layout: Array2D # ONLY used by ActorPlayer!
#export (Array, Resource) var loaded_moves: Array = [null, null, null, null, null, null, null] # Can manually change this for ActorEnemy but leave as 7 by default; shouldn't exceed 7 for ActorPlayer

#const pstring: String = "PREVIEW"
#const astring: String = "ACT"
#const lvstring: String = "LOAD_VARIANTS"

# ---

func _ready():
	batman.connect("action_option_view_changed", self, "run_move_preview")
	batman.connect("action_step_complete", self, "run_move_preview")
	pass

func run_move_preview(is_brand_new_move_selected: bool = false):
	if batman.curr_actor != self: return
	if !batman.player_input_validation_checks(): return
	support.de_ghost_all_actors()
	
	var move: MoveAction = batman.loaded_move
#	print("running move preview for ",move)
	if move == null: return
	
	limited_run_move_preview(move, is_brand_new_move_selected)
	pass

func limited_run_move_preview(move, is_brand_new_move_selected: bool = false):
	# This version BYPASSES VALIDATIONS so that it can also be called after the action is successfully processed in batman!
	move.restage_MPD("Actor Player limited move preview")
	move.prepare_actualized_variants()
	batman.assert_player_variant_against_move(move, is_brand_new_move_selected)
	
	if move.has_method("PREVIEW"):
#		print("  --  New Preview  --")
		move.call("PREVIEW") # Player moves (other than common's WALK) never have params; they use the actualized variant stuff to determine possible options!
		batman.field.movewindow.update_error_text_only()
		move.generate_cell_highlights()
		pass
	
	move.ready_to_use = is_player_action_usable(false)
	
	batman.emit_signal("new_action_preview_data_readied", move)
	pass

# ---

func is_player_action_usable(do_print: bool = true) -> bool:
	if !batman.player_input_validation_checks(): return false
	if batman.curr_actor != self: return false
	
	var move: MoveAction = batman.loaded_move
	
	if move == null:
		# Sometimes 'valid' when it's a custom script, so we have to check
		# (but either way, this is still not a 'usable move' so return false!)
		
		if batman.field.movewindow.attempt_to_run_moveoption_custom_function():
#			print("sfx good")
			pass
		else:
#			print("sfx bad")
			pass
		
		return false
	
	return move.usability_check(self, do_print)
	pass

func attempt_player_char_move(motion: Vector2):
#	LM["WALK"].actor = self
	LM["WALK"].manual_variant = motion
	
	if !LM["WALK"].totality_check([], self, true):
		print("validation fail, move error: ",LM["WALK"].error_text)
		return
	
#	print("letsgo: ",motion)
	spend(LM["WALK"])
	batman.append_action(self, LM["WALK"])
	submit_player_action(false)
	pass

func attempt_player_char_action():
	if !is_player_action_usable(): return # For 'custom moveopts' this also runs their command before stopping!
	
	# Should be valid, then! Adjust our stats/values first
	var move: MoveAction = batman.loaded_move
	
#	print("going to spend ",move.effective_cost(),"-AP when ",action_points,"-AP remain")
	
	move.log_move_use() # Also spends player's AP
	
	# Now execute!
	batman.append_action(self, move)
	
	submit_player_action(move.motion_type == move.motionchecks.REST)
	pass

func submit_player_action(is_rest: bool):
	emit_signal("player_action_submitted")
	
	if is_rest:
		yield(batman, "action_step_complete")
		if !batman.is_my_action(self): return
		
		strife.emit_signal("actor_rest_event", self)
#		strife.TILE_event_rest(self, coord)
	pass

# ---
