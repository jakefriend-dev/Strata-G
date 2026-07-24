extends MoveAction

var DIST: int = 3
var return_tile: Vector2
var post_jump_rumble_time: float = 0.2

var seq: int = 1



func PREVIEW():
#	print(actor.name,"'s LUNGE PREVIEW start at: ",actor.get_tree().get_frame())
	seq = 1
	
	var target: Vector2 = actor.coord + (actor.my_facing * DIST)
	if !batman.grid_actors.has_cellv(target):
		error_text = "Can't access lunge dest!"
		add_actor(actor, ROWS.ERROR)
#		print("[a] lunge stomp # of bad rows: ",get_all_cells_by_MPD_type(ROWS.BAD).size())
		end_telegraph()
		return
	
	if batman.grid_tiles.get_cellv(target) == batman.tiletypes.PIT:
		error_text = "Lunge dest is pit!"
		add_actor(actor, ROWS.ERROR)
#		print("[b] lunge stomp # of bad rows: ",get_all_cells_by_MPD_type(ROWS.BAD).size())
		end_telegraph()
		return
	
	add_cell(target, ROWS.BAD)
	
	var adj_tiles: Array = support.get_adj_orthagonal_tiles(target)
	for tile in adj_tiles:
		add_cell(tile, ROWS.NEUTRAL)
	
#	print("[c] lunge stomp # of bad rows: ",get_all_cells_by_MPD_type(ROWS.BAD).size())
	passfail = true
	end_telegraph()
	pass

# No need for RE_TELEGRAPH; clear data and run TELEGRAPH again!

func ACT():
#	print(actor.name,"'s LUNGE ACT-",seq," start at: ",actor.get_tree().get_frame())
	
	match seq:
		1:
			ACT_lunge_forward()
			seq += 1
			return
		2:
			ACT_lunge_back()
			seq += 1
			return
	
	end_action() # Should not reach this code! Always go to OTHER funcs and return after, and THOSE funcs must end action!
	pass

func ACT_lunge_forward():
#	print("lunge_forward when neutral cells = ",get_all_cells_by_MPD_type(ROWS.NEUTRAL))
	
	actor.allowed_over_faction_lines = true
	actor.claim_tile()
#	actor.ghost_mode(false)
	
	# Try to return to a random tile (BEFORE enabling ghost mode)
	return_tile = actor.claimed_tile
	var rand_tile: Vector2 = support.get_rand_faction_tile_for_actormoving(actor, actor.faction, true)
	if rand_tile != actor.coord:
#		print(actor.name," ACT_forward() picked new tile whose occupant is ",batman.grid_actors.get_cellv(rand_tile))
		return_tile = rand_tile
		actor.claim_tile(return_tile)
	
	actor.ghost_mode(true)
	
	var dur: float = 0.5
	var ctarget: Vector2 = get_first_cell_by_MPD_type(ROWS.BAD)
	actor.hotjump(ctarget, dur)
	
	yield(utils.yt(dur, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	strife.reset_CAMs()
	strife.set_CAM_admin("knockback", true)
	
	# Damage impact! All adjacent cells take 0+knockback, center cell takes 2
	
	# Center:
	support.log_actorhit_if_occupied(actor, ctarget)
	strife.damage_actor_at_coord(actor, ctarget, actor.dmg(base_damage))
	strife.quick_vfx(ctarget, "dust")
	if support.is_tile_available(ctarget, [actor]):
		support.change_tiletype_single(ctarget, batman.tiletypes.JAGGED)
	
	# Adjacents:
	for atarget in get_all_cells_by_MPD_type(ROWS.NEUTRAL):
		# For testing! Disables orthagonal damage, but instead pushes actors away!
		support.log_actorhit_if_occupied(actor, atarget)
		var motion: Vector2 = atarget - actor.coord
		var victim: Actor = batman.grid_actors.get_cellv(atarget)
		if utils.actorpass(victim):
			strife.store_CAMstep_by_actor(victim, motion)
		
		strife.quick_vfx(atarget, "dust")
	
	var per_tile_dur: float = 0.15
	var total_dur: float = strife.get_total_CAM_dur(per_tile_dur)
	strife.execute_CAMs(actor, per_tile_dur)
	
#	release_targeted_tiles()
	
	if strife.are_CAMs_loaded():
		yield(utils.yt(total_dur, actor), "timeout")
	else:
		yield(utils.yt(post_jump_rumble_time, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	batman.append_action(actor, self)
	end_action()
	pass

func ACT_lunge_back():
	
	var dur: float = 0.5
	
	var occupant_of_dest: Actor = batman.grid_actors.get_cellv(return_tile)
#	print(actor.name," ACT_lunge_back() when is_ghost ",actor.is_ghost," and occupant of lunge dest: ",occupant_of_dest)
	if utils.actorpass(occupant_of_dest):
		# Breakpoint!
		pass
	
	actor.hotjump(return_tile, dur)
	yield(utils.yt(dur, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	actor.ghost_mode(false)
	actor.allowed_over_faction_lines = false
	
	yield(utils.yt(post_jump_rumble_time, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	actor.clear_telegraphed_move()
	end_action()
	pass



