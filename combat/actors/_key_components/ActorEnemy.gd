extends Actor
class_name ActorEnemy

func execute_npc_move(move: MoveAction, free_prefight_telegraph: bool = false):
	print(name,".execute_npc_move(",move,")")
	
	move.prepare_actualized_variants() # IDK if matters, frankly?
	
	if !free_prefight_telegraph:
		move.log_move_use() # Also spends user's AP
	
	# Now execute!
	batman.append_action(self, move)
	
	var is_rest: bool = (move.motion_type == move.motionchecks.REST)
	if move.req_successful_telegraph and telegraphed_move != move:
		# This is a telegraph! ALWAYS counts as a rest... I... think?
		is_rest = true
	
#	emit_signal("player_action_submitted")
	
	if is_rest:
		print(name," doing an action that is a rest!")
		yield(batman, "action_step_complete")
		if !batman.is_my_action(self): return
		
		strife.emit_signal("actor_rest_event", self)
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
	
	var move: MoveAction = loader.CM_walk
	
	if !move.quick_context_passfail_check([self, motion]):
		return false
	
	# Success!
	if auto_execute_if_true:
		# Kind of want to compress this into a standard function, but it's ok for now!
		spend(move)
		batman.append_action(self, move, [self, motion])
	
	return true
	pass


