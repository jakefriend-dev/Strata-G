extends MoveAction

var DIST: int = 3

# Only uncomment this method if you want to bypass "normal" variant loading
#func LOAD_VARIANTS():
#	for vec in plausible_variants:
#		if batman.grid_actors.has_cellv(actor.coord + vec + Vector2(DIST, 0)):
#			actualized_variants.append(vec)
#	pass


func PREVIEW():
#
#	var check_vector: Vector2 = batman.loaded_variant
#
#	var unoccupieds: Array = support.list_all_unoccupied_tiles_in_dir(actor.coord, check_vector)
#	if !unoccupieds.empty():
#		add_arrow(actor.coord, unoccupieds.back(), ROWS.PASS)
#
#	var victim: Actor = support.find_nearest_actor_in_dir(actor.coord, check_vector)
#	if !utils.actorpass(victim): return
#
#	add_actor(victim, ROWS.BAD)
#	passfail = true
	pass

func TELEGRAPH():
	var target: Vector2 = actor.coord + (actor.my_facing * DIST)
	if !batman.grid_actors.has_cellv(target):
		error_text = "Can't lunge off battlefield!"
		add_actor(actor, ROWS.ERROR)
		return
	
	add_cell(target, ROWS.BAD)
	var adj_tiles: Array = support.get_adj_orthagonal_tiles(target)
	for tile in adj_tiles:
		add_cell(tile, ROWS.NEUTRAL)
	pass

# No need for RE_TELEGRAPH; clear data and run TELEGRAPH again!

func ACT():
#	# Shoot a target in your line-of-sight; higher damage per tile travelled
#	var victim: Actor = get_first_actor_by_MPD_type(ROWS.BAD)
#
#	if utils.actorpass(victim):
#		strife.damage_actor_at_coord(actor, victim.coord, actor.dmg(base_damage), ["piercing"])
#		strife.quick_vfx(victim, "spark_burst")
	
	end_action() # Should not reach this code! Always go to OTHER funcs and return after, and THOSE funcs must end action!
	pass

func ACT_forward():
	print("lunge_forward")
	actor.allowed_over_faction_lines = true
	actor.claim_tile()
#	actor.ghost_mode(false)
	
	
#
#	# Attempt to return to a random tile (BEFORE enabling ghost mode)
#	lunge_return_tile = claimed_tile
#	var rand_tile: Vector2 = support.get_rand_faction_tile_for_actormoving(self, faction, true)
#	if rand_tile != coord:
#		print(name," ACT_lunge_forward() picked new tile whose occupant is ",batman.grid_actors.get_cellv(rand_tile))
#		lunge_return_tile = rand_tile
#		claim_tile(lunge_return_tile)
#
#	ghost_mode(true)
#
#	var dur: float = 0.5
#
#	hotjump(jump_dest_coord, dur)
#	yield(utils.yt(dur, self), "timeout")
#	if !batman.is_my_action(self): return
#
#	strife.reset_CAMs()
#	strife.set_CAM_admin("knockback", true)
#
#	# Damage impact! All adjacent cells take 1 base, our cell takes 2 base
#	for target in targeted_tiles:
#		if target == coord: # Center tile
#			strife.damage_actor_at_coord(self, target, dmg(2))
#			strife.quick_vfx(target, "dust")
#			if support.is_tile_available(target, [self]):
#				support.change_tiletype_single(target, batman.tiletypes.JAGGED)
#		else: # Adjacent tiles
#			# For testing! Disables orthagonal damage, but instead pushes actors away!
#			var motion: Vector2 = target - coord
#			var victim: Actor = batman.grid_actors.get_cellv(target)
#			if utils.actorpass(victim):
#				strife.store_CAMstep_by_actor(victim, motion)
#
#			strife.quick_vfx(target, "dust")
#
#	var per_tile_dur: float = 0.15
#	var total_dur: float = strife.get_total_CAM_dur(per_tile_dur)
#	strife.execute_CAMs(self, per_tile_dur)
#
#	release_targeted_tiles()
#
#	if strife.are_CAMs_loaded():
#		yield(utils.yt(total_dur, self), "timeout")
#	else:
#		yield(utils.yt(post_jump_rumble_time, self), "timeout")
#	if !batman.is_my_action(self): return
	pass

func ACT_back():
	pass



