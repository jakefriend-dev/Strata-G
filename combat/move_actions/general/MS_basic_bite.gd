extends MoveAction



func PREVIEW():
	pass

func ACT():
	strife.damage_actor_at_coord(actor, actor.coord + actor.my_facing, actor.dmg(base_damage))
	
	actor.clear_status("enrage") # Whether it's active of not
	actor.clear_damage_mod("enrage")
	strife.end_vfx_on_actor(actor, "buff", true)
	if !batman.is_my_action(actor): return
	
	end_action()
	pass

