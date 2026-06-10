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
	batman.connect("action_option_view_changed", self, "run_actop_preview")
	pass

func prep_options_from_optionstring():
	var moveset_ref: Dictionary = get("moveset") # Lives downstream at the local script level
	
	for opt in action_options: if opt is String: if opt != "":
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
		for key in ["display_name", "display_desc", "options", "cost", "cooldown", "initial_cooldown", "uses_per_turn", "uses_per_battle"]:
			var badflag: bool = false
			if !moveset_ref[opt].has(key):
				print(name,": MAJOR error; ",opt," is set up incorrectly in our moveset; missing key ",key)
				badflag = true
				break
			if badflag: continue
		if valid_action_options.has(opt):
			print(name,": MAJOR error; ",opt," is already in our keys list! No dupes!")
			continue
		
		valid_action_options.append(opt)
		moveset_ref[opt]["keyref"] = opt # Cyclic reference, so that WITHIN the dictionary you also have its key
	
	print(name," has validated options: ",valid_action_options)
	pass

func run_actop_preview():
	if batman.curr_actor != self: return
	if !batman.player_input_validation_checks(): return
	
	APD.clear()
	
	var pstring: String = str("PREVIEW_",batman.loaded_move_name)
	print(pstring)
	if has_method(pstring):
		call(pstring, batman.highlighted_sub_actop)
		
		APD.generate_cell_highlights()
	pass

#func check_for_action_options(who: Actor):
#	if who != self: return
#	if batman.curr_actor != self: return # Redundant, but why not
#
#	# We are the actor! Prep our things
#
#	pass

# ---

func attempt_player_char_move(motion: Vector2):
	if !can_afford(COST_WALK): return
	if !support.is_tile_traversable_relative(self, motion): return
	
#	var exact_coord: Vector2 = coord + motion
	
	# Should be valid, then!
	spend(COST_WALK)
	batman.append_action(self, "walk", [motion])
	submit_player_action()
	pass

func attempt_player_char_basicattack():
	var COST: int = staple_cost
	if !can_afford(COST): return
	
	# Should be valid, then!
	spend(COST)
	batman.append_action(self, "staple_attack")
	submit_player_action()
	pass

func submit_player_action():
	emit_signal("player_action_submitted")
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

