extends ActorPlayer

#const COST_: int = 1
#const COST_: int = 1
#const COST_: int = 1
#const COST_: int = 1
#const COST_: int = 1
#const COST_: int = 1

# ---

func _ready():
	
	pass

func pre_turn_setup():
	pass

func prep_next_action(): # This func should END with setting up one or multiple actions!
	
	# SAMPLE REFERENCE from DOGGO!
#	# If we can afford to charge (and have space to), do that!
#	if can_afford(COST_CHARGE) and can_charge_left:
#		spend(COST_CHARGE) # This is the charge-AND-bite combo
#		batman.append_action(self, "charge_forward")
#		batman.append_action(self, "bite")
#		batman.append_action(self, "charge_back")
#		return
	
	
	
	# DEFAULT ELSE: Can't go anywhere, can't do nothin' :(
	pass

func PREVIEW_longshot() -> Dictionary:
	var preview: Dictionary = template_action_preview.duplicate(true)
	
	preview["unaffected"] = support.list_all_unoccupied_tiles_in_dir(coord, my_facing)
	
	var victim: Actor = support.find_nearest_actor_in_dir(coord, my_facing)
	if utils.valid(victim):
		preview["damaged"] = [victim.coord]
	
	return preview
	pass

func ACT_longshot():
	# Shoot a target in your line-of-sight; higher damage per tile travelled
	var victim: Actor = support.find_nearest_actor_in_dir(coord, my_facing)
	if !utils.valid(victim):
		return
	
	var dist: int = support.get_vecdist_between_actors(self, victim).length()
	var dmg: int = dist - 1 # Should mean 0 damage for adjacent, or 4 for opposite side of a 6x3 arena
	if dmg < 0: dmg = 0
	dmg *= batman.BASE_HP_FACTOR
	
	strife.damage_actor_at_coord(self, victim.coord, dmg)
	end_action()
	pass

func PREVIEW_yank(option: int): # Options are 0, 1, 2
	var unoccupieds: Array = support.list_all_unoccupied_tiles_in_dir(coord, my_facing)
	if !unoccupieds.empty():
		APD.add_arrow(coord, unoccupieds.back(), acols.PASS)
	
	var victim: Actor = support.find_nearest_actor_in_dir(coord, my_facing)
	if !utils.actorpass(victim): return
	
	APD.add_actor(victim, acols.NEUTRAL)
	
	var check_vector: Vector2 = their_facing
	if option == 1: check_vector += Vector2.UP
	if option == 2: check_vector += Vector2.DOWN
	var check_coord: Vector2 = victim.coord + check_vector
	
	if support.is_tile_traversable_exact(victim, check_coord):
		APD.add_arrow(victim.coord, check_coord, acols.NEUTRAL)
		APD.passfail = true
	else:
		APD.add_arrow(victim.coord, check_coord, acols.ERROR)
	
	pass

func ACT_yank():
	# We KNOW there' a victim, because if there wasn't, we couldn't have passed the preview check
	var victim: Actor = APD.get_actor_by_type(acols.NEUTRAL)
	pass
