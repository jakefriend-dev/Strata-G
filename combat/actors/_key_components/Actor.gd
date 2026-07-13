extends Node2D
class_name Actor

onready var sprite: Sprite = $ArtMgr/HFlipper/Sprite
onready var hflipper: Node2D = $ArtMgr/HFlipper
onready var shadow: ColorRect = $ArtMgr/Shadow
onready var aniplayer: AnimationPlayer = $ArtMgr/AnimationPlayer
var tween: Tween

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

const global_moves: Array = ["walk", "be_external_motioned"]

var active: bool = true # When false, cannot act. Depletion of health should auto-set this, unless we want someone to have a post-death action, or a post-death health increase reaction for a second phase.

export (int, 1, 52) var max_health: int = 4 # Pre-factoring
var health: int = 4 # Pre-factoring
var base_health_pips: int = 4 # Updated ONCE by max health and that's it!

export var max_shield: int = 0
var shield: int = 0

export var ofc_name: String = "--"
var numerated_name: String = ""

enum bui_tiers {FULL, JUST_PIPS, JUST_HEALTH, INVIS_UNTIL_HIT, NOTHING_EVER}
export (bui_tiers) var bui_level: int = bui_tiers.FULL
var bui: Node2D

export var base_action_points: int = 4 # Used for movement AND attacks!
var action_points: int = 0 # Refreshed at the top of each turn! And start of combat
const MAX_action_points: int = 9 # Never let multi-turn overflow exceed this!
var action_cracking: int = 0 # Iterates through 1 (partial), 2 (heavy), then breaks 1AP and reverts to 0 (uncracked)
const MAX_action_cracking: int = 1 # Could change to 1 for testing if ya wants

var actions_completed_this_turn: int = 0 # An action is what we think of as an attack;
	# like all 3 steps of Doggo's charge attack is 1 action
var turns_completed_this_round: int = 0 # Includes interruptions, just if you had a turn at all
var turns_completed_total: int = 0

#export var base_damage: int = 1 # For attack shortcuts for simple mobs (gets auto-factored)
#var bonus_damage: int = 0

enum factions { # Local copy of TurnMgr, must be an exact duplicate!
	NEUTRAL,
	PLAYER,
	ENEMY,
}
export (factions) var faction: int = factions.ENEMY # Enemy if not manually set
var is_facing_left: bool = true # Default true for enemies; false for party
var my_facing: Vector2 = Vector2.ZERO # either LEFT or RIGHT
var their_facing: Vector2 = Vector2.ZERO # either RIGHT or LEFT

# A list of statuses for tracking and live usage
var ongoing_statuses: Dictionary = {
#	"example_status": {
#		"tick_style": "start", # vs "end"
#		"ticks_remaining": 2, # auto-ends UPON reaching 0
#		"display_name": "Example Status Name",
#		"key_name": "example_status", # Convenient redundancy; harmless
#		"icon_type": "good", # vs "bad" or "misc"
#		"ending_function": "auto_clear_damage_mod", # The name of the function (if any) that is called upon the status ending
#	},
}
# Concluded statuses are logged by the ROUND as a key, and an array of the statuses as a value
# Not sure we'll ever NEED these, but no harm storing it in the odd case like "don't use this status again if you used it last turn"
var concluded_statuses: Dictionary = {
	# Example:
	# 3: ["poison", "power_surge"],
	# 5: ["enrage"],
}

var damage_mods: Dictionary = {
#	"example_tag_name": -1, # Would be a -1 FULL PIP damage buff, to a minimum of 0 of course
}

enum weightclasses {
	HOVER,  # Flying; not affects by the ground beneath it at ALL. Allowed to enter pit tiles!
	LIGHT,  # Doesn't sink into certain tiles; immediately moved by wind; doesn't break lilypads?
	NORMAL, # Standard; affected by things as usual
	HEAVY,  # Unaffected by knockback, jagged tiles, or wind; always sinks
}

# Defaults first; manually set
export (weightclasses) var def_weight: int = weightclasses.NORMAL

const COST_WALK: int = 1
export var tile_walk_speed: float = 0.125

#export var def_hovering:			bool = false # Not affected by ground type or pits at all
#export var def_lightweight:			bool = false # Not affected by tiles that you sink in, like mud
#export var def_heavyweight:			bool = false # Not affected by wind OR knockback
export var def_unmovable:			bool = false # Not affected by ANY external factors! (Can still move ITSELF of course)
export var def_immune_jagged:		bool = false # Doesn't take damage or AP penalties from jaggies
export var def_immune_fire:			bool = false # Not affected by ember floors
export var def_immune_shrub:		bool = false # Not slowed by overgrowth tiles
export var def_immune_sand:			bool = false # Doesn't sink or take penalty from sand
export var def_immune_mud:			bool = false # Doesn't take penalty from mud
export var def_immune_ice:			bool = false # Doesn't slide on ice
export var def_immune_poison:		bool = false # Doesn't take poison damage
export var def_immune_magnet:		bool = false # Not pulled by magnet tiles
export var def_immune_elec:			bool = false # Doesn't take elec damage on static traps
export var def_immune_piercing:		bool = false # Not affected by the 'piercing' tag

var weight: int
#var is_hovering: bool
#var is_lightweight: bool
#var is_heavyweight: bool
var is_unmovable: bool
var is_immune_jagged: bool
var is_immune_fire: bool
var is_immune_shrub: bool
var is_immune_sand: bool
var is_immune_mud: bool
var is_immune_ice: bool
var is_immune_poison: bool
var is_immune_magnet: bool
var is_immune_elec: bool
var is_immune_piercing: bool

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

var z: int
var prev_z: int
var is_on_ground: bool = true # Always true unless jumping, essentially. Even hover-weight mobs are 'on ground'.
enum airstates {FLAT, RISING, FALLING}
var airstate: int = airstates.FLAT

signal on_z_begin_rise()
signal on_z_begin_fall()
signal on_z_jumped() # Even a non-"jump" counts as long as it becomes airborne
signal on_z_landed()

var moving_style: int = strife.moves.NOT_MOVING # All mobs should set this every action (actionstep?), semi-automatically (ie. defaulting to NOT_MOVING when not specified)

# Attacker combat signals
signal on_blocked_by_shield_any(combat_package) # Connected with a shield *at all*
signal on_blocked_by_shield_total(combat_package) # Completely blocked by shield
signal on_broke_someones_shield_any(combat_package) # Broke a shield, REGARDLESS of how much is left
signal on_broke_someones_shield_total(combat_package) # Broke a shield completely, and the victim has none left (regardless of damage received this attack)
signal on_broke_someones_shield_partial(combat_package) # Broke a shield partially, but the victim has some left
signal on_pierced_someones_shield(combat_package) # Bypassed a shield (does not count if they had none)
#
signal on_failed_to_wound_someone(combat_package) # Any impact without damage (it got blocked)
signal on_wounded_someone(combat_package) # Any damage impacted
signal on_killed_someone(combat_package) # Wowee!!
#
signal moved_other_actor(combat_package) # Motion only; knockback separate
signal knockback_damaged_other_actor(victim, knockback) # Damage only; motion separate


# Defender combat signals
signal on_blocked_damage_any(combat_package) # Incoming damage was affected by shields in any partial-or-full capacity
signal on_blocked_damage_total(combat_package) # Incoming damage was *completely* blocked by shields
signal on_shield_broken_any(combat_package) # Shield depleted, REGARDLESS of all/partial
signal on_shield_broken_through(combat_package) # Shield depleted, fully
signal on_shield_broken_held(combat_package) # Shield depleted, but not fully (whether or not damage penetrates past)
signal on_shield_pierced(combat_package) # Shield bypassed
#
signal on_wounded(combat_package) # Any damage received
signal on_not_wounded(combat_package) # Zero damage received (all of it blocked)
signal on_killed(combat_package) # Who killed me, and how???
#
signal was_moved_by_external(motion) # Motion only; knockback separate
signal was_knockback_damaged_by_external(knockback) # Damage only; motion separate

# Any combat signals
signal on_strife_any_contact_by_external(combat_package) # Happens no matter what, as long as it wasn't "quiet" combat like poison damage.

# Other
signal player_action_submitted() # Only pertinent to ActorPlayer subclasses but here nonetheless

# ---

func _ready():
	add_to_group("actors")
	if first_initiative != initspeeds.DOES_NOT_ACT:
		add_to_group("live_actors")
	
	perform_initial_data_setup()
	$ArtMgr/Shadow.recenter()
	vis_object = $ArtMgr/HFlipper
	tween = $Utils/Tween
	
	batman.connect("pre_turn_setup", self, "master_pre_turn_setup")
	batman.connect("new_round_started", self, "master_pre_round_setup")
	batman.connect("update_all_preview_drawing", self, "adjust_target_highlights")
	pass

func perform_initial_data_setup():
	
	base_health_pips = max_health
	max_health *= 4
	health = max_health
	
	max_shield *= 4 # Let the start of turn determine current shield
	shield = max_shield
	
	action_points = base_action_points
#	base_damage *= batman.BASE_HP_FACTOR
	
	for term in ["unmovable", "immune_fire", "immune_shrub", "immune_ice", "immune_poison", "immune_magnet", "immune_elec", "immune_jagged", "immune_mud", "immune_piercing"]:
		set( str("is_"+term), get(str("def_",term)) )
	weight = def_weight
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
		controls.inputstate = controls.istates.READY_FOR_PLAYER_INPUT
#		print("Ready for player char to act: ",name)
		yield(self, "player_action_submitted")
		pass
	
	# Everyone/thing else
	elif has_method("prep_next_action"):
		call("prep_next_action")
	
	if !batman.action_queue.empty():
		# It'd be empty if we failed to have assigned an action to the queue
		actions_completed_this_turn += 1
	
	batman.progress_action_queue() # If empty when this is called (ie. we could not afford an action at all, or chose not to take one), consider the turn auto-over
	pass

# ---

func can_afford(cost: int) -> bool:
	if (action_points) >= cost:
		return true
	return false
	pass

func spend(cost: int):
	if cost <= 0: return
	
	var og_cost: int = cost
	var og_actions: int = action_points
	
#	while bonus_actions > 0 and cost > 0:
#		bonus_actions -= 1
#		cost -= 1
	
	while action_points > 0 and cost > 0:
		action_points -= 1
		cost -= 1
	
	if cost > 0: # Note that this 'goes through' even if it's an issue; the print is the only notice
		print(name,": ERROR, tried to spend ",og_cost," action points when only ",og_actions," we available!")
	
	if action_points < 0: action_points = 0
#	if bonus_actions < 0: bonus_actions = 0
	
	if action_points == 0:
		action_cracking = 0
	
	update_bui()
	pass

func add_action_points(value: int):
	action_points += value
	if action_points > MAX_action_points:
		action_points = MAX_action_points
	batman.field.movewindow.refresh_all()
	update_bui()
	pass

func refresh_action_points():
	action_points += base_action_points
	if action_points > MAX_action_points:
		action_points = MAX_action_points
	action_cracking = 0
	
	update_bui()
	pass

func walk_spend_check():
	if batman.USE_ACTION_CRACKING:
		inc_action_cracking()
	else:
		spend(COST_WALK)
	pass

func inc_action_cracking():
	action_cracking += 1
	if action_cracking > MAX_action_cracking:
		action_cracking = 0
		spend(1)
	update_bui()
	pass

func clear_action_cracking():
	action_cracking = 0
	update_bui()
	pass

# ---

func master_pre_round_setup():
	turns_completed_this_round = 0
	pass

func master_pre_turn_setup(who: Actor):
	if who != self: return
	
#	print("Pre-turn refresh for ",self)
	actions_completed_this_turn = 0
	ghost_mode(false)
	tick_down_ongoing_statuses(true)
	
	update_bui()
	pass

func master_post_turn_teardown(): # Teardown happens EVEN IF turn is interrupted! Baseline needs!
	turns_completed_total += 1
	tick_down_ongoing_statuses(false)
	refresh_action_points()
	pass

# Just shortcuts
func end_action(): batman.end_action()
func end_turn():   batman.end_turn()

# ---

#var ref: Dictionary = {
#"example_status": {
#	"tick_style": "start", # vs "end"
#	"ticks_remaining": 2, # auto-ends UPON reaching 0
#	"display_name": "Example Status Name",
#	"key_name": "example_status", # Convenient redundancy; harmless
#	"icon_type": "good", # vs "bad" or "misc"
#	"ending_function": "auto_clear_damage_mod", # The name of the function (if any) that is called upon the status ending
#}}

var partial_predeffed_statuses: Dictionary = {
	"poisoned": {
		"icon_type": "bad",
		"desc": "Receive 1/4 poison damage each rest.",
		"tags": ["rest", "poison"],
	},}

func start_status(status_key: String, status_display_name: String, status_desc: String, icon_type: String, ticks: int, until_end_of_turn: bool = true, tags: Array = [], ending_function: String = ""):
	
	# For existing statuses, re-up the tick count to the higher of the new-vs-current
	if ongoing_statuses.has(status_key):
		var existing_ticks: int = ongoing_statuses[status_key]["ticks_remaining"]
		if ticks > existing_ticks:
			ongoing_statuses[status_key]["ticks_remaining"] = ticks
			batman.update_action_log(str(name," RE-statused with [",status_key,"], topped up to ",ticks," ticks!"))
		return
	
	# Otherwise, it's a new status!
	ongoing_statuses[status_key] = {}
	ongoing_statuses[status_key]["key_name"] = status_key
	ongoing_statuses[status_key]["display_name"] = status_display_name
	ongoing_statuses[status_key]["display_desc"] = status_desc
	ongoing_statuses[status_key]["tags"] = tags
	ongoing_statuses[status_key]["icon_type"] = icon_type
	ongoing_statuses[status_key]["ticks_remaining"] = ticks
	if until_end_of_turn:
		ongoing_statuses[status_key]["tick_style"] = "end"
	else:
		ongoing_statuses[status_key]["tick_style"] = "start"
	ongoing_statuses[status_key]["ending_function"] = ending_function
	
	batman.update_action_log(str(name," statused with [",status_key,"] for ",ticks," ticks!"))
	on_any_status_change()
	update_bui()
	pass

func clear_status(status_key: String):
	if !ongoing_statuses.has(status_key): return
	
	var ending_function: String = ongoing_statuses[status_key]["ending_function"]
	if has_method(ending_function):
		call(ending_function, status_key)
	ongoing_statuses.erase(status_key)
	log_ended_status(status_key, true)
	on_any_status_change()
	update_bui()
	pass

func generic_clear_status(status_key: String):
	clear_damage_mod(status_key)
	pass

func check_status(status_key: String) -> bool:
	return ongoing_statuses.has(status_key)
	pass

func on_any_status_change():
	var icons: Array = get_status_icons_in_play() # Reminder: good, bad, misc
	
	# Good/Buff
	if icons.has("good"):
		if !strife.check_if_vfx_on_actor_is_in_play(self, "buff"):
			strife.quick_vfx(self, "buff")
	else:
		if strife.check_if_vfx_on_actor_is_in_play(self, "buff"):
			strife.end_vfx_on_actor(self, "buff")
	
	# Bad/Debuff
	
	# Misc
	
	pass

func tick_down_ongoing_statuses(is_turn_start: bool):
	if batman.curr_actor != self: return # We only tick down our OWN!
	
#	var new_dict: Dictionary = {}
	var newly_ended_status_keys: Array = []
	
	for status_key in ongoing_statuses.keys():
		# Only tick the appropriate type at the appropriate time!
		if is_turn_start:
			if ongoing_statuses[status_key]["tick_style"] != "start": continue
		else:
			if ongoing_statuses[status_key]["tick_style"] != "end":   continue
		
		var ticks: int = ongoing_statuses[status_key]["ticks_remaining"]
		if ticks != 99: # 99 is 'infinite duration'
			ticks -= 1
			# If we've run out, log it in our records
			if ticks <= 0:
				newly_ended_status_keys.append(status_key)
				continue
		
		# Otherwise, pass it to the new temp dict to carry forward
		ongoing_statuses[status_key]["ticks_remaining"] = ticks
		pass
	
	for status_key in newly_ended_status_keys:
		if ongoing_statuses.has(status_key):
			var ending_function: String = ongoing_statuses[status_key]["ending_function"]
			if has_method(ending_function):
				call(ending_function, status_key)
			ongoing_statuses.erase(status_key)
			log_ended_status(status_key, false)
			on_any_status_change()
	update_bui()
#	ongoing_statuses.clear()
#	ongoing_statuses = new_dict
	pass

func log_ended_status(status_name: String, manual_end: bool):
	if manual_end:
		batman.update_action_log(str(name," ended its status [",status_name,"]"))
	else:
		batman.update_action_log(str(name,"'s status [",status_name,"] timed out"))
	
	if !concluded_statuses.has(batman.round_count):
		concluded_statuses[batman.round_count] = []
	if !concluded_statuses[batman.round_count].has(status_name):
		concluded_statuses[batman.round_count].append(status_name)
	pass

func get_status_icons_in_play() -> Array:
	var results: Array = []
	
	for key in ongoing_statuses.keys():
		if !results.has(ongoing_statuses[key]["icon_type"]):
			results.append(ongoing_statuses[key]["icon_type"])
	
	return results

# ---

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
#			print(name," at coord ",coord," is claiming SAME coord ",newly_claimed_tile)
			if !claim_tile(coord):
				print(name," ERROR: Attempted claim new tile during a ghost_mode(true) call but could not claim tile ",coord,"! Breakpoint!")
				
				return false
		else:
#			print(name," at coord ",coord," is claiming OTHER coord ",newly_claimed_tile)
			if !claim_tile(newly_claimed_tile):
				print(name," ERROR: Attempted claim new tile during a ghost_mode(true) call but could not claim tile ",coord,"! Breakpoint!")
				
				return false
		return true
	
	# Return to gridlocked mortal form
	else:
		# We don't actually want to look at CLAIMS here, perhaps? This is a hard override; if someone else has claimed this tile that is going to be a them issue. Claims influence behaviour but are a crutch; actors take precedence for purposes like a thory CAM preview.
		if utils.actorpass(batman.grid_actors.get_cellv(coord)):
#		if !support.is_tile_available(coord, [self]):
			print(name," ERROR: Attempted to return from ghost mode while our current coord was unavailable! BREAKPOINT!")
			
			return false
		if batman.ghost_actors.has(self):
			batman.ghost_actors.erase(self)
		is_ghost = false
		just_exited_ghost_mode = true
		batman.change_actor_grid_coord(self, coord) # Manually - otherwise the system won't recognize the 'change'!
		return true
	pass

func claim_tile(claiming_coord: Vector2 = Vector2(-99, -99)) -> bool:
#	print("claiming_coord coming in at: ",claiming_coord)
	if claiming_coord == Vector2(-99, -99):
		claiming_coord = coord
#	print("claiming_coord still? at: ",claiming_coord)
	
	# Only one claim is ever allowed at a time!
	batman.release_actor_claims(self)
	claimed_tile = Vector2.ZERO
	
	if support.is_tile_available(claiming_coord, [self]):
#		print("and here's the fallout, claiming: ",claiming_coord)
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
	if !batman.is_game_live(): return
	
	manage_z_height()
	monitor_position_as_coordinate()
	if just_exited_ghost_mode: just_exited_ghost_mode = false
	pass

func manage_z_height():
	is_on_ground = (z <= 0)
	
	# going down
	if z < prev_z:
		if airstate != airstates.FALLING:
			emit_signal("on_z_begin_fall")
		airstate = airstates.FALLING
		if prev_z > 0 and z <= 0:
			emit_signal("on_z_landed")
			strife.TILE_event_entry(self, coord)
			print(name," landed!")
	
	# going up
	elif z > prev_z:
		if airstate != airstates.RISING:
			emit_signal("on_z_begin_rise")
		airstate = airstates.RISING
		if prev_z <= 0 and z > 0:
			emit_signal("on_z_jumped")
			print(name," jumped!")
	
	# sustained position
	else:
		airstate = airstates.FLAT
	
	# Commit!
	prev_z = z
	
	# Regardless, we want to update the visuals live
	if vis_object.position.y != -z:
		vis_object.position.y = -z
	pass

func monitor_position_as_coordinate():
	if position.is_equal_approx(last_pos): return
	
	last_pos = position
	var prev_tick_coord: Vector2 = coord
	
	# If a position change is registered, we need to check we have gone FAR ENOUGH outside the currently-registered coord to warrant an actual change
	
	var margin: float = 0.125
	var ERROR_MARGIN_X: Vector2 = Vector2(batman.CELL_SIZE.x * margin, 0)
	var ERROR_MARGIN_YL: Vector2 = Vector2(-24.0 * margin, batman.CELL_SIZE.y * margin)
	var ERROR_MARGIN_YR: Vector2 = Vector2( 24.0 * margin, batman.CELL_SIZE.y * margin)
		
	# As long as ANY of the left/right/etc checks are STILL our current coord, return!
	
	var ver_coord_left: Vector2 = batman.actorpos_to_tilecoord(position - ERROR_MARGIN_X)
	if ver_coord_left == coord: return
	var ver_coord_right: Vector2 = batman.actorpos_to_tilecoord(position + ERROR_MARGIN_X)
	if ver_coord_right == coord: return
	var ver_coord_up: Vector2 = batman.actorpos_to_tilecoord(position - ERROR_MARGIN_YL)
	if ver_coord_up == coord: return
	var ver_coord_down: Vector2 = batman.actorpos_to_tilecoord(position + ERROR_MARGIN_YR)
	if ver_coord_down == coord: return
	
	# At this point, it's fair to say that we aren't "too close" to our last-registered coord, so let's update and see where we're at
	
	coord = batman.actorpos_to_tilecoord(position)
	
	if coord == prev_tick_coord: return
	
#	print("new coord for ",name,": ",coord)
	
	strife.TILE_event_exit(self, prev_tick_coord)
	strife.TILE_event_entry(self, coord)
	
	if is_ghost: return
	
	# We always want to track our own coordinate personally, but don't want to manage the grid coord unless we're not a ghost
	
	batman.change_actor_grid_coord(self, coord)
	
	pass

# ---

# ---

func adjust_target_highlights():
	var to_col: Color = Color.white
	if batman.drawer.drawing:
		if batman.drawer.MPD != null:
			if !batman.drawer.MPD.unique_cells.has(coord):
				to_col = Color.gray
#				to_col.a = 0.75
	
	if $ArtMgr.modulate != to_col:
		$ArtMgr.modulate = to_col
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
		my_facing = Vector2.RIGHT
		their_facing = Vector2.LEFT
	elif faction == batman.factions.ENEMY:
		my_facing = Vector2.LEFT
		their_facing = Vector2.RIGHT
	
	if !is_facing_left:
		$ArtMgr/HFlipper.scale.x = -1.0
	
	if !has_node("BUI"):
		bui = loader.res_bui.instance()
		bui.set("actor", self)
		bui.set("position", Vector2(0, 8))
		add_child(bui)
		bui.set("owner", self)
	
	batman.field.movewindow.update_ap()
	bui.refresh()
	pass

func update_outline(): # Should be called every time targeting changes
	# No outline by default
	var use_outline: bool = true
	var to_col: Color = Color("222a5c")
	
	# White outline if it's your turn
	if batman.curr_actor == self:
		use_outline = true
		to_col = Color("ffffff")
	
	# Red outline if you're being targeted by something at present
	elif is_targeted():
		use_outline = true
		to_col = Color("800c53")
	
	var sm: ShaderMaterial = $ArtMgr/HFlipper/Sprite.material
	if use_outline:
		sm.set_shader_param("outline_col", to_col)
	sm.set_shader_param("outline_enabled", use_outline)
	pass

# -


func hotmove(to_coord: Vector2, dur: float):
	tween.interpolate_property(self, "position", null, batman.grid_gpos.get_cellv(to_coord), dur,Tween.TRANS_CIRC, Tween.EASE_IN_OUT)
	tween.start()
	pass

func hotpushed(to_coord: Vector2, dur: float):
	tween.interpolate_property(self, "position", null, batman.grid_gpos.get_cellv(to_coord), dur,Tween.TRANS_QUINT, Tween.EASE_OUT)
	tween.start()
	pass

func hotknockbacked(attacker: Actor, relvec: Vector2, dur: float, total_kb_dmg_value: int):
	print(name,": hotknockbacked(",attacker,", ",relvec,", ",dur,", ",total_kb_dmg_value,")")
	
	relvec = relvec.normalized()
	var dur1_3: float = dur/3.0
	var dur2_3: float = dur1_3 * 2.0
	
	var og_pos: Vector2 = position
	var kb_pos: Vector2 = position + (relvec*10.0)
	
	tween.interpolate_property(self, "position", null, kb_pos, dur1_3, Tween.TRANS_EXPO, Tween.EASE_OUT)
	tween.start()
	
	yield(utils.yt(dur1_3, self), "timeout")
	
	# Take the hit before moving back!
	if total_kb_dmg_value > 0:
		strife.do_impact_damage(attacker, self, total_kb_dmg_value)
	if !utils.actorpass(self): return
	
	tween.interpolate_property(self, "position", kb_pos, og_pos, dur2_3, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	tween.start()
	
	pass

func hotjump(to_coord: Vector2, dur: float, height: float = 100.0):
	tween.interpolate_property(self, "position", null, batman.grid_gpos.get_cellv(to_coord), dur,Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	
	tween.interpolate_property(self, "z", null, height, dur/2.0,Tween.TRANS_CUBIC, Tween.EASE_OUT)
	tween.interpolate_property(self, "z", height, 0.0, dur/2.0,Tween.TRANS_CUBIC, Tween.EASE_IN, dur/2.0)

#	tween.interpolate_property(vis_object, "position:y", null, -height, dur/2.0,Tween.TRANS_CUBIC, Tween.EASE_OUT)
#	tween.interpolate_property(vis_object, "position:y", -height, 0.0, dur/2.0,Tween.TRANS_CUBIC, Tween.EASE_IN, dur/2.0)

	tween.start()
	pass

func ACT_walk(motion: Vector2):
#	print("walk")
	var dur: float = tile_walk_speed
	
	var exact_coord: Vector2 = coord + motion
	hotmove(exact_coord, dur)
	yield(utils.yt(dur, self), "timeout")
	if !batman.is_my_action(self): return
	
	end_action()
	pass

# This action is always auto-constructed by Strife; we do not manually call this
func ACT_be_external_motioned(motion: Vector2, knockback_damage: int, attacker: Actor, is_quiet: bool, flags: Array = []):
	
	# (Note, this action is only called if there IS motion - if there's ONLY knockback, it's bypassed entirely for immediate damage)
	
	# First, let's confirm attacker status
	var attacker_is_real: bool = false
	if utils.actorpass(attacker):
		attacker_is_real = true
	
	var major_impact: bool = (knockback_damage > 0 or !is_quiet)
	
	# Then let's trigger the motion!
	var dur1: float
	var dur2: float
	var trans: int
	var easin: int
	if major_impact: # Big impact! We were forcibly knocked back, by eg. a punch!
		dur1 = 0.05
		dur1 += (dur1 * motion.length())
#		trans = Tween.TRANS_QUINT
		trans = Tween.TRANS_LINEAR
		easin = Tween.EASE_OUT
	else: # Steady impact! We're in wind, or something.
		dur1 = (motion.length() * 0.375)
		trans = Tween.TRANS_CIRC
		easin = Tween.EASE_IN_OUT
	
	if knockback_damage > 0: # Only triggers in major_impact anyhow
		dur1 += 0.05
		dur2 = 0.10
	
	var _total_dur = dur1 + dur2
	var to_coord: Vector2 = coord + motion
	var to_gpos: Vector2 = batman.grid_gpos.get_cellv(to_coord)
	# Overshoot is 35% of 1 tile
	var impact_overshoot: Vector2 = (motion.normalized() * batman.field.CELL_SIZE * 0.35)
	
	# Signal being moved just before you go, then go!
	if !is_quiet:
		if attacker_is_real:
			attacker.emit_signal("moved_other_actor", self, motion)
		emit_signal("was_moved_by_external", motion)
	
#	print("ready to moved with motion ",motion," and KD ",knockback_damage," and dur1 ",dur1," and dur2 ",dur2)
	
	# For getting hurt, we want two tweens, actually! And apply damage on impact
	if knockback_damage > 0:
		tween.interpolate_property(self, "position", null, to_gpos + impact_overshoot,
			dur1, trans, easin)
		tween.interpolate_property(self, "position", to_gpos + impact_overshoot, to_gpos,
			dur2, Tween.TRANS_QUINT, Tween.EASE_OUT, dur1)
		tween.start()
		
		yield(utils.yt(dur1, self), "timeout")
		if !batman.is_my_action(self): return
		
		if knockback_damage > 0: # 'is_quiet' doesn't matter here; we collided with something!
			if attacker_is_real:
				attacker.emit_signal("knockback_damaged_other_actor", self, knockback_damage)
			emit_signal("was_knockback_damaged_by_external", knockback_damage)
			strife.do_impact_damage(attacker, self, knockback_damage, flags)
		
		yield(utils.yt(dur2, self), "timeout")
		if !batman.is_my_action(self): return
		pass
	
	# For *not* getting hurt, well... it's less exciting but it works.
	else:
		tween.interpolate_property(self, "position", null, to_gpos, dur1, trans, easin)
		tween.start()
		
		yield(utils.yt(dur1, self), "timeout")
		if !batman.is_my_action(self): return
		pass
	
	#
	# EITHER WAY! At this point we've fully arrived, and knockback damage is behind us.
	#
	
	print(name," external motioned has ended!")
	
	# We're done!
	end_action()
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

# ---

func set_damage_mod(mod_key: String, value: int):
	damage_mods[mod_key] = value
	pass

func dmg(value: int, treat_as_quarters: bool = false) -> int:
	var mod: int = get_damage_mod_total()
	mod *= 4 # Always comes in as FULL pips
	
	if !treat_as_quarters:
		value *= 4 # Also FULL pips by default
	
	value += mod
	if value < 0: return 0
	return value
	pass

func get_damage_mod_total() -> int:
	var total: int = 0
	
	for key in damage_mods.keys():
		total += damage_mods[key]
	
	return total
func clear_damage_mod(mod_key: String):
	if damage_mods.has(mod_key):
		damage_mods.erase(mod_key)
	pass

func clear_all_damage_mods():
	damage_mods.clear()
	pass

# ---

func x_facing() -> int: # Shortcut for the X-facing dir
	if faction == factions.PLAYER:
		return 1
	if faction == factions.ENEMY:
		return -1
	return 0

func _to_string() -> String:
	if ofc_name != "--":
		return ofc_name
	else:
		return name



