extends MoveAction



func PREVIEW():
	var my_frontline_x: int
	var their_frontline_x: int
	
	if utils.actorpass(batman.pressuring_actor):
		error_text = "Only one may press at once!"
		add_actor(actor, ROWS.ERROR)
	
	if actor.faction == batman.factions.PLAYER:
		my_frontline_x = batman.player_frontline_col
		their_frontline_x = batman.enemy_frontline_col
	elif actor.faction == batman.factions.ENEMY:
		my_frontline_x = batman.enemy_frontline_col
		their_frontline_x = batman.player_frontline_col
	
	# If I'm not against the frontline, fail
	if actor.coord.x != my_frontline_x:
		error_text = "Unit must be against frontline!"
		add_actor(actor, ROWS.ERROR)
	
	# If enemies are against the frontline, fail
	var y: int = 0 # 1-based
	for n in batman.field.board_size.y:
		y += 1
		var coord: Vector2 = Vector2(their_frontline_x, y)
		var o_actor: Actor = batman.grid_actors.get_cellv(coord)
		if utils.actorpass(o_actor):
			if o_actor.faction != batman.factions.NEUTRAL:
				error_text = "Opposing frontline must be clear of units!"
				add_actor(o_actor, ROWS.ERROR)
	
	if error_text != "":
		return
	
	passfail = true
	pass

func affirm_by_any_actor(anyactor: Actor) -> bool:
	var my_frontline_x: int
	var their_frontline_x: int
	
	if anyactor.faction == batman.factions.PLAYER:
		my_frontline_x = batman.player_frontline_col
		their_frontline_x = batman.enemy_frontline_col
	elif anyactor.faction == batman.factions.ENEMY:
		my_frontline_x = batman.enemy_frontline_col
		their_frontline_x = batman.player_frontline_col
	
	# If I'm not against the frontline, fail
	if anyactor.coord.x != my_frontline_x:
		failquip(anyactor, "Blast! I am moved")
		return false
	
	# If enemies are against the frontline, fail
	var y: int = 0 # 1-based
#	var opposing_pass: bool = true
	for n in batman.field.board_size.y:
		y += 1
		var coord: Vector2 = Vector2(their_frontline_x, y)
		var o_actor: Actor = batman.grid_actors.get_cellv(coord)
		if utils.actorpass(o_actor):
			if o_actor.faction != batman.factions.NEUTRAL:
				failquip(anyactor, "Alas! They have shored rank")
				return false
	
	return true
	pass

func failquip(anyactor: Actor, text: String):
	anyactor.quip(text)
	pass

func ACT():
	# Get the effect, then end TURN (not action).
	actor.quip("We press forward!")
#	actor.quip(str(actor.display_name," presses forward!"))
	actor.start_status("pressuring_frontline")
	batman.pressuring_actor = actor
	
	yield(utils.yt(1.0, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	end_turn()
	pass

