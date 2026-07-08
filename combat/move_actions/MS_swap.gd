extends MoveAction

#var DIST: int = 3

# Only uncomment this method if you want to bypass "normal" variant loading
func LOAD_VARIANTS():
	for vec in plausible_variants:
		var target: Vector2 = actor.coord + vec
		if batman.grid_factions.has_cellv(target):
			if batman.grid_factions.get_cellv(target) == actor.faction:
				var victim: Actor = support.get_actor_at_cellv(target)
				if utils.actorpass(victim):
					if victim.faction == actor.faction:
						actualized_variants.append(vec)
	pass

func PREVIEW():
	
	var check_vector: Vector2 = batman.loaded_variant
	var target: Vector2 = actor.coord + check_vector
	
	var victim: Actor = support.get_actor_at_cellv(target)
	if !utils.actorpass(victim): return
	if victim.faction != actor.faction: return
	
	add_actor(self, ROWS.NEUTRAL)
	
	if victim.is_ghost: # Don't try swapping already-ghost allies; that's a messy road to go down
		add_actor(victim, ROWS.ERROR)
		return
	
	add_actor(victim, ROWS.NEUTRAL)
	passfail = true
	pass

func ACT():
	var check_vector: Vector2 = batman.loaded_variant
	var target: Vector2 = actor.coord + check_vector
	var og_tile: Vector2 = actor.coord
	var victim: Actor = support.get_actor_at_cellv(target)
	
	actor.ghost_mode(true)
	victim.ghost_mode(true)
	actor.claim_tile(victim.coord)
	victim.claim_tile(actor.coord)
	
	var delay: float = 0.1
	var dur: float = 0.3
	actor.hotmove(target, dur)
	
	yield(utils.yt(delay, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	victim.hotmove(og_tile, dur)
	
	yield(utils.yt(dur, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	actor.ghost_mode(false)
	victim.ghost_mode(false)
	
	end_action()
	pass

