extends MoveAction




func ACT():
	actor.start_status("enrage")
	actor.set_damage_mod("enrage", 1)
	strife.quick_vfx(actor, "quick_good")
	
	yield(utils.yt(0.5, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	end_action()
	pass

