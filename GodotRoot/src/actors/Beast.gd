extends Actor

var targeted_locs: Array = []
enum {NOT_SET, LUNGE, SHOOT, POST_LUNGE, POST_SHOOT}
var telegraphed_move: int = NOT_SET
var executed_main_attack: bool = false

var lunge_delta_target: Vector2 # A static *relative* reference to the opposite side of the board

var jump_dest_coord: Vector2

const COST_PRE_SHOOT: int = 2
const COST_SHOOT: int = 2
# Shoot+telegraph are 4 combined
const COST_PRE_LUNGE: int = 2
const COST_LUNGE: int = 2
# Lunge+telegraph are 4 combined
const COST_SUPERDEBUFF: int = 3
const COST_REPOJUMP: int = 2
#const COST_ENRAGE: int = 2
const COST_WALK: int = 1
var next_telegraph_cost: int = 0

var get_bonus_action_next_turn: bool = false

# ---

func _ready():
	lunge_delta_target = batman.get_halfboard_size()
	lunge_delta_target.x *= -1
	lunge_delta_target.y = 0
#	set_up_next_turn()
	pass

func pre_turn_setup():
	allowed_over_faction_lines = false
	jump_dest_coord = coord + lunge_delta_target
	executed_main_attack = false
	pass

func prep_next_action():
	# First, check if we've telegraphed anything; if yes, can we follow-through?
	
	if telegraphed_move == LUNGE:
		telegraphed_move = POST_LUNGE
		next_telegraph_cost = COST_PRE_SHOOT
		if can_afford(COST_LUNGE):
			if act.is_tile_traversable_exact(self, jump_dest_coord):
				executed_main_attack = true
				spend(COST_LUNGE)
				batman.append_action(self, "lunge_forward")
				batman.append_action(self, "lunge_back")
				return
			else: release_targeted_tiles()
		else: release_targeted_tiles()
	
	if telegraphed_move == SHOOT:
		telegraphed_move = POST_SHOOT
		next_telegraph_cost = COST_PRE_LUNGE
		if can_afford(COST_SHOOT):
			executed_main_attack = true
			spend(COST_SHOOT)
			batman.append_action(self, "shoot")
			return
		else: release_targeted_tiles()
	
	# Turn-starting telegraph follow-ups are done with; now prioritize turn *ending* telegraphs
	# If we can afford a telegraph and nothing but, that's always what we should do!
	if action_points == next_telegraph_cost:
	
		if telegraphed_move == POST_LUNGE:
			spend(COST_PRE_SHOOT)
			telegraphed_move == SHOOT
			batman.append_action(self, "pre_shoot")
			return
		
		if telegraphed_move == POST_SHOOT:
			spend(COST_PRE_LUNGE)
			telegraphed_move == LUNGE
			batman.append_action(self, "pre_lunge")
			return
	
	#
	# We've accounted for everything telegraph-related; what's left is just playing with AP!
	#
	
	# When we've done a successful main attack, just move around a bit, if we can
	if executed_main_attack:
		
		# The walk check
		var walk_coord: Vector2
		var walk_conditions_met: bool = false
		if can_afford(COST_WALK):
			walk_coord = act.get_rand_adj_tile_for_actormoving(coord, self)
			if walk_coord != coord:
				walk_conditions_met = true
		
		# In the condition we have TONS of action points, do a superdebuff!
		if walk_conditions_met and can_afford(COST_WALK + next_telegraph_cost + COST_SUPERDEBUFF):
			spend(COST_SUPERDEBUFF)
			batman.append_action(self, "debuff")
			return
		
		# The repo check - typically we don't want to do this unless we can also telegraph
		var repo_coord: Vector2
		var repo_normal_conditions_met: bool = false
		var repo_emergency_conditions_met: bool = false
		if can_afford(COST_REPOJUMP):
			repo_coord = act.get_rand_faction_tile_for_actormoving(self, faction)
			if repo_coord != coord:
				repo_emergency_conditions_met = true
				if can_afford(COST_REPOJUMP + next_telegraph_cost):
					repo_normal_conditions_met = true
		
		if walk_conditions_met:
			# If we can do both easily, err on the side of walking 2/3rds of the time
			if repo_normal_conditions_met:
				var walkpref: bool = (rand_range(0.0, 3.0) <= 2.0)
				if walkpref:
					spend(COST_WALK)
					batman.append_action(self, "walk", [walk_coord])
					return
				else:
					spend(COST_REPOJUMP)
					batman.append_action(self, "repo_jump", [repo_coord])
					return
			# Otherwise, just default to walking
			spend(COST_WALK)
			batman.append_action(self, "walk", [walk_coord])
			return
		
		# If we can't random-walk (we're stuck), repojump if you can
		elif repo_emergency_conditions_met:
			spend(COST_REPOJUMP)
			batman.append_action(self, "repo_jump", [repo_coord])
			return
		
		return # No attempting to squeeze in an additional main attack!
	
	# If we FAILED to execute a main attack this turn so far, including if we weren't able to set one up last turn, pick a different option we typically wouldn't do

	# If we can afford to debuff the party AND do a telegraph after, do that
	if can_afford(next_telegraph_cost + COST_SUPERDEBUFF):
		executed_main_attack = true
		spend(COST_SUPERDEBUFF)
		batman.append_action(self, "debuff")
		return
	
	# Otherwise, stop attempting to execute a main attack, then give up and cycle again
	executed_main_attack = true
	prep_next_action()
	pass

func post_all_action_prep():
	if get_bonus_action_next_turn:
		get_bonus_action_next_turn = false
		add_bonus_actions(1)
		start_effect("keeps_bonus_action", 1, false)
	pass

# ---

func ACT_pre_shoot():
	
	
	end_action()
	pass

func ACT_shoot():
	
	
	end_action()
	pass

func ACT_pre_lunge():
	
	
	end_action()
	pass

func ACT_lunge_forward():
	
	
	end_action()
	pass

func ACT_lunge_back():
	
	
	end_action()
	pass

func ACT_debuff():
	get_bonus_action_next_turn = true
	
	for actor in batman.living_actors: if actor is Actor:
		if actor == self: continue # We handle ourselves later!
		
		# Enemies gain 1AP, playerside loses 1AP
		if actor.faction == batman.factions.ENEMY:
			actor.add_bonus_actions(1)
		elif actor.faction == batman.factions.PLAYER:
			actor.spend(1)
	
	end_action()
	pass

func ACT_repo_jump():
	
	
	end_action()
	pass

func ACT_walk(exact_coord: Vector2):
	var dur: float = 0.5
	
	act.hotmove(self, exact_coord, dur)
	yield(utils.yt(dur, self), "timeout")
	if !batman.is_my_turn(self): return
	
	end_action()
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
