extends MoveAction





func ACT():
	strife.damage_actor_at_coord(actor, actor.coord + actor.my_facing, actor.dmg(base_damage))
	
#	actor.clear_status("enrage") # Whether it's active or not
#	actor.clear_damage_mod("enrage") # Should be handled by status auto clear?
#	strife.end_vfx_on_actor(actor, "buff", true) # Should be handled by status auto clear?
#	if !batman.is_my_action(actor): return
	
	end_action()
	pass

