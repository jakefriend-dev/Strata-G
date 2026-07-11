extends MoveAction

#var DIST: int = 3

# Only uncomment this method if you want to bypass "normal" variant loading
#func LOAD_VARIANTS():
#	for vec in plausible_variants:
#		if batman.grid_actors.has_cellv(actor.coord + vec + Vector2(DIST, 0)):
#			actualized_variants.append(vec)
#	pass


func PREVIEW():
	var faction: int = actor.faction
	for ally in batman.living_actors:
		if utils.actorpass(ally):
			if ally.faction == faction:
				add_actor(ally, ROWS.GOOD)
	pass

func ACT():
	for ally in get_all_actors_by_MPD_type(ROWS.GOOD):
		strife.quick_vfx(ally, "quick_good")
		ally.set_damage_mod("attack_buff", 1)
#		ally.start_status("attack_buff", "Cry of Valor", "good", 1, true)
#		ally.start_status("attack_buff", "Cry of Valor", "good", 1, true, "generic_clear_status")
		ally.start_status("attack_buff", "Cry of Valor", "+1 damage until end of next turn.", "good", 1, true, [], "generic_clear_status")
	
	end_action()
	pass

