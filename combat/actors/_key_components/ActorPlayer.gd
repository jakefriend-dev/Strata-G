extends Actor
class_name ActorPlayer

var moveset: Dictionary = {} # Post-validation
var move_layout: Array2D
export (Array, Resource) var loaded_moves: Array = [null, null, null, null, null, null, null]

const pstring: String = "PREVIEW"
const astring: String = "ACT"

# ---

func _ready():
	load_moves()
	prep_moveset_on_battle_start()
	batman.connect("action_option_view_changed", self, "run_move_preview")
	batman.connect("action_step_complete", self, "run_move_preview")
	pass

func load_moves():
	var row: int = 0
	var col: int = 0
	move_layout = Array2D.new()
	move_layout.resize(2, 4)
	
	for move in loaded_moves: if move != null: if move is MoveAction:
		# Basic setup first!
		if move.resource_name == "":
			move.resource_name = utils.get_resource_name(move)
		move.set_local_to_scene(true)
		move.actor = self
		move.initialize_MPD()
		
		# Validations!
		if !move.has_method(pstring):
			print(name," can't find PREVIEW() method for move ",move,"! Soft error")
		if !move.has_method(astring):
			print(name," can't load move ",move,", no ACT() method!")
			continue
		if moveset.has(move.resource_name):
			print(name," can't load move ",move,", duplicate entry! Already in moveset!")
			continue
		if move.option_image == null:
			print(name," can't load move ",move,", no option_image!")
			continue
		
		# Pass!
		moveset[move.resource_name] = move
		move.plausible_variants = strife.aimflower_vectors_from_file(move.option_image.resource_path)
		
		# Pass to the layout 2x4 and update the position data!
#		print(name," col:row ",col,":",row)
		move_layout.set_cell(col, row, move)
		
		col += 1
		if col > 1:
			col = 0
			row += 1
		pass
	
#	print(name," move_layout: ",move_layout)
#	print("ALL loaded moves in moveset are: ",moveset)
	pass

func prep_moveset_on_battle_start():
#	print(name," battle start")
	for key in moveset:
		var move: MoveAction = moveset[key]
		move.current_turn_uses = 0
		move.current_battle_uses = 0
		if move.initial_cooldown > 0:
			move.current_cooldown = move.initial_cooldown
		else:
			move.current_cooldown = 0
		if move.has_method("ONE_TIME_SETUP"):
			move.call("ONE_TIME_SETUP")
		pass
	
	pass

func prep_moveset_on_turn_start():
#	print(name," turn start")
	for key in moveset:
		var move: MoveAction = moveset[key]
		if move.current_turn_uses > 0 and move.uses_per_turn > 0:
			print(move," unlocked as per-turn uses resets")
		move.current_turn_uses = 0
#		print("reset ",move," current_turn_uses")
		pass
	
	pass

func prep_moveset_on_turn_end():
#	print(name," turn end")
	for key in moveset:
		var move: MoveAction = moveset[key]
		if move.current_cooldown > 0:
			move.current_cooldown -= 1
			print("Cooldown ticked down for ",move," to: ",move.current_cooldown)
	pass

func clear_all_move_previews():
	if batman.curr_actor != self: return
	
	for key in moveset.keys():
		moveset[key].clear_MPD()
	pass

func run_move_preview(is_brand_new_move_selected: bool = false):
	if batman.curr_actor != self: return
	if !batman.player_input_validation_checks(): return
	
	var move: MoveAction = batman.loaded_move
	if move == null: return
	
	move.clear_MPD()
	move.prepare_actualized_variants()
	batman.assert_player_variant_against_move(move, is_brand_new_move_selected)
	
	if move.has_method(pstring):
#		print("  --  New Preview  --")
		move.call(pstring)
		
		move.generate_cell_highlights()
		pass
	
	move.ready_to_use = is_player_action_usable(false)
	
	batman.emit_signal("new_action_preview_data_readied", move)
	pass

# ---

func is_player_action_usable(do_print: bool = true) -> bool:
	if !batman.player_input_validation_checks(): return false
	if batman.curr_actor != self: return false
	
	var move: MoveAction = batman.loaded_move
	
	if move == null:
		# Sometimes 'valid' when it's a custom script, so we have to check
		# (but either way, this is still not a 'usable move' so return false!)
		
		if batman.field.movewindow.attempt_to_run_moveoption_custom_function():
#			print("sfx good")
			pass
		else:
#			print("sfx bad")
			pass
		
		return false
	
	if !can_afford(move.cost):
		if do_print: print(name," can't afford ",move.cost,"-AP for ",move)
		return false
	if move.current_cooldown > 0:
		if do_print: print(name," still on cooldown for ",move.current_cooldown," turns: ",move)
		return false
	if move.req_successful_preview and !move.passfail:
		if do_print: print(name," needs preview pass for ",move)
		return false
	if move.actualized_variants.empty():
		if do_print: print(name," has zero possible variants for ",move," at this position!")
		return false
	if move.uses_per_turn > 0: # Ignore if unlimited
		if move.current_turn_uses >= move.uses_per_turn:
			if do_print: print(name," already maxed per-turn uses of ",move)
			return false
	if move.uses_per_battle > 0: # Ignore if unlimited
		if move.current_battle_uses >= move.uses_per_battle:
			if do_print: print(name," already maxed per-battle uses of ",move)
			return false
	
	return true
	pass

func attempt_player_char_move(motion: Vector2):
	if !can_afford(COST_WALK): return
	if !support.is_tile_traversable_relative(self, motion): return
	
	# Should be valid, then!
#	spend(COST_WALK)
	inc_action_cracking()
	batman.append_action(self, "walk", [motion])
	submit_player_action(false)
	pass

func attempt_player_char_action():
	if !is_player_action_usable(): return
	
	# Should be valid, then! Adjust our stats/values first
	var move: MoveAction = batman.loaded_move
	
#	print("going to spend ",move.cost,"-AP when ",action_points,"-AP remain")
	
	move.log_move_use()
	
	# Now execute!
	batman.append_action(self, move.resource_name)
	
	submit_player_action(move.motion_type == move.motionchecks.REST)
	pass

func submit_player_action(is_rest: bool):
	emit_signal("player_action_submitted")
	
	if is_rest:
		yield(batman, "action_step_complete")
		if !batman.is_my_action(self): return
		
		strife.TILE_event_rest(self, coord)
	pass

# ---
