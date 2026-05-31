extends Actor

var targeted_locs: Array = []
enum {NOT_SET, LUNGE, SHOOT}
var telegraphed_move: int = NOT_SET
var lunge_delta_target: Vector2

var jump_dest_coord: Vector2

func _ready():
	lunge_delta_target = batman.get_halfboard_size()
	lunge_delta_target.x *= -1
	lunge_delta_target.y = 0
	set_up_next_turn()
	pass

func begin_turn():
	var _start_position: Vector2 = coord
	
	match telegraphed_move:
		LUNGE: do_lunge()
		
		SHOOT: do_shoot()
	
	# Jump to a new position; OG position is fallback
	var new_dest: Vector2 = act.get_rand_faction_tile_for_actormoving(self, faction)
	if new_dest != coord:
		act.prep_exact_move(self, new_dest)
	act.start_action_queue(self)
	set_up_next_turn()
	pass

func do_lunge():
	# Damage other side (no visual)
	var opposite: Vector2 = coord + lunge_delta_target
	act.prep_shaped_attack(self, targeted_locs, true)
	act.prep_tiletype_changes(self, [opposite], batman.tiletypes.JAGGED)
	pass

func do_shoot():
	act.prep_shaped_attack(self, targeted_locs, false)
	pass

func set_up_next_turn():
	targeted_locs.clear()
	telegraphed_move = NOT_SET
	
	if rand_range(0.0, 1.0) <= 0.35:
		telegraphed_move = LUNGE
		if !lunge_viability_check(): # This actually sets up the lunge attack (if valid)
			telegraphed_move = SHOOT
	else:
		telegraphed_move = SHOOT
	
	if telegraphed_move != SHOOT: return
	
	var player_tiles: Array = act.get_all_tiles_by_faction(batman.factions.PLAYER)
	player_tiles.shuffle()
	targeted_locs.append(player_tiles.pop_front())
	targeted_locs.append(player_tiles.pop_front())
	if rand_range(0.0, 1.0) <= 0.6:
		targeted_locs.append(player_tiles.pop_front()) # Common chance of a 3rd bullet
		if rand_range(0.0, 1.0) <= 0.1:
			targeted_locs.append(player_tiles.pop_front()) # TINY chance of a 4th bullet
	
	print(name," prepping Shoot! Targeting: ",targeted_locs)
	pass

func lunge_viability_check() -> bool:
	var opposite: Vector2 = coord + lunge_delta_target
	if batman.grid_tiles.get_cellv(opposite) == batman.tiletypes.PIT:
		return false
	
	targeted_locs.append(opposite)
	targeted_locs.append_array(act.get_adj_orthagonal_tiles(opposite))
	
	print(name," prepping Lunge! Targeting: ",targeted_locs)
	
	return true
