extends MoveAction


func PREVIEW():
	if actor.check_status("enrage"):
		error_text = "Already enraged"
		return
	
	passfail = true
	pass

func ACT():
	actor.start_status("enrage")
	actor.set_damage_mod("enrage", 1)
	strife.quick_vfx(actor, "quick_good")
	
	yield(utils.yt(0.5, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	end_action()
	pass

