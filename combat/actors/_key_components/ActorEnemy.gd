extends Actor
class_name ActorEnemy

# ---

func prime_npc_move(move: MoveAction, free_no_charge: bool = false):
#	print(name,".prime_npc_move(",move,")")
	
	move.prepare_actualized_variants() # IDK if matters, frankly?
	
	if !free_no_charge:
		move.log_move_use() # Also spends user's AP
	
	# Now execute!
	batman.append_action(self, move)
	
#	var is_rest: bool = (move.motion_type == move.motionchecks.REST)
#	if move.req_successful_telegraph and telegraphed_move != move:
#		# This is a telegraph! ALWAYS counts as a rest... I... think?
#		is_rest = (move.telegraph_motion_type == move.motionchecks.REST)
#
##	emit_signal("player_action_submitted")
#
#	if is_rest:
##		print(name," doing an action that is a rest!")
#		yield(batman, "action_step_complete")
#		if !batman.is_my_action(self): return
#
#		strife.emit_signal("actor_rest_event", self)
	pass

func randomwalk_if_possible(auto_execute_if_true: bool = true) -> bool: # If true, the walk move will be actionqueued before the 'true' result comes back!
	var orthags: Array = support.orthags.duplicate()
	orthags.shuffle()
	var motion: Vector2
	var passflag: bool = false
	for vec in orthags:
		if support.is_tile_traversable_relative(self, vec):
			motion = vec
			passflag = true
			break
	
	if !passflag: # We have at least 1 viable option, and since we randomly drew it, it's our direction!
		return false
	
#	var move: MoveAction = LM["WALK"]
#	LM["WALK"].actor = self
	LM["WALK"].restage_MPD("actorenemy pre RAND walk check")
	LM["WALK"].manual_variant = motion
	
	if !LM["WALK"].quick_context_passfail_check():
#		print(name," walk passfail check failed")
		return false
#	print(name," walk passfail check succeeeded")
	
	# Success!
	if auto_execute_if_true:
		# Kind of want to compress this into a standard function, but it's ok for now!
		spend(LM["WALK"])
		batman.append_action(self, LM["WALK"])
	
	return true
	pass

func walkdir_check(motion: Vector2, ignore_factionline: bool = false) -> bool:
	if !support.is_tile_traversable_relative(self, motion, ignore_factionline):
		print("walkdir_check(",motion,") cant traverse that way")
		return false
	
	if action_points == 0:
		print("walkdir_check needs at least 1 AP")
		return false
	
	print("walkdir_check(",motion,") passed!")
	return true
	pass

func directed_walk_if_possible(motion: Vector2, auto_execute_if_true: bool = true) -> bool: # If true, the walk move will be actionqueued before the 'true' result comes back!
	var passflag: bool = false
	if support.is_tile_traversable_relative(self, motion):
		passflag = true
	
	if !passflag:
		return false
	
	LM["WALK"].restage_MPD("actorenemy pre DIR walk check")
	LM["WALK"].manual_variant = motion
	
	if !LM["WALK"].quick_context_passfail_check():
#		print(name," walk passfail check failed")
		return false
#	print(name," walk passfail check succeeeded")
	
	# Success!
	if auto_execute_if_true:
		# Kind of want to compress this into a standard function, but it's ok for now!
		spend(LM["WALK"])
		batman.append_action(self, LM["WALK"])
	
	return true
	pass

