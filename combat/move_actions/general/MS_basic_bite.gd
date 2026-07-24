extends MoveAction





func ACT():
	strife.damage_actor_at_coord(actor, actor.coord + actor.my_facing, actor.dmg(base_damage))
	
	var dur: float = 0.125
	
	yield(utils.yt(dur, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	end_action()
	pass

