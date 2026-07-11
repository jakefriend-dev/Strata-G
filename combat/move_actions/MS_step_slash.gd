extends MoveAction

var victim: Actor
var step_cell: Vector2
var og_cell:  Vector2
var victim_cell: Vector2

var seq: int = 1

func PREVIEW():
	seq = 1
	
	var check_vector: Vector2 = batman.loaded_variant
	og_cell = actor.coord
	step_cell = og_cell + check_vector
	victim_cell = step_cell + check_vector
	
	if !batman.grid_actors.has_cellv(step_cell):
		return
	if !batman.grid_actors.has_cellv(victim_cell):
		return
	
	if !support.is_tile_available(step_cell):
		add_cell(step_cell, ROWS.ERROR)
		return
	if !support.is_tile_traversable_exact(actor, step_cell, true):
		add_cell(step_cell, ROWS.ERROR)
		return
	
	# We know WE can move
	add_cell(actor.coord, ROWS.NEUTRAL)
	add_cell(step_cell, ROWS.NEUTRAL)
	
	victim = batman.grid_actors.get_cellv(victim_cell)
	if !utils.actorpass(victim):
		add_cell(victim_cell, ROWS.PASS)
		return
	
	# At this point, we can assume the victim exists
	add_actor(victim, ROWS.BAD)
	passfail = true
	
	# Whether or not we're able to move the victim closer, we're able to attack now!
	pass

func ACT():
	
	match seq:
		1:
			move_forward_and_stab()
			seq += 1
			return
		2:
			move_back_and_pull()
			seq += 1
			return
	
	end_action()
	pass

func move_forward_and_stab():
	actor.ghost_mode(true)
	actor.allowed_over_faction_lines = true
	
	var dur: float = 0.1
	actor.hotmove(step_cell, dur)
	
	yield(utils.yt(dur, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	strife.damage_actor_at_coord(actor, victim.coord, actor.dmg(base_damage), ["piercing"])
	strife.quick_vfx(victim, "spark_burst")
	
	batman.append_action(actor, resource_name)
	end_action()
	pass

func move_back_and_pull():
	actor.ghost_mode(true)
	actor.allowed_over_faction_lines = true
	
	var delay: float = 0.25
	
	yield(utils.yt(delay, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	var pullable_vic: bool = false
#	print("a")
	if utils.actorpass(victim): # They might already be dead!
#		print("b")
		if !strife.is_unmovable(victim):
#			print("c")
			if support.is_tile_traversable_exact(victim, step_cell):
#				print("d")
				pullable_vic = true
	
	var dur: float = 0.375
	actor.hotmove(og_cell, dur)
	if pullable_vic:
		victim.ghost_mode(true)
		victim.hotmove(step_cell, dur)
		strife.quick_vfx(victim_cell, "dust")
	
	yield(utils.yt(dur, actor), "timeout")
	if !batman.is_my_action(actor): return
	actor.ghost_mode(false)
	actor.allowed_over_faction_lines = false
	if pullable_vic:
		victim.ghost_mode(false)
	
	end_action()
	pass




