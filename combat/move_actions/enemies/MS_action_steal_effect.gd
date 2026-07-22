extends MoveAction

func ACT():
	yield(utils.yt(0.25, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	for victim in batman.living_actors: if victim is Actor:
		# Enemies gain 1AP, playerside loses 1AP
		if victim.faction == batman.factions.NEUTRAL: continue
		if victim.faction != actor.faction:
			strife.quick_vfx(victim, "quick_bad")
			victim.manual_spend(1)
	
	yield(utils.yt(0.5, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	for ally in batman.living_actors: if ally is Actor:
		if ally.faction == batman.factions.NEUTRAL: continue
		if ally.faction == actor.faction:
			strife.quick_vfx(ally, "quick_good")
			ally.add_action_points(1)
	
	yield(utils.yt(0.25, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	actor.log_hit() # You would just never use this if there weren't opposing forces, because the battle would be over!
	end_action()
	pass

