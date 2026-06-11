extends Actor
class_name ActorPlayer

var moveset: Dictionary = {} # Post-validation
export (Array, Resource) var loaded_moves: Array = [null, null, null, null, null, null, null, null]

# ---

func _ready():
#	batman.connect("pre_turn_setup", self, "check_for_action_options")
	load_moves()
#	prep_options_from_optionstring()
	prep_moveset_on_battle_start()
	batman.connect("action_option_view_changed", self, "run_actop_preview")
	batman.connect("action_step_complete", self, "run_actop_preview")
	pass

func load_moves():
	for move in loaded_moves: if move != null: if move is PlayerAction:
		# Basic setup first!
		if move.resource_name == "":
			move.resource_name = utils.get_resource_name(move)
		move.set_local_to_scene(true)
		move.actor = self
		move.APD = APD
		
		if !move.has_method("PREVIEW"):
			print(name," can't find PREVIEW() method for move ",move,"! Soft error")
#			continue
		if !move.has_method("ACT"):
			print(name," can't load move ",move,", no ACT() method!")
			continue
		if moveset.has(move.resource_name):
			print(name," can't load move ",move,", duplicate entry! Already in moveset!")
			continue
		
		moveset[move.resource_name] = move
		pass
	
	print("ALL loaded moves in moveset are: ",moveset)
	pass

func prep_options_from_optionstring():
#	var moveset_ref: Dictionary = get("moveset") # Lives downstream at the local script level
#
#	for opt in moveset_ref.keys(): if opt is String: if opt != "":
#		var pstring: String = str("PREVIEW_",opt)
#		var astring: String = str("ACT_",opt)
#
##		if !has_method(pstring):
##			print(name,": Minor error; does not have ",pstring," method, preview will show nothing!")
##		if !has_method(astring):
##			print(name,": MAJOR error; does not have ",astring," method, action is ineligible!")
##			continue
##		if !moveset_ref.has(opt):
##			print(name,": MAJOR error; ",opt," is not in our moveset!")
##			continue
#		for key in ["display_name", "display_desc", "options", "cost", "on_use_cooldown", "initial_cooldown", "uses_per_turn", "uses_per_battle", "req_APDpass", "current_cooldown", "current_turn_uses", "current_battle_uses"]:
#			var badflag: bool = false
#			if !moveset_ref[opt].has(key):
#				print(name,": MAJOR error; ",opt," is set up incorrectly in our moveset; missing key ",key)
#				badflag = true
#				break
#			if badflag: continue
#
#		if valid_action_options.has(opt):
#			print(name,": MAJOR error; ",opt," is already in our keys list! No dupes!")
#			continue
#
#		moveset_ref[opt]["keyref"] = opt # Cyclic reference, so that WITHIN the dictionary you also have its key
#		valid_action_options.append(opt)
#
##	print(name," has validated options: ",valid_action_options)
	pass

func prep_moveset_on_battle_start():
	for move in moveset: if move is PlayerAction:
		move.current_turn_uses = 0
		move.current_battle_uses = 0
		if move.initial_cooldown > 0:
			move.current_cooldown = 1 + move.initial_cooldown # +1 to offset start of 1st turn
		else:
			move.current_cooldown = 0
		pass
	
#	var moveset_ref: Dictionary = get("moveset")
#
#	for key in moveset_ref.keys():
#		moveset_ref[key]["current_turn_uses"] = 0
#		moveset_ref[key]["current_battle_uses"] = 0
#		moveset_ref[key]["current_cooldown"] = 0+moveset_ref[key]["initial_cooldown"]
#
#	set("moveset", moveset_ref)
	pass

func prep_moveset_on_turn_start():
	for move in moveset: if move is PlayerAction:
		if move.current_cooldown > 0:
			move.current_cooldown -= 0
			print("Cooldown ticked down for ",move,": now ",move.current_cooldown)
		pass
	
#	var moveset_ref: Dictionary = get("moveset")
#
#	for key in moveset_ref.keys():
#		var cooldown: int = moveset_ref[key]["current_cooldown"]
#		if cooldown > 0:
#			cooldown -= 1
#			print("Cooldown ticked down for ",key,", now ",cooldown)
#			moveset_ref[key]["current_cooldown"] = cooldown
#
#	set("moveset", moveset_ref)
	pass

func run_actop_preview():
	if batman.curr_actor != self: return
	if !batman.player_input_validation_checks(): return
	
	APD.clear()
	
	var pstring: String = str("PREVIEW_",batman.loaded_move_name)
	print(pstring)
	if has_method(pstring):
		if batman.loaded_move_ref["options"] == 0:
			call(pstring)
		else:
			call(pstring, batman.highlighted_sub_actop)
		
		APD.generate_cell_highlights()
		pass
	
	APD.ready_to_use = is_player_action_usable(false)
	
	batman.emit_signal("new_action_preview_data_readied", APD)
	pass

#func check_for_action_options(who: Actor):
#	if who != self: return
#	if batman.curr_actor != self: return # Redundant, but why not
#
#	# We are the actor! Prep our things
#
#	pass

# ---

func is_player_action_usable(do_print: bool = true) -> bool:
	if !batman.player_input_validation_checks(): return false
	if batman.curr_actor != self: return false
	
	var moveref: Dictionary = get_current_moveref() # Not duplicating, so FYI linked!
	
	var COST: int = moveref["cost"]
	if !can_afford(COST):
		if do_print: print(name," can't afford ",COST,"-AP for ",moveref["keyref"])
		return false
	
	if moveref["current_cooldown"] > 0:
		if do_print: print(name," still on cooldown for ",moveref["current_cooldown"]," turns: ",moveref["keyref"])
		return false
	if moveref["req_APDpass"] and !APD.passfail:
		if do_print: print(name," needs APD pass for ",moveref["keyref"])
		return false
	if moveref["uses_per_turn"] > 0:
		if moveref["current_turn_uses"] >= moveref["uses_per_turn"]:
			if do_print: print(name," already maxed per-turn uses of ",moveref["keyref"])
			return false
	if moveref["uses_per_battle"] > 0:
		if moveref["current_battle_uses"] >= moveref["uses_per_battle"]:
			if do_print: print(name," already maxed per-battle uses of ",moveref["keyref"])
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
	var moveref: Dictionary = get_current_moveref() # Not duplicating, so FYI linked!
	var COST: int = moveref["cost"]
#	if !can_afford(COST): return
	
#	print("going to spend ",COST,"-AP when ",action_points,"-AP remain")
	
	spend(COST)
	if moveref["on_use_cooldown"] > 0:
		moveref["current_cooldown"] = 1+moveref["on_use_cooldown"] # +1 to neutralize rest of turn!
	moveref["current_turn_uses"] = 1+moveref["current_turn_uses"]
	moveref["current_battle_uses"] = 1+moveref["current_battle_uses"]
	update_current_moveref(moveref)
	
	# Now execute!
	if moveref["options"] == 0:
			batman.append_action(self, batman.loaded_move_name)
	else:
		batman.append_action(self, batman.loaded_move_name, [batman.highlighted_sub_actop])
	
	submit_player_action()
	pass

func submit_player_action():
	emit_signal("player_action_submitted")
	pass

func get_current_moveref() -> Dictionary:
	return get("moveset")[batman.loaded_move_name]

func update_current_moveref(moveref: Dictionary):
	var temp_moveset: Dictionary = get("moveset")
	temp_moveset[batman.loaded_move_name] = moveref
	set("moveset", temp_moveset)
	pass

# ---
