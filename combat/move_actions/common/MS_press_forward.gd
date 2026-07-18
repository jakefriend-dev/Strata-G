extends MoveAction

#var DIST: int = 3

# Only uncomment this method if you want to bypass "normal" variant loading
#func LOAD_VARIANTS():
#	for vec in plausible_variants:
#		if batman.grid_actors.has_cellv(actor.coord + vec + Vector2(DIST, 0)):
#			actualized_variants.append(vec)
#	pass


func PREVIEW():
	# If I'm not against the frontline, fail
	
	# If enemies are against the frontline, fail
	
	passfail = true
	pass

func ACT():
	# Get the effect, then end TURN (not action).
	actor.start_status("pressuring_frontline")
	end_turn()
	pass

