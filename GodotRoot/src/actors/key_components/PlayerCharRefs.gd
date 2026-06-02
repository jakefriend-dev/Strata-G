
var actor: Actor

# ---

func check_resources():
	print("PC REFS: ",actor.name," has ",actor.action_points," AP left and ",actor.health," health!")
	pass

func ACT_basic_move(dir: Vector2):
	print("executing basic move")
	
	var exact_coord: Vector2 = actor.coord + dir
	var dur: float = 0.125
	
	act.hotmove(actor, exact_coord, dur)
	yield(utils.yt(dur, self), "timeout")
	if !batman.is_my_turn(actor): return
	
	actor.end_action()
	
	pass






