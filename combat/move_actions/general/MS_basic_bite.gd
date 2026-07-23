extends MoveAction



func PREVIEW():
#
#	var check_vector: Vector2 = batman.loaded_variant
#
#	var unoccupieds: Array = support.list_all_unoccupied_tiles_in_dir(actor.coord, check_vector)
#	if !unoccupieds.empty():
#		add_arrow(actor.coord, unoccupieds.back(), ROWS.PASS)
#
#	var victim: Actor = support.find_nearest_actor_in_dir(actor.coord, check_vector)
#	if !utils.actorpass(victim): return
#
#	add_actor(victim, ROWS.BAD)
#	passfail = true
	pass

func ACT():
	strife.damage_actor_at_coord(actor, actor.coord + actor.my_facing, actor.dmg(2))
	
	actor.clear_status("enrage") # Whether it's active of not
	actor.clear_damage_mod("enrage")
	strife.end_vfx_on_actor(actor, "buff", true)
	if !batman.is_my_action(actor): return
	
	end_action()
	pass

