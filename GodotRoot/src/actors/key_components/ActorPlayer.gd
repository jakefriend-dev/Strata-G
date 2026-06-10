extends Actor
class_name ActorPlayer

var staple_attack: String
var staple_cost: int = 1

export (Array, String) var action_options: Array = ["staple_attack"]
export (Dictionary) var test2: Dictionary
var valid_action_options: Array = []

# ---

func _ready():
#	batman.connect("pre_turn_setup", self, "check_for_action_options")
	prep_options_from_optionstring()
	prep_moveset_on_battle_start()
	batman.connect("action_option_view_changed", self, "run_actop_preview")
	batman.connect("action_step_complete", self, "run_actop_preview")
	pass

func prep_options_from_optionstring():
	var moveset_ref: Dictionary = get("moveset") # Lives downstream at the local script level
	
	for opt in moveset_ref.keys(): if opt is String: if opt != "":
		var pstring: String = str("PREVIEW_",opt)
		var astring: String = str("ACT_",opt)
		
		if !has_method(pstring):
			print(name,": Minor error; does not have ",pstring," method, preview will show nothing!")
		if !has_method(astring):
			print(name,": MAJOR error; does not have ",astring," method, action is ineligible!")
			continue
		if !moveset_ref.has(opt):
			print(name,": MAJOR error; ",opt," is not in our moveset!")
			continue
		for key in ["display_name", "display_desc", "options", "cost", "on_use_cooldown", "initial_cooldown", "uses_per_turn", "uses_per_battle", "req_APDpass", "current_cooldown", "current_turn_uses", "current_battle_uses"]:
			var badflag: bool = false
			if !moveset_ref[opt].has(key):
				print(name,": MAJOR error; ",opt," is set up incorrectly in our moveset; missing key ",key)
				badflag = true
				break
			if badflag: continue
			
		if valid_action_options.has(opt):
			print(name,": MAJOR error; ",opt," is already in our keys list! No dupes!")
			continue
		
		moveset_ref[opt]["keyref"] = opt # Cyclic reference, so that WITHIN the dictionary you also have its key
		valid_action_options.append(opt)
	
#	print(name," has validated options: ",valid_action_options)
	pass

func prep_moveset_on_battle_start():
	var moveset_ref: Dictionary = get("moveset")
	for key in moveset_ref.keys():
		moveset_ref[key]["current_turn_uses"] = 0
		moveset_ref[key]["current_battle_uses"] = 0
		moveset_ref[key]["current_cooldown"] = 0+moveset_ref[key]["initial_cooldown"]
	
	set("moveset", moveset_ref)
	pass

func prep_moveset_on_turn_start():
	var moveset_ref: Dictionary = get("moveset")
	print("moveset ref prepped: ",moveset_ref)
	for key in moveset_ref.keys():
		var cooldown: int = moveset_ref[key]["current_cooldown"]
		if cooldown > 0:
			cooldown -= 1
			print("Cooldown ticked down for ",key,", now ",cooldown)
			moveset_ref[key]["current_cooldown"] = cooldown
	set("moveset", moveset_ref)
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
	spend(moveref["cost"])
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

#func ACT_basic_move(dir: Vector2):
##	var actor: Actor = get_actor()
##	print(actor.name,": executing basic move")
#
#	var exact_coord: Vector2 = coord + dir
#	var dur: float = 0.125
#
#	hotmove(exact_coord, dur)
#	yield(utils.yt(dur, self), "timeout")
#	if !batman.is_my_action(self): return
#
#	end_action()
#	pass

func ACT_staple_attack():
	call(str("ACT_"+staple_attack))
	pass

func ACT_basic_shot():
	var victim: Actor = support.find_nearest_actor_in_dir(coord, Vector2.RIGHT)
	if victim == null:
		end_action()
		return
	
	strife.damage_actor_at_coord(self, victim.coord, base_damage)
	
	end_action()
	pass

func ACT_basic_melee():
	var exact_coord: Vector2 = coord + Vector2.RIGHT
	
	strife.damage_actor_at_coord(self, exact_coord, base_damage)
	
	end_action()
	pass

