extends Actor
class_name ActorPlayer

var moveset: Dictionary = {} # Post-validation
export (Array, Resource) var loaded_moves: Array = [null, null, null, null, null, null, null, null]

const pstring: String = "PREVIEW"
const astring: String = "ACT"

# ---

func _ready():
	load_moves()
	prep_moveset_on_battle_start()
	batman.connect("action_option_view_changed", self, "run_actop_preview")
	batman.connect("action_step_complete", self, "run_actop_preview")
	pass

func load_moves():
	for move in loaded_moves: if move != null: if move is MoveAction:
		# Basic setup first!
		if move.resource_name == "":
			move.resource_name = utils.get_resource_name(move)
		move.set_local_to_scene(true)
		move.actor = self
		move.APD = APD
		
		if !move.has_method(pstring):
			print(name," can't find PREVIEW() method for move ",move,"! Soft error")
#			continue
		if !move.has_method(astring):
			print(name," can't load move ",move,", no ACT() method!")
			continue
		if moveset.has(move.resource_name):
			print(name," can't load move ",move,", duplicate entry! Already in moveset!")
			continue
		
		moveset[move.resource_name] = move
		pass
	
	print("ALL loaded moves in moveset are: ",moveset)
	pass

func prep_moveset_on_battle_start():
	for move in moveset: if move is MoveAction:
		move.current_turn_uses = 0
		move.current_battle_uses = 0
		if move.initial_cooldown > 0:
			move.current_cooldown = 1 + move.initial_cooldown # +1 to offset start of 1st turn
		else:
			move.current_cooldown = 0
		pass
	
	pass

func prep_moveset_on_turn_start():
	for move in moveset: if move is MoveAction:
		if move.current_cooldown > 0:
			move.current_cooldown -= 0
			print("Cooldown ticked down for ",move," to: ",move.current_cooldown)
		pass
	
	pass

func run_actop_preview():
	if batman.curr_actor != self: return
	if !batman.player_input_validation_checks(): return
	
	APD.clear()
	
	var move: MoveAction = batman.loaded_move
	move.option = batman.highlighted_sub_actop
	
	if move.has_method(pstring):
		move.call(pstring)
		
		APD.generate_cell_highlights()
		pass
	
	APD.ready_to_use = is_player_action_usable(false)
	
	batman.emit_signal("new_action_preview_data_readied", APD)
	pass

# ---

func is_player_action_usable(do_print: bool = true) -> bool:
	if !batman.player_input_validation_checks(): return false
	if batman.curr_actor != self: return false
	
	var move: MoveAction = batman.loaded_move
	
	if !can_afford(move.cost):
		if do_print: print(name," can't afford ",move.cost,"-AP for ",move)
		return false
	if move.current_cooldown > 0:
		if do_print: print(name," still on cooldown for ",move.current_cooldown," turns: ",move)
		return false
	if move.req_successful_preview and !APD.passfail:
		if do_print: print(name," needs APD pass for ",move)
		return false
	if move.uses_per_turn > 0:
		if move.current_turn_uses >= move.uses_per_turn:
			if do_print: print(name," already maxed per-turn uses of ",move)
			return false
	if move.uses_per_battle > 0:
		if move.current_battle_uses >= move.uses_per_battle:
			if do_print: print(name," already maxed per-battle uses of ",move)
			return false
	
	return true
	pass

func attempt_player_char_move(motion: Vector2):
	if !can_afford(COST_WALK): return
	if !support.is_tile_traversable_relative(self, motion): return
	
#	var exact_coord: Vector2 = coord + motion
	
	# Should be valid, then!
	spend(COST_WALK)
	batman.append_action(self, "walk", [motion])
	submit_player_action()
	pass

func attempt_player_char_action():
	if !is_player_action_usable(): return
	
	# Should be valid, then! Adjust our stats/values first
	var move: MoveAction = batman.loaded_move
	move.option = batman.highlighted_sub_actop
	
#	print("going to spend ",move.cost,"-AP when ",action_points,"-AP remain")
	
	move.log_use()
	
	# Now execute!
	batman.append_action(self, move.resource_name)
#	if move.options == 0:
#		batman.append_action(self, move.resource_name)
#	else:
#		batman.append_action(self, move.resource_name, [batman.highlighted_sub_actop])
	
	submit_player_action()
	pass

func submit_player_action():
	emit_signal("player_action_submitted")
	pass

# ---
