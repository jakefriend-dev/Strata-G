extends Actor

func ready_turn_actions():
	# Move 1 direction randomly
	act.prep_random_move_actor(self)
	
	# Perform a charge, then return to the original position
	act.prep_normal_move(self, Vector2.LEFT, true, true, true)
	act.prep_simple_attack(self, false, false)
	act.prep_normal_move(self, Vector2.RIGHT, true, false, true)
	
	# All actions readied!
	act.start_action_queue(self)
#	print(act.actionlog)
	pass

