extends ActorEnemy

#var targeted_locs: Array = []
#enum {NOT_SET, LUNGE, SHOOT, POST_LUNGE, POST_SHOOT}
#var OLD_telegraphed_move: int = NOT_SET
var lunge_vs_spit_coin: bool
var did_main_attack: bool = false
var readied_telegraph: bool = false

#var lunge_delta_target: Vector2 # A static *relative* reference to the opposite side of the board
#var jump_dest_coord: Vector2
var post_jump_rumble_time: float = 0.2
#var lunge_return_tile: Vector2

#const COST_PRE_SHOOT: int = 2
#const COST_SHOOT: int = 2
## Shoot+telegraph are 4 combined
#const COST_PRE_LUNGE: int = 2
#const COST_LUNGE: int = 2
## Lunge+telegraph are 4 combined
#const COST_SUPERDEBUFF: int = 3
#const COST_REPOJUMP: int = 2
var next_telegraph_cost: int = 0

var get_bonus_action_next_turn: bool = false



# ---

func _ready():
	pass

func pre_combat_setup():
#	print("Beast pre combat setup!")
	if utils.coin_flip():
		lunge_vs_spit_coin = false # NEXT one is lunge, so THIS one is spit
		prime_npc_move(moveset["SPIT_ATTACK"], true)
	else:
		lunge_vs_spit_coin = true
		prime_npc_move(moveset["LUNGE_STOMP"], true)
		
	pass

func pre_turn_setup():
	print("\n---\n")
	allowed_over_faction_lines = false
	did_main_attack = false
	readied_telegraph = false
	
#	print("starting our turn when our telegraphed move is ",OLD_telegraphed_move)
	pass

func prep_next_action():
	if readied_telegraph: # Telegraphing is always the END of our turn
		return
	
	
	
	# FIRST: If we've telegraphed something last turn, attempt to follow through!
	if telegraphed_move != null: if !did_main_attack: 
		# Prep for next time!
		lunge_vs_spit_coin = !lunge_vs_spit_coin
#		print("Flipped lunge_vs_spit_coin to: ",lunge_vs_spit_coin)
		
		# ...whether or not it actually plays out!
		if telegraphed_move.totality_check(self, true):
			did_main_attack = true
			prime_npc_move(telegraphed_move)
			return
		else:
			clear_telegraphed_move()
	
	if telegraphed_move == null and !did_main_attack and action_points == 5:
		print("BEAST has 5 AP, no telegraphed move, and has NOT done its main attack yet")
	
	# (One way or the other, AFTER this point, telegraphed_move is null)
	
	
	# SECOND: Once you're down to EXACTLY the cost of the next telegraph, that's your priority!
	var next_main_attack: MoveAction
	if lunge_vs_spit_coin:
		next_main_attack = moveset["LUNGE_STOMP"]
	else:
		next_main_attack = moveset["SPIT_ATTACK"]
	
	if action_points == next_main_attack.effective_cost():
		readied_telegraph = true # Flag it as 'we tried' whether or not it executes
		if next_main_attack.totality_check(self, true):
			prime_npc_move(next_main_attack)
			return
	
	
	
	# THIRD: If we've FAILED to do our main attack this turn, try some nonstandard options (only once!)
	if !did_main_attack:
		did_main_attack = true # Enforces the 'only once'
		
		# If we can afford to debuff the party AND do a telegraph after, do that
		var combo_cost: int = next_main_attack.effective_cost() + moveset["ACTION_STEAL_EFFECT"].effective_cost()
		if can_afford(combo_cost):
			if moveset["ACTION_STEAL_EFFECT"].totality_check():
				prime_npc_move(moveset["ACTION_STEAL_EFFECT"])
				return
	
	
	
	# FOURTH: At this point, you can do as you like with the AP remaining.
	# (Which is mostly sort of moving around vaguely)
	
	var can_walk: bool = randomwalk_if_possible(false) && LM["WALK"].usability_check(self) # Confirms at least ONE direction is possible, but doesn't actually walk yet
	if can_walk:
		if action_points < (LM["WALK"].effective_cost() + next_main_attack.effective_cost()):
			can_walk = false
	var can_repo: bool = moveset["REPO_JUMP"].totality_check() # Confirms we can move to at least one OTHER tile
	if can_repo:
		if action_points < (moveset["REPO_JUMP"].effective_cost() + next_main_attack.effective_cost()):
			can_repo = false
	
	
	if can_walk:
		if can_repo: # Both! Choose randomly (weighted!)
			if (rand_range(0.0, 4.0) <= 3.0):
				randomwalk_if_possible()
				return
			else:
				prime_npc_move(moveset["REPO_JUMP"])
				return
		
		else: # ONLY walk!
			randomwalk_if_possible()
			return
	
	elif can_repo: # ONLY repo!
		prime_npc_move(moveset["REPO_JUMP"])
		return
	
	# And if we can't walk OR repo, well - maybe just skip ahead to the telegraph?
	readied_telegraph = true # Once we get to this point, turn's over either way
	if next_main_attack.totality_check(self, true):
		prime_npc_move(next_main_attack)
		return
	
	pass








