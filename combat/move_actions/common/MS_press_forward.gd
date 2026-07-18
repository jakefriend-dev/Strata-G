extends MoveAction

#var DIST: int = 3

# Only uncomment this method if you want to bypass "normal" variant loading
#func LOAD_VARIANTS():
#	for vec in plausible_variants:
#		if batman.grid_actors.has_cellv(actor.coord + vec + Vector2(DIST, 0)):
#			actualized_variants.append(vec)
#	pass


func PREVIEW():
	var my_frontline_x: int
	var their_frontline_x: int
	
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
	var opposing_pass: bool = true
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

func ACT():
	# Get the effect, then end TURN (not action).
	actor.start_status("pressuring_frontline")
	end_turn()
	pass

