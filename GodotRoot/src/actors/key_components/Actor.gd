extends Node2D
class_name Actor

onready var sprite: Sprite = $ArtMgr/HFlipper/Sprite
onready var hflipper: Node2D = $ArtMgr/HFlipper
onready var shadow: ColorRect = $ArtMgr/Shadow
onready var aniplayer: AnimationPlayer = $ArtMgr/AnimationPlayer

#var res_lib_helper = preload("res://src/actors/action_libraries/ALib1_Helper.gd")
#var res_lib_general = preload("res://src/actors/action_libraries/ALib2_General.gd")
#var res_lib_player = preload("res://src/actors/action_libraries/ALib3_Player.gd")
#var res_lib_enemy = preload("res://src/actors/action_libraries/ALib4_Enemy.gd")

var lib_helper:  ActionLibrary # Baseline helper functions like "Find nearest PC in dir" or "get 3x3 coords"
var lib_general: ActionLibrary # Common behaviour/actions anyone can use, like walking 1 tile or common buffs
var lib_player:  ActionLibrary # Common players-only shared behaviour/actions
var lib_enemy:   ActionLibrary # Common enemies-only shared behaviour/actions


enum initspeeds {
	DOES_NOT_ACT, # Things like rocks
	# ENEMIES:
	AUTOLAST,     # Last no matter what; scripted use case
	SLOW_ENEMY,         # Behind Player3
	SLOW_PLAYER,
	MEDIUM_ENEMY,       # Behind Player2
	MEDIUM_PLAYER,
	FAST_ENEMY,         # Behind Player1
	FAST_PLAYER,
	AUTOFIRST,    # First no matter what; we are only faster than P1 in scripted circumstances
	#
}
export (initspeeds) var first_initiative: int = initspeeds.MEDIUM_ENEMY
export (initspeeds) var second_initiative: int = initspeeds.DOES_NOT_ACT
export (initspeeds) var third_initiative: int = initspeeds.DOES_NOT_ACT
	# An actor can optionally have up to 3 turns, for a boss; matching the party
var variance_initiative: float  = -1.0 # Cued by batman at start of combat; percentage from 0-99%

var active: bool = true # When false, cannot act. Depletion of health should auto-set this, unless we want someone to have a post-death action, or a post-death health increase reaction for a second phase.

export var max_health: int = 4
var health: int = 4

export var max_shield: int = 0
var shield: int = 0

var bonus_shield: int = 0 # Generally never starts with any, I think?

export var ofc_name: String = "--"
var numerated_name: String = ""

enum bui_tiers {FULL, JUST_PIPS, JUST_HEALTH, INVIS_UNTIL_HIT, NOTHING_EVER}
export (bui_tiers) var bui_level: int = bui_tiers.FULL
var bui: Node2D

export var base_action_points: int = 4 # Used for movement AND attacks!
var action_points: int = 0 # Refreshed at the top of each turn! And start of combat
var bonus_actions: int = 0 # Can be added to in buffs and the like!

var actions_completed_this_turn: int = 0 # An action is what we think of as an attack;
										# like all 3 steps of Doggo's charge attack is 1 action
var turns_completed_this_round: int = 0 # Includes interruptions, just if you had a turn at all
var turns_completed_total: int = 0

export var base_damage: int = 1 # For attack shortcuts for simple mobs (gets auto-factored)
var bonus_damage: int = 0

enum factions { # Local copy of TurnMgr, must be an exact duplicate!
	NEUTRAL,
	PLAYER,
	ENEMY,
}
export (factions) var faction: int = factions.ENEMY # Enemy if not manually set
var is_facing_left: bool = true # Default true for enemies; false for party

# A list of effects for tracking and live usage
var ongoing_turn_effects: Dictionary = {
	# All ongoing effects are in the format: [STRING key, INT ticks remaining]
	# Any string inc custom stuff can be used; if it does nothing it'll just be ignored
	# If an effect already exists when a new one is added, it'll set to the highest of either ticks
	
	# A call is made each START and END of turn
	# If you want 'only for the rest of this turn,' mark 1 tick
	# If you want 'until the start of next turn' like a superguard, mark 2 ticks
	# If you want 'the rest of this turn until the end of the next' like rage, mark 3 ticks
	
	# Generally for SELF-EFFECTS you want a formula of ((X-1) + Y), where:
		# X is the total number of rounds you want the effect to last (including the current one)
		# Y is a int(bool) where 1 if it ends at the end of your turn
}
# Concluded effects are logged by the ROUND as a key, and an array of the effects as a value
var concluded_effects: Dictionary = {
	# Example:
	# 3: ["poison", "power_surge"],
	# 5: ["enrage"],
}

enum weightclasses {
	HOVER,  # Flying; not affects by the ground beneath it at ALL. Allowed to enter pit tiles!
	LIGHT,  # Doesn't sink into certain tiles; immediately moved by wind; doesn't break lilypads?
	NORMAL, # Standard; affected by things as usual
	HEAVY,  # Unaffected by knockback, jagged tiles, or wind; always sinks
}

# Defaults first; manually set
export (weightclasses) var def_weight: int = weightclasses.NORMAL

#export var def_hovering:			bool = false # Not affected by ground type or pits at all
#export var def_lightweight:			bool = false # Not affected by tiles that you sink in, like mud
#export var def_heavyweight:			bool = false # Not affected by wind OR knockback
export var def_unmovable:			bool = false # Not affected by ANY external factors! (Can still move ITSELF of course)
export var def_immune_jagged:		bool = false # Doesn't take damage or AP penalties from jaggies
export var def_immune_fire:			bool = false # Not affected by ember floors
export var def_immune_water:		bool = false # Not slowed by water tiles (even lightweights are)
export var def_immune_sand:			bool = false # Doesn't sink or take penalty from sand
export var def_immune_mud:			bool = false # Doesn't take penalty from mud
export var def_immune_ice:			bool = false # Doesn't slide on ice
export var def_immune_poison:		bool = false # Doesn't take poison damage
export var def_immune_magnet:		bool = false # Not pulled by magnet tiles
export var def_immune_elec:			bool = false # Doesn't take elec damage on static traps

var weight: int
#var is_hovering: bool
#var is_lightweight: bool
#var is_heavyweight: bool
var is_unmovable: bool
var is_immune_jagged: bool
var is_immune_fire: bool
var is_immune_water: bool
var is_immune_sand: bool
var is_immune_mud: bool
var is_immune_ice: bool
var is_immune_poison: bool
var is_immune_magnet: bool
var is_immune_elec: bool

var is_ghost: bool = false # When true, allowed to break many rules. You almost ALWAYS turn this off at the end of a turn; meant as a temporary thing for like a charge-through attack.
var just_exited_ghost_mode: bool = false # Helps us bypass some errors

var allowed_over_faction_lines: bool = false
export var keep_claims_at_eot: bool = false # Set true for the RARE cases (like a missile) where you don't want to wipe its claim at the end of a turn

var targeted_tiles: Array = [] # Just an array of Vector2 coords that is fed to BatMan
var vis_object: Node2D # Typically the parent of all the visual stuff that has Z height

# Convenience references; duplicate data to batman.grid_actors but DRIVEN FROM HERE (important)
var last_pos: Vector2 = Vector2.ZERO
var coord: Vector2
var prior_actionstep_coord: Vector2 # Update this at the end of every actionstep for every actor! This helps us understand what happened this actionstep for tiletype changes
var claimed_tile: Vector2 = Vector2.ZERO

var moving_style: int = strife.moves.NOT_MOVING # All mobs should set this every action (actionstep?), semi-automatically (ie. defaulting to NOT_MOVING when not specified)


signal on_shield_consumed(is_melee) # Shield consumed at all
signal on_shield_broken_through(is_melee) # Shield depleted, and damage surpassed it
signal on_shield_broken_held(is_melee) # Shield depleted exactly w/o damage
signal on_shield_broken_any(is_melee) # Shield depleted, any circumstance
signal on_blocked_all_damage(is_melee) # Shield remains; health unaffected
signal on_phys_combat_any_contact() # Happens no matter what, as long as it wasn't like, poison

# ---

func _ready():
	add_to_group("actors")
	if first_initiative != initspeeds.DOES_NOT_ACT:
		add_to_group("live_actors")
	
	perform_initial_data_setup()
	$ArtMgr/Shadow.recenter()
	vis_object = $ArtMgr/HFlipper
#	update_bui()
	
	initialize_action_libraries()
	
	batman.connect("pre_turn_setup", self, "master_pre_turn_setup")
	batman.connect("new_round_started", self, "master_pre_round_setup")
	pass

func perform_initial_data_setup():
	max_health *= batman.BASE_HP_FACTOR
	health = max_health
	
	max_shield *= batman.BASE_HP_FACTOR # Let the start of turn determine current shield
	shield = max_shield
	
	action_points = base_action_points
	base_damage *= batman.BASE_HP_FACTOR
	
	for term in ["unmovable", "immune_fire", "immune_water", "immune_ice", "immune_poison", "immune_magnet", "immune_elec", "immune_jagged", "immune_mud"]:
#	for term in ["hovering", "lightweight", "heavyweight", "unmovable", "immune_fire", "immune_water", "immune_ice", "immune_poison", "immune_magnet", "immune_elec", "immune_jagged"]:
		set( str("is_"+term), get(str("def_",term)) )
	weight = def_weight
	pass

func initialize_action_libraries():
	var libnames: Array = ["helper", "general", "player", "enemy"]
	
	for lib_name in libnames: if lib_name is String:
		var var_name: String = str("lib_",lib_name)
		var res_name: String = str("res_lib_",lib_name)
		var node_name: String = str("Lib",lib_name.capitalize())
		
		var lib: Node = Node.new()
#		lib.set_script(get(res_name))
		lib.set_script(loader.get(res_name))
		lib.set("name", node_name)
		lib.set("actor", self)
	
		$Utils.add_child(lib)
		lib.set("owner", self)
		set(var_name, lib)
		
		# Messy but we will have to fix at a later time
		if lib_name == "player":
			match name:
				"P1":
					lib.set("staple_attack", "basic_shot")
					lib.set("staple_cost", 2)
				"P2":
					lib.set("staple_attack", "basic_melee")
					lib.set("staple_cost", 2)
				"P3":
					lib.set("staple_attack", "basic_shot")
					lib.set("staple_cost", 1)
		pass
	
	# At this point, all libraries are set, and just need to be made aware of each other
	for lib_name in libnames: if lib_name is String:
#		var var_name: String = str("lib_",lib_name)
		var node_name: String = str("Lib",lib_name.capitalize())
		var lib: Node = $Utils.get_node(node_name)
		
		for otherlib_name in libnames: if otherlib_name is String:
			if otherlib_name == lib_name: continue
			
			var othervar_name: String = str("lib_",otherlib_name)
			var othernode_name: String = str("Lib",otherlib_name.capitalize())
			var otherlib: Node = $Utils.get_node(othernode_name)
			
			lib.set(othervar_name, otherlib)
		pass
	# Done!
	pass

# ---

func get_initiative() -> Array:
	if variance_initiative < 0: # Should set it once ever
		variance_initiative = rand_range(0.00000, 0.99999)
	
	var initset: Array = []
	
	if first_initiative > initspeeds.DOES_NOT_ACT:
		initset.append(float(first_initiative + variance_initiative))
	if second_initiative > initspeeds.DOES_NOT_ACT:
		initset.append(float(second_initiative + variance_initiative))
	if third_initiative > initspeeds.DOES_NOT_ACT:
		initset.append(float(third_initiative + variance_initiative))
	
	return initset

func choose_action():
	# At the start of turn, AND every time the action queue empties, this should fire until we're unable to act and need to end the turn manually (or automatically...?)
	if has_method("pre_action_cleanup"):
		call("pre_action_cleanup")
	
	# Players have a custom call
	if faction == batman.factions.PLAYER:
		player.inputstate = player.istates.READY_FOR_PLAYER_INPUT
#		print("Ready for player char to act: ",name)
		yield(player, "party_action_chosen")
		pass
	
	# Everyone/thing else
	elif has_method("prep_next_action"):
		call("prep_next_action")
	
	if !batman.action_queue.empty():
		actions_completed_this_turn += 1
	
	batman.progress_action_queue() # If empty when this is called (ie. we could not afford an action at all, or chose not to take one), consider the turn auto-over
	pass

func can_afford(cost: int) -> bool:
	if (action_points + bonus_actions) >= cost:
		return true
	return false
	pass

func spend(cost: int):
	if cost <= 0: return
	
	var og_cost: int = cost
	var og_actions: int = (action_points + bonus_actions)
	
	while bonus_actions > 0 and cost > 0:
		bonus_actions -= 1
		cost -= 1
	
	while action_points > 0 and cost > 0:
		action_points -= 1
		cost -= 1
	
	if cost > 0: # Note that this 'goes through' even if it's an issue; the print is the only notice
		print(name,": ERROR, tried to spend ",og_cost," action points when only ",og_actions," we available!")
	
	if action_points < 0: action_points = 0
	if bonus_actions < 0: bonus_actions = 0
	update_bui()
	pass

func add_bonus_actions(value: int):
	bonus_actions += value
	update_bui()
	pass

func refresh_action_points():
	action_points = base_action_points
	if !check_effect("keeps_bonus_actions"):
		bonus_actions = 0
	
	update_bui()
	pass

func master_pre_round_setup():
	turns_completed_this_round = 0
	pass

func master_pre_turn_setup(who: Actor):
	if who != self: return
	
#	print("Pre-turn refresh for ",self)
	actions_completed_this_turn = 0
	shield = max_shield
	if !check_effect("keeps_bonus_shield"):
		bonus_shield = 0
	ghost_mode(false)
#	action_points = base_action_points # This is handled during turn teardown
	tick_down_ongoing_effects(true)
	
	update_bui()
	pass

func master_post_turn_teardown(): # Teardown happens EVEN IF turn is interrupted! Baseline needs!
	turns_completed_total += 1
	tick_down_ongoing_effects(false)
	refresh_action_points()
	pass

# Just shortcuts
func end_action(): batman.end_action()
func end_turn():   batman.end_turn()

func start_effect(effect_name: String, turns_to_last: int = 1, until_end_of_turn: bool = true):
	var ticks: int = (turns_to_last * 2)
	if until_end_of_turn:
		ticks -= 1
	
	# When until_end_of_turn is false, it'll treat it as ending at the start of a turn - in almost all cases we want to end effects at the end of a turn, but a reaction guard ability might be different
	
	if batman.curr_actor != self:
		# When it's my turn, a "1-turn" effect typically means "for the rest of the turn"
		
		# When it's NOT my turn, ie. someone else is applying this effect to us, a "1-turn" effect typically means "until the end of your upcoming turn," so we need to add a tick to survive the start-of-turn tickover. This is basically always true, otherwise effects on others would only last UNTIL their turn starts and generally do nothing to them
		
		# So let's add a tick!
		ticks += 1
		pass
	
	# For existing effects, re-up the tick count to the higher of the new-vs-current
	if ongoing_turn_effects.has(effect_name):
		var existing_ticks: int = ongoing_turn_effects[effect_name]
		if ticks > existing_ticks:
			ongoing_turn_effects[effect_name] = ticks
			batman.update_action_log(str(name," RE-effected with [",effect_name,"], topped up to ",ticks," ticks!"))
		return
	
	# Otherwise, it's a new effect!
	ongoing_turn_effects[effect_name] = ticks
	batman.update_action_log(str(name," effected with [",effect_name,"] for ",ticks," ticks!"))
	pass

func clear_effect(effect_name: String):
	if !ongoing_turn_effects.has(effect_name): return
	
	ongoing_turn_effects.erase(effect_name)
	log_ended_effect(effect_name, true)
	pass

func check_effect(effect_name: String) -> bool:
	return ongoing_turn_effects.has(effect_name)
	pass

func tick_down_ongoing_effects(_is_turn_start: bool):
	if batman.curr_actor != self: return # We only tick down our OWN!
	
	var new_dict: Dictionary = {}
	
	for key in ongoing_turn_effects.keys():
		var ticks: int = ongoing_turn_effects[key]
		ticks -= 1
		
		# If we've run out, log it in our records
		if ticks <= 0:
			log_ended_effect(key, false)
			continue
		
		# Otherwise, pass it to the new temp dict to carry forward
		new_dict[key] = ticks
		pass
	
	ongoing_turn_effects.clear()
	ongoing_turn_effects = new_dict
	pass

func log_ended_effect(effect_name: String, manual_end: bool):
	if manual_end:
		batman.update_action_log(str(name," ended its effect [",effect_name,"]"))
	else:
		batman.update_action_log(str(name,"'s effect [",effect_name,"] timed out"))
	
	if !concluded_effects.has(batman.round_count):
		concluded_effects[batman.round_count] = []
	if !concluded_effects[batman.round_count].has(effect_name):
		concluded_effects[batman.round_count].append(effect_name)
	pass

func ghost_mode(to_ghost: bool, newly_claimed_tile: Vector2 = Vector2(-99, -99)) -> bool:
	# Ignore status quo
	if (to_ghost and is_ghost):
		return false
	elif (!to_ghost and !is_ghost):
		return false
	
	# Only changes from here!
	
	# Becoming ghost
	if to_ghost:
		# Switch out of the actor grid
		batman.remove_actor_from_actorgrid(self)
		if !batman.ghost_actors.has(self):
			batman.ghost_actors.append(self)
		is_ghost = true
		if newly_claimed_tile == Vector2(-99, -99): # We HAVE to claim something if we're going ghost mode, to ensure we have somewhere to come back to
			claimed_tile = coord
		else:
			claimed_tile = newly_claimed_tile
		return true
	
	# Return to gridlocked mortal form
	else:
		# We should always be tracking our own coord fwiw, even while ghosted, so this should still be up to date
		if !act.is_tile_available(coord, self):
			print(name," ERROR: Attempted to return from ghost mode while our current coord was unavailable!")
			return false
		if batman.ghost_actors.has(self):
			batman.ghost_actors.erase(self)
		is_ghost = false
		just_exited_ghost_mode = true
		batman.change_actor_coord(self, coord) # Manually - otherwise the system won't recognize the 'change'!
		return true
	pass

func claim_tile(claiming_coord: Vector2 = Vector2(-99, -99)) -> bool:
	if Vector2(-99, -99): claiming_coord = coord
	
	# Only one claim is ever allowed at a time!
	batman.release_actor_claims(self)
	claimed_tile = Vector2.ZERO
	
	if act.is_tile_available(claiming_coord, self):
		batman.grid_claims.set_cellv(claiming_coord, self)
		claimed_tile = claiming_coord
		return true
	
	return false
	pass

func release_claims():
	batman.release_actor_claims(self)
	pass

func set_targeted_tiles(targetset: Array): # Also operates as an overwrite
	targeted_tiles = targetset
	batman.update_targeted_tiles()
	pass

func append_some_targeted_tiles(targetset: Array):
	for target in targetset:
		if !targeted_tiles.has(target):
			targeted_tiles.append(target)
	
	batman.update_targeted_tiles()
	pass

func remove_some_targeted_tiles(targetset: Array):
	var new_targetset: Array = []
	
	# Pass ahead any target NOT in the inbound param set
	for target in targeted_tiles:
		if !targetset.has(target):
			new_targetset.append(target)
	
	targeted_tiles = []
	targeted_tiles = new_targetset
	batman.update_targeted_tiles()
	pass

func release_targeted_tiles():
	targeted_tiles = []
	batman.update_targeted_tiles()
	pass

func _process(_delta):
	monitor_position_as_coordinate()
	if just_exited_ghost_mode: just_exited_ghost_mode = false
	pass

func monitor_position_as_coordinate():
	if last_pos == position: return
	
	last_pos = position
	var last_tick_coord: Vector2 = coord
	
	coord = batman.field.actorpos_to_tilecoord(position)
	
	if coord == last_tick_coord: return
	if is_ghost: return
	
	# We always want to track our own coordinate personally, but don't want to manage the grid coord unless we're not a ghost
	
	batman.change_actor_coord(self, coord)
	
	pass

# ---

func on_entered_new_tile(new_coord: Vector2, old_coord: Vector2):
	var new_tiletype: int = batman.grid_tiles.get_cellv(new_coord)
	var _old_tiletype: int = batman.grid_tiles.get_cellv(old_coord)
	
	match new_tiletype:
		batman.tiletypes.POISON:
			receive_damage(1, false) # Minimum damage value
		batman.tiletypes.JAGGED:
			receive_damage(4, false) # Full hit, then restore it
			act.change_tiletype_single(new_coord, batman.tiletypes.NORMAL)
		
		batman.tiletypes.MUD:
			sink_into_tile()
		batman.tiletypes.WATER:
			sink_into_tile()
		batman.tiletypes.BOGROT:
			sink_into_tile()
	pass

func on_exited_old_tile(new_coord: Vector2, old_coord: Vector2):
	var _new_tiletype: int = batman.grid_tiles.get_cellv(new_coord)
	var old_tiletype: int = batman.grid_tiles.get_cellv(old_coord)
	
	match old_tiletype:
		batman.tiletypes.SAND:
			spend(1)
	pass

func on_rested_whileon_tile():
	var tiletype: int = batman.grid_tiles.get_cellv(coord)
	
	match tiletype:
		batman.tiletypes.POISON:
			receive_damage(1, false) # Minimum damage value
		batman.tiletypes.SAND:
			sink_into_tile()
	pass

func on_actionstep_ended_whileon_tile():
	var tiletype: int = batman.grid_tiles.get_cellv(coord)
	
	match tiletype:
		batman.tiletypes.ICE:
			pass
	pass

func on_turn_ended_whileon_tile():
	var tiletype: int = batman.grid_tiles.get_cellv(coord)
	
	match tiletype:
		batman.tiletypes.HOT:
			receive_damage(4, false) # Full damage at the END of your turn
	pass


# ---

func receive_damage(damage: int, is_melee: bool):
	if damage <= 0:
#		print(name,": No damage to receive")
		return
	
	var og_damage: int = damage
	var og_shield: int = shield
	var og_bonus_shield: int = bonus_shield
	var desctext: String = " melee"
	if !is_melee: desctext = " ranged"
	
	emit_signal("on_phys_combat_any_contact")
	strife.quick_effect(self, "spark_burst")
	
	# Deduct damage and shield equally until either of them depletes fully
	while (bonus_shield > 0 or shield > 0) and damage > 0:
		damage -= 1
		if bonus_shield > 0:
			bonus_shield -= 1
		else:
			shield -= 1
	
	if (shield+bonus_shield) < (og_shield+og_bonus_shield):
#		print("Some quantity of shield consumed!")
		emit_signal("on_shield_consumed", is_melee)
	
	if (og_shield+og_bonus_shield) > 0 and shield == 0:
#		print("Shield BROKEN!")
		if damage > 0:
			emit_signal("on_shield_broken_through", is_melee)
			strife.quick_effect(self, "shield_broken")
		else:
			emit_signal("on_shield_broken_held", is_melee)
			strife.quick_effect(self, "blocked")
		emit_signal("on_shield_broken_any", is_melee)
	
	var shielded_damage: int = og_damage - damage
	if damage <= 0:
		batman.update_action_log(str(name,": Blocked ",shielded_damage,desctext," and took no damage"))
		emit_signal("on_blocked_all_damage", is_melee)
		update_bui()
		return
	
	while health > 0 and damage > 0:
		damage -= 1
		health -= 1
	
	var unshielded_damage: int = og_damage - shielded_damage - damage
	strife.quick_effect(self, "damage", unshielded_damage)
	
	if health > 0:
		if shielded_damage == 0:
			batman.update_action_log(str(name,": Took ",og_damage,desctext," damage"))
		else:
			batman.update_action_log(str(name,": Blocked ",shielded_damage," and took ",unshielded_damage,desctext," damage"))
		update_bui()
		return
	else:
		if shielded_damage == 0:
			batman.update_action_log(str(name,": Died from taking ",unshielded_damage,desctext," damage"))
		else:
			batman.update_action_log(str(name,": Died from taking ",unshielded_damage,desctext," damage (blocked ",shielded_damage,")"))
		batman.kill_actor(self)
	
	pass

func sink_into_tile():
	pass

func alive_check() -> bool:
	if health <= 0: return false
	if !active: return false
	if !batman.living_actors.has(self): return false
	return true

# -

func update_bui():
	if faction == batman.factions.PLAYER:
		is_facing_left = false
	
	if !is_facing_left:
		$ArtMgr/HFlipper.scale.x = -1.0
	
	if !has_node("BUI"):
		bui = loader.res_bui.instance()
		bui.set("actor", self)
		add_child(bui)
		bui.set("owner", self)
	
	bui.update_all()
	pass

func update_outline(): # Should be called every time targeting changes
	# No outline by default
	var use_outline: bool = false
	var to_col: Color
	
	# White outline if it's your turn
	if batman.curr_actor == self:
		use_outline = true
		to_col = Color("c8f3fcf0")
	
	# Red outline if you're being targeted by something at present
	elif is_targeted():
		use_outline = true
		to_col = Color("c8f16233")
	
	var sm: ShaderMaterial = $ArtMgr/HFlipper/Sprite.material
	if use_outline:
		sm.set_shader_param("outline_col", to_col)
	sm.set_shader_param("outline_enabled", use_outline)
	pass

# -

func get_multifactored_actor_name() -> String:
	if !batman.unique_actornames_observed.has(ofc_name):
		return ofc_name
	
	var qty: int = batman.unique_actornames_observed[ofc_name]
	if qty == 1:
		return ofc_name
	
	return numerated_name
	pass

func is_targeted() -> bool:
	return batman.targeted_tiles.has(coord)

func _to_string() -> String:
	if ofc_name != "--":
		return ofc_name
	else:
		return name



