extends MoveAction


func ONE_TIME_SETUP():
	actor.connect("on_shield_broken_through", self, "REACT")
	pass

func PREVIEW():
	
	# Pick a PC!
	var pcs: Array = batman.get_all_current_players()
	pcs.shuffle()
	for pc in pcs:
		if !batman.targeted_tiles.has(pc.coord):
			add_cell(pc.coord, ROWS.BAD)
			break
	# If there wasn't a 'free' PC, double-target
	if get_all_cells_by_MPD_type(ROWS.BAD).size() == 0:
		add_cell(pcs[0].coord, ROWS.BAD)
	
	strife.quick_vfx(actor, "spark_burst")
	
	actor.sprite.frame = actor.HELD_ROCK
	
	passfail = true
	
	yield(utils.yt(0.25, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	end_telegraph()
	pass

func RE_PREVIEW():
	passfail = true
	pass

func ACT():
	var target: Vector2 = get_first_cell_by_MPD_type(ROWS.BAD) # Just in case of accidental multiple
	actor.clear_telegraphed_move()
	
	yield(utils.yt(0.125, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	strife.damage_actor_at_coord(actor, target, actor.dmg(base_damage))
	strife.quick_vfx(actor, "spark_burst")
	actor.sprite.frame = actor.NO_ROCK
	
	yield(utils.yt(0.25, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	end_action()
	pass

func REACT(_combat_package):
	print("thrower react?")
	if actor.telegraphed_move != self: return
	print("it succeeded bc we had telegraphed it")
	
	restage_MPD("drop rock reaction")
	actor.release_targeted_tiles()
	actor.sprite.frame = actor.DROPPED_ROCK
	strife.damage_actor_at_coord(actor, actor.coord, actor.dmg(1))
	actor.clear_telegraphed_move()
	
	yield(utils.yt(0.125, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	end_action()
	pass
