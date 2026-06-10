extends ActorPlayer

#const COST_: int = 1
#const COST_: int = 1
#const COST_: int = 1
#const COST_: int = 1
#const COST_: int = 1
#const COST_: int = 1

const moveset: Dictionary = {
	
#	# TEMPLATE
#	"move_key": {
#		"display_name": "Move Name",
#		"display_desc": "Do this set of actions when you pick this move.",
#		"options": 0, # Typically 0 but could be an infinite number
#		"cost": 1,
#		"on_use_cooldown": 0, # 0 = no cooldown; 1 = after using, you cannot use it the next 1 turns
#		"initial_cooldown": 0, # Turns required until ability is first usable
#		"uses_per_turn": 0, # 0 = infinite; any positive int = limited
#		"uses_per_battle": 0, # As above, but in total all fight
#		"req_APDpass": false, # When true, unusable in scenarios where APD.passfail is false
#		"current_cooldown": 0,
#		"current_turn_uses": 0,
#		"current_battle_uses": 0,
#	},
	
	"basic_shot": {
		"display_name": "Weak Shot",
		"display_desc": "Shoot the first unit in your line of sight. Weak, but convenient.",
		"options": 0, # Typically 0 but could be an infinite number
		"cost": 1,
		"on_use_cooldown": 0, # 0 = no cooldown; 1 = after using, you cannot use it the next 1 turns
		"initial_cooldown": 0, # Turns required until ability is first usable
		"uses_per_turn": 0, # 0 = infinite; any positive int = limited
		"uses_per_battle": 0, # As above, but in total all fight
		"req_APDpass": false, # When true, unusable in scenarios where APD.passfail is false
		"current_cooldown": 0,
		"current_turn_uses": 0,
		"current_battle_uses": 0,
	},
	
	"yank": {
		"display_name": "Yank-Back",
		"display_desc": "Grab the nearest unit in your line of sight, and yank it towards you (and maybe to the side) Won't yank Heavy units.",
		"options": 2, # Typically 0 but could be an infinite number
		"cost": 1,
		"on_use_cooldown": 0, # 0 = no cooldown; 1 = after using, you cannot use it the next 1 turns
		"initial_cooldown": 0, # Turns required until ability is first usable
		"uses_per_turn": 1, # 0 = infinite; any positive int = limited
		"uses_per_battle": 0, # As above, but in total all fight
		"req_APDpass": true, # When true, unusable in scenarios where APD.passfail is false
		"current_cooldown": 0,
		"current_turn_uses": 0,
		"current_battle_uses": 0,
	},
	
	"longshot": {
		"display_name": "Longshot",
		"display_desc": "Shoot the first unit in your line of sight. Deals more damage the further away the target is.",
		"options": 2, # Typically 0 but could be an infinite number
		"cost": 2,
		"on_use_cooldown": 0, # 0 = no cooldown; 1 = after using, you cannot use it the next 1 turns
		"initial_cooldown": 0, # Turns required until ability is first usable
		"uses_per_turn": 0, # 0 = infinite; any positive int = 
		"uses_per_battle": 0, # As above, but in total all fight
		"req_APDpass": false, # When true, unusable in scenarios where APD.passfail is false
		"current_cooldown": 0,
		"current_turn_uses": 0,
		"current_battle_uses": 0,
	},
	
}

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
	
	if !support.is_tile_traversable_exact(victim, check_coord):
		APD.add_arrow(victim.coord, check_coord, acols.ERROR)
		return
	
	if !strife.is_affected_by_force(victim):
		APD.add_arrow(victim.coord, check_coord, acols.ERROR)
		return
	
	# Success case!
	APD.add_arrow(victim.coord, check_coord, acols.NEUTRAL)
	APD.passfail = true
	pass

func ACT_yank(option: int):
	# We KNOW there' a victim, because if there wasn't, we couldn't have passed the preview check
	var victim: Actor = APD.get_actor_by_type(acols.NEUTRAL)
	
	# Data setup!
	var motion: Vector2 = their_facing
	if option == 1: motion += Vector2.UP
	if option == 2: motion += Vector2.DOWN
	
	var dest_coord: Vector2 = victim.coord + motion
	if !support.is_tile_traversable_exact(victim, dest_coord):
		dest_coord = victim.coord
	
	# Visuals!
	strife.quick_effect(victim, "spark_burst")
	
	yield(utils.yt(0.25, self), "timeout")
	if !batman.is_my_action(self): return
	
	strife.quick_effect(victim, "dust")
	if dest_coord != victim.coord:
		victim.ACT_be_external_motioned(motion, 0, self, false)
	
	yield(utils.yt(0.375, self), "timeout")
	if !batman.is_my_action(self): return
	
	end_action()
	pass

func PREVIEW_longshot(option: int):
	
	var check_vector: Vector2 = my_facing
	if option == 1: check_vector += Vector2.UP
	if option == 2: check_vector += Vector2.DOWN
	
	var unoccupieds: Array = support.list_all_unoccupied_tiles_in_dir(coord, check_vector)
	if !unoccupieds.empty():
		APD.add_arrow(coord, unoccupieds.back(), acols.PASS)
	
	var victim: Actor = support.find_nearest_actor_in_dir(coord, check_vector)
	if !utils.actorpass(victim): return
	
	APD.add_actor(victim, acols.BAD)
	APD.passfail = true
	pass

func ACT_longshot(option: int):
	# Shoot a target in your line-of-sight; higher damage per tile travelled
	var victim: Actor = APD.get_actor_by_type(acols.BAD)
	var dmg: int = 0
	var dist: int = 0
	
	var coord_path: Array = []
	if utils.actorpass(victim):
		
		var check_vector: Vector2 = my_facing
		if option == 1: check_vector += Vector2.UP
		if option == 2: check_vector += Vector2.DOWN
		var check_cell: Vector2 = coord
		while check_cell != victim.coord:
			check_cell += check_vector
			if !batman.grid_actors.has_cellv(check_cell):
				dist = 0
				break
			coord_path.append(check_cell)
			dist += 1
		pass
	
	# Distance is based off damage; adjacent to us is 0 damage and +1 per gap of space
	if dist > 0: dmg = (dist - 1)
	if dmg < 0: dmg = 0
	print("longshot dist ",dist," so base dmg ",dmg)
	dmg *= batman.BASE_HP_FACTOR
	
	for cell in coord_path:
		strife.quick_effect(cell, "spark_burst")
	if utils.actorpass(victim):
		strife.damage_actor_at_coord(self, victim.coord, dmg)
		strife.quick_effect(victim, "spark_burstdamage")
	
	end_action()
	pass






