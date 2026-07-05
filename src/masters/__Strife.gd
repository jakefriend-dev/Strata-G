extends Node

# Owner of ALL COMBAT AND DISPUTES:
	# The 'impact' of one actor on another
		# Typically damage
		# Can also be wind force, knockback force, conveyor physical motion, etc
	# Damage types, and ensuring attacks 'have' core damage details
		# Elemental eg. fire or normal
		# Range eg. contact-range vs long-range (let's avoid saying 'melee or ranged' maybe?)
		# Impact type eg. physical or abstract (useful for "counter phy attacks")
		# Other optional tags like shield-piercing
		# Who the source of damage is, if there is one
	# Tile entry/exit effects
	# Global checks for if a given actor is 'allowed' to move to a given tile

enum elements {NORMAL, COLD, FIRE, WOOD, GROUND, AIR, MAGIC, ELEC, POISON, BLOOD, LIGHT}
# Ones I'm unsure of being an 'element' so much as just a flag:
	# BREAKING

enum hitrange {CONTACT, DISTANT} # Not used anywhere atm

enum impacts {PHYSICAL, ABSTRACT} # Not use anywhere atm

# For actors, to help handle things like ice or conveyor effect motion
enum moves { # WAYS of moving, for the purpose of things like determining ice slippy-ness.
	NOT_MOVING,
	BY_TRAVEL, # Affected by ice! Does not factor in hover etc; this is a plain adjacency thing
	BY_JUMP,
	BY_WARP,
	BY_SPECIAL_TRAVEL, # A cartwheel might be immune to slipping, for instance
	MOVED_EXTERNALLY, # Similar to BY_TRAVEL but helps separate external forces from ourselves
		# If someone else warps our position, we'll just use BY_WARP rather than make another WARPED_EXTERNALLY
	DNU
}



# COMBAT PROCESSING! -----------------------------------------------------------

# Impact damage/motion can be blocked and countered as usual, and triggers animation responses.
	# Impacts are 'standard' attacks or knockback motion. This is the norm!
# Quiet damage/motion simply happens, as long as there's no relevant immunities. There should be nothing to 'counter' and visual responses like animations can be skipped.
	# Damage example: Poison tiles
	# Motion example: Wind currents
	# We don't worry about ice or conveyor movement - those handle themselves.
# If motion AND damage are needed in one attack, the attacker's function needs to have one call for each. Much simpler that way. Ideally, damage first.

# Note that 'attacker' is *allowed* to be null, for instances of arena damage/effects.

func do_impact_damage(attacker: Actor, defender: Actor, damage: int, flags: Array = []):
	master_do_damage(attacker, defender, damage, flags, false)
func do_quiet_damage(attacker: Actor, defender: Actor, damage: int, flags: Array = []):
	master_do_damage(attacker, defender, damage, flags, true)
	pass

# Common DAMAGE flags:
	# piercing: Shields are bypassed
	# poison (or other element): Elemental immunities/weaknesses are applied
	# skip_own_faction: Typically FF is default-on; this would bypass that

func master_do_damage(attacker: Actor, defender: Actor, damage: int, flags: Array, is_quiet: bool):
	if damage <= 0: return
	if !utils.actorpass(defender): return # Attacker is allowed to be null, though!
	
	var attacker_is_real: bool = false
	if utils.actorpass(attacker):
		attacker_is_real = true
	
	var friendly_fire: bool = true
	if flags.has("skip_own_faction"): friendly_fire = false
	if !friendly_fire:
		if attacker_is_real:
			if attacker.faction == defender.faction:
				return
	
	# This bit is probably quite replaceable; it's just for early prototype state text logging
#	var is_melee: bool = support.are_actors_adjacent(attacker, defender)
#	var desctext: String = " melee"
#	if !is_melee: desctext = " ranged"
	
	#
	# Apply any elemental modifiers here! Increase the damage for hitting a weakness eg.
	#
	
	# REFERENCE - these should ALWAYS be mutually exclusive, I thiiink?
#	{NORMAL, COLD, FIRE, WOOD, GROUND, AIR, MAGIC, ELEC, POISON, BLOOD, LIGHT}
	
	
	# Determine our element
	var elem: String = "NORMAL"
	var elemkeys: Array = elements.keys()
	for flag in flags: if flag is String:
		var flag_upper: String = flag.to_upper()
		if elemkeys.has(flag_upper):
			elem = flag_upper
			break
	
#	print("damage element is: ",elem)
	
	#
	# Now begin the damage management
	#
	
	var og_damage: int = damage
	var og_shield: int = defender.shield
	var og_bonus_shield: int = defender.bonus_shield
	var og_total_shield: int = og_shield + og_bonus_shield
	
	
	if !is_quiet:
		defender.emit_signal("on_phys_combat_any_contact")
		quick_effect(defender, "spark_burst")
	
	#
	# If able, break shields first
	#
	
	var breaking: bool = flags.has("breaking")
	var break_damage: int = 0
	var break_spends: int = 0 # Goes up by 1 per break_damage applied
	if breaking: break_damage = damage
	if elem == "COLD":
		break_damage += 1
		break_spends -= 1 # The cold pip is "free"
	
	var did_shield_break_occur: bool = false # For signals to hook into later
	var were_all_shields_broken: bool = false # Ditto
	if break_damage > 0:
		# Deduct damage and shield equally until either of them depletes fully
		while (defender.bonus_shield > 0 or defender.shield > 0) and break_damage > 0:
			# Remove bonus shield first, then apply the rest as breakage
			break_damage -= 1
			break_spends += 1
			if defender.bonus_shield > 0:
				defender.bonus_shield -= 1
			else:
				defender.shield -= 1
				did_shield_break_occur = true
				if defender.shield == 0:
					were_all_shields_broken = true
	
	# This is how we keep break_damage and damage separated but linked
	if break_spends > 0:
		damage -= break_spends
	
	#
	# Check for piercing or piercing immunity - you cannot break AND pierce; breaking means shields ARE interacted with and overrides piercing which means they aren't
	#
	
	var piercing: bool = (flags.has("piercing") and !breaking)
	if defender.is_immune_piercing: piercing = false # Override!
	var unbroken_shield: int = defender.shield
	
	# If NOT piercing, in this order:
		# 1. Deduct damage & bonus_shield together
		# 2. Deduct damage $ unbroken_shield together (not ACTUAL LIVE SHIELD VALUE, just this int)
		# 3. Deduct damage & health together
	
	if !piercing:
		# Deduct damage and shield equally until either of them depletes fully
		while (defender.bonus_shield > 0 or unbroken_shield > 0) and damage > 0:
			damage -= 1
			if defender.bonus_shield > 0:
				defender.bonus_shield -= 1
			else:
				unbroken_shield -= 1
	
	#
	# In standard circumstances, we need to send out a bunch of signal hooks
	# If we BROKE the last STANDARD shield this action, do the shield broken signal - we don't bother if it's just damaging (but not breaking) the shield, or if bonus shield is depleted.
	# In fact, bonus shield shouldn't really trigger any signals at all in this combat algorithm approach.
	# Let's also not bother with the is_melee tag in the signal; maybe instead we can send out a combat assessment package
	#
	
	var total_shield_left: int = defender.shield + defender.bonus_shield
	var shielded_damage: int = og_damage - damage
	var combat_package: Dictionary = {}
	
	if !is_quiet:
		
		# First, handle shield breaking
		if did_shield_break_occur:
			defender.emit_signal("on_shield_broken_any", combat_package)
			if attacker_is_real: attacker.emit_signal("on_broke_someones_shield_any", combat_package)
			
			if were_all_shields_broken:
				defender.emit_signal("on_shield_broken_through", combat_package)
				if attacker_is_real: attacker.emit_signal("on_broke_someones_shield_total", combat_package)
				quick_effect(defender, "shield_broken")
			else:
				defender.emit_signal("on_shield_broken_held", combat_package)
				if attacker_is_real: attacker.emit_signal("on_broke_someones_shield_partial", combat_package)
		
		# Second, piercing
		if piercing:
			defender.emit_signal("on_shield_pierced", combat_package)
			if attacker_is_real: attacker.emit_signal("on_pierced_someones_shield", combat_package)
		
		# Third, blocked damage
		if shielded_damage > 0:
			defender.emit_signal("on_blocked_damage_any", combat_package)
			if attacker_is_real: attacker.emit_signal("on_blocked_by_shield_any", combat_package)
			quick_effect(defender, "blocked")
			
			if damage == 0:
				defender.emit_signal("on_blocked_damage_total", combat_package)
				if attacker_is_real: attacker.emit_signal("on_blocked_by_shield_total", combat_package)
		
		# Fourth, actually received unblocked damage (or not)
		if damage > 0:
			defender.emit_signal("on_wounded", combat_package)
			if attacker_is_real: attacker.emit_signal("on_wounded_someone", combat_package)
		else:
			defender.emit_signal("on_not_wounded", combat_package)
			if attacker_is_real: attacker.emit_signal("on_failed_to_wound_someone", combat_package)
		
#		if total_shield_left < og_total_shield:
#	#		print("Some quantity of shield consumed!")
#			defender.emit_signal("on_shield_consumed", combat_package)
#			if attacker_is_real: attacker.emit_signal("on_hit_someones_shield", combat_package)
	
		pass
	# Unless things are quiet, in which case... nope, no signals!
	
	# The only unused signals here are killing, which should happen regardless of is_quiet
	
	# When no damage is left, end the algorithm
	if damage <= 0:
		batman.update_action_log(str(defender.name,": Blocked ",shielded_damage," and took no damage"))
		defender.update_bui()
		return
	
	#
	# Apply remnant damage to the defender's health!
	#
	
	var impacted_damage: int = 0
	while (defender.health > 0 and damage > 0):
		damage -= 1
		defender.health -= 1
		impacted_damage += 1
	
	# Any remaining damage in the 'damage' var is overkill
	
	if !is_quiet:
		quick_effect(defender, "damage", impacted_damage)
	
	# The defender lives!
	if defender.health > 0:
		if shielded_damage == 0:
			batman.update_action_log(str(defender,": Took ",og_damage," damage"))
		else:
			batman.update_action_log(str(defender,": Blocked ",shielded_damage," and took ",impacted_damage," damage"))
		defender.update_bui()
		return
	
	# The defender dies!
	if shielded_damage == 0:
		batman.update_action_log(str(defender.name,": Died from taking ",impacted_damage," damage"))
	else:
		batman.update_action_log(str(defender.name,": Died from taking ",impacted_damage," damage (blocked ",shielded_damage,")"))
	
	defender.emit_signal("on_killed", combat_package)
	if attacker_is_real: attacker.emit_signal("on_killed_someone", combat_package)
	
	batman.kill_actor(defender)
	pass

# -

func do_impact_motion(attacker: Actor, defender: Actor, motion: Vector2, flags: Array = []):
	master_do_motion(attacker, defender, motion, flags, false)
	pass
func do_quiet_motion(attacker: Actor, defender: Actor, motion: Vector2, flags: Array = []):
	master_do_motion(attacker, defender, motion, flags, true)
	pass

# Common MOTION flags:
	# travel_damage: For each cell the defender is *unable* to travel, deal 1 base damage
	# skip_own_faction: Typically FF is default-on; this would bypass that

func master_do_motion(attacker: Actor, defender: Actor, motion: Vector2, flags: Array, is_quiet: bool):
	if motion == Vector2.ZERO: return
	if !utils.actorpass(defender): return # Attacker is allowed to be null, though!
	
	var og_motion: Vector2 = motion
	if !support.is_motion_a_line(motion): # Just a safety check, SHOULD never actually happen
		motion = support.lineize_motion(motion)
		print("STRIFE: Had to line-ize incoming motion ",og_motion," into ",motion)
	
	var attacker_is_real: bool = false
	if utils.actorpass(attacker):
		attacker_is_real = true
	
	var friendly_fire: bool = true
	if flags.has("skip_own_faction"): friendly_fire = false
	if !friendly_fire:
		if attacker_is_real:
			if attacker.faction == defender.faction:
				return
	
	#
	# Check resistances!
	#
	
	var successful_motion: bool = false
	var on_ice: bool = bool(
		batman.grid_tiles.get_cellv(defender.coord) == batman.tiletypes.ICE)
	
	if is_affected_by_force(defender):
		successful_motion = true
	elif (
		on_ice and
		is_affected_by_ice(defender) and
		defender.is_on_ground and
		defender.weight != defender.weightclasses.HOVER):
			# Even a 'force-immune' enemy on the ground gets pushed while on ice!
			successful_motion = true
	
	if !successful_motion: return
	
	#
	# Work out if we can move, and if so how far (and track it all!)
	#
	
	var unspent_motion: Vector2 = motion
	var spent_motion: Vector2 = Vector2.ZERO
	
	var tilemove_successes: int = 0
	var tilemove_failures: int = 0
	
	var loops: int = 0 # 1-based, shortly
	var max_loops: int = support.get_steps_in_vector_line_int(motion)
	var step: Vector2 = motion.normalized().round()
	var check_tile_rel: Vector2 = Vector2.ZERO
	
	while !unspent_motion.is_equal_approx(Vector2.ZERO):
		loops += 1
		if loops > max_loops:
			loops = max_loops
			print("MAX LOOPS REACHED! Unspent motion: ",unspent_motion)
			break
		
		# If we've already failed, don't bother with check logic - the rest is necessarily also a fail, and we already know our final spent_motion.
		if tilemove_failures > 0:
			tilemove_failures += 1
			continue
		
		# Last validation check to make sure we're still on the board
		check_tile_rel += step
		var check_tile_exact: Vector2 = defender.coord + check_tile_rel
		if !batman.grid_tiles.has_cellv(check_tile_exact): # (Unless we're off the board)
			tilemove_failures += 1
			continue
		
		#
		# Okay, NOW we're still in the game!
		#
		
		# Finally, if we're ABLE to exist on that tile, spend the motion; otherwise continue
		if support.is_tile_traversable_exact(defender, check_tile_exact):
			tilemove_successes += 1
			spent_motion += step
			unspent_motion -= step
			continue
		else:
			tilemove_failures += 1
			continue
		pass
	
	print("STRIFE: Worked out that master_do_motion(",attacker,", ",defender,", ",motion,", ",flags,") was able to push the defender ",tilemove_successes," steps with spent_motion ",spent_motion," and ",tilemove_failures," step failures!")
	
	#
	# At this point, we should now know our destination tile and how far we *couldn't* move
	#
	
	var do_travel_damage: bool = flags.has("travel_damage")
	var knockback_damage: int = 0
	if do_travel_damage:
		knockback_damage = (tilemove_failures * batman.BASE_HP_FACTOR)
	
	# No motion??
	if spent_motion.is_equal_approx(Vector2.ZERO):
		if knockback_damage == 0:
			# We failed to move anyone or deal knockback damage - why react?
			return
		
		# Otherwise, we have knockback and no motion - there's no need to wait for movement; trigger the impact and signals now then skip the reaction movement
		if attacker_is_real:
			attacker.emit_signal("knockback_damaged_other_actor", self, knockback_damage)
		defender.emit_signal("was_knockback_damaged_by_external", knockback_damage)
		do_impact_damage(attacker, defender, knockback_damage, flags)
		return
	
	# The is_quiet signalling actually needs to happen when the ACTION STEP begins, not the moment (mid-attacker's action step) this connects - and dealing damage needs to wait until the motion ends! So for now, just create the reaction and forward the details to there.
	
	batman.reaction(defender, "be_external_motioned", [
		spent_motion, knockback_damage, attacker, is_quiet, flags
		])
	pass

# Holdovers below, need updating!

func damage_actor_at_coord(attacker: Actor, exact_coord: Vector2, damage: int, flags: Array = []):
	if !batman.grid_actors.has_cellv(exact_coord): return
	
	var victim: Actor = batman.grid_actors.get_cellv(exact_coord)
	if !utils.actorpass(victim): return
	
	var is_quiet: bool = flags.has("quiet")
	
	master_do_damage(attacker, victim, damage, flags, is_quiet)
	pass

func extmotion_actor_at_coord(attacker: Actor, exact_coord: Vector2, motion: Vector2, flags: Array = []):
	if !batman.grid_actors.has_cellv(exact_coord): return
	
	var victim: Actor = batman.grid_actors.get_cellv(exact_coord)
	if !utils.actorpass(victim): return
	
	var is_quiet: bool = flags.has("quiet")
	
	master_do_motion(attacker, victim, motion, flags, is_quiet)
	pass

func heal_actor_at_coord(_attacker: Actor, exact_coord: Vector2, healing: int, _flags: Array = []):
	if !batman.grid_actors.has_cellv(exact_coord): return
	
	var victim: Actor = batman.grid_actors.get_cellv(exact_coord)
	if !utils.actorpass(victim): return
	
	# Temporary jank setup until we do a 'main' function for this
	
	var before_health: int = victim.health
	var new_health: int = victim.health + healing
	if new_health < victim.max_health:
		victim.health = new_health
	else:
		victim.health = victim.max_health
	var delta: int = new_health - before_health
	
	quick_effect(victim, "heal", delta)
	victim.update_bui()
	print("Healed ",victim," +",healing," HP from ",before_health," to ",victim.health,"!")
	
#	var is_quiet: bool = flags.has("quiet")
#	
#	master_do_damage(attacker, victim, -healing, flags, is_quiet)
	pass

# VISUAL EFFECTS ---------------------------------------------------------------

func quick_effect(actor_or_coord, effect: String, variant = null):
	match effect:
		
		"damage":
			spawn_effect_on_actor(actor_or_coord, "damage", false, float(variant))
		
		"heal":
			spawn_effect_on_actor(actor_or_coord, "heal", false, float(variant))
		
		"blocked":
			spawn_effect_on_actor(actor_or_coord, "blocked", false)
			pass
		
		"shield_broken":
			spawn_effect_on_actor(actor_or_coord, "shield_broken", false)
		
		"quick_good":
			spawn_effect_on_actor(actor_or_coord, "power_up", false)
			pass
		
		"quick_bad":
			spawn_effect_on_actor(actor_or_coord, "power_down", false)
			pass
		
		"buff": # Implies somewhat persistent
			spawn_effect_on_actor(actor_or_coord, "buff", true)
		
		"debuff": # Implies somewhat persistent
			pass
		
		"spark_burst":
			if actor_or_coord is Vector2:
				spawn_effect_on_tile(actor_or_coord, "spark_burst")
			elif actor_or_coord is Actor:
				spawn_effect_on_actor(actor_or_coord, "spark_burst", false)
			pass
		
		"dust": # This one needs to be a tile coord
			if actor_or_coord is Actor: actor_or_coord = actor_or_coord.coord
			spawn_effect_on_tile(actor_or_coord, "dust_cloud", false)
	pass

func spawn_effect_on_actor(actor: Actor, effect: String, persistent: bool, intensity: float = 1.0, misc: String = ""):
	var pos: Vector2 = actor.position
	var ep: Node2D = loader.res_effect_particle.instance()
	ep.set("position", pos + Vector2.DOWN)
	ep.set("actor", actor)
	ep.set("effect_name", effect)
	ep.set("persistent", persistent)
	ep.set("intensity", intensity)
	ep.set("misc", misc)
	
	batman.field.effects.add_child(ep)
	# The EP begins itself via _ready()
	pass

func spawn_effect_on_tile(coord: Vector2, effect: String, intensity: float = 1.0, misc: String = ""):
	var pos: Vector2 = batman.grid_gpos.get_cellv(coord)
	var ep: Node2D = loader.res_effect_particle.instance()
	ep.set("position", pos + Vector2.DOWN)
#	ep.set("actor", actor)
	ep.set("effect_name", effect)
	ep.set("persistent", false)
	ep.set("intensity", intensity)
	ep.set("misc", misc)
	
	batman.field.effects.add_child(ep)
	# The EP begins itself via _ready()
	pass

func end_effect_on_actor(actor: Actor, effect: String, immediate: bool = false):
	for ep in batman.field.effects.get_children():
		if ep.actor == actor:
			if ep.effect_name == effect:
				# Valid!
				if immediate:
					ep.quick_clear()
				else:
					ep.end_persistent()
	pass



# TILE CROSSOVER EFFECTS AND IMPACTS -------------------------------------------

func TILE_event_turn_started_on(actor: Actor, coord: Vector2):
	if !TILE_any_event_precheck(actor): return
	
	# Self-explanatory, but only happens at the start of THAT actor's turn, not the start of overall combat
	
	var tiletype: int = batman.grid_tiles.get_cellv(coord)
	var tilestring: String = get_tiletype_as_string(tiletype)
	var segment: String = "started_on"
	if has_method(str("TILE_",segment,"_",tilestring)):
		call(str("TILE_",segment,"_",tilestring), actor, coord)
	if has_method(str("TILE_",segment,"_ANY")):
		call(str("TILE_",segment,"_ANY"), actor, coord)
	pass

func TILE_event_exit(actor: Actor, coord: Vector2): # EXITED coord
	if !TILE_any_event_precheck(actor): return
	
	# This means we have departed and left from one tile to another - should be called BEFORE entry, if we're doing both at once!
	
	var tiletype: int = batman.grid_tiles.get_cellv(coord)
	var tilestring: String = get_tiletype_as_string(tiletype)
	var segment: String = "exited"
	if has_method(str("TILE_",segment,"_",tilestring)):
		call(str("TILE_",segment,"_",tilestring), actor, coord)
	if has_method(str("TILE_",segment,"_ANY")):
		call(str("TILE_",segment,"_ANY"), actor, coord)
	pass

func TILE_event_entry(actor: Actor, coord: Vector2):
	if !TILE_any_event_precheck(actor): return
	
	# This could be from walking over, OR re-called upon landing (if we were in the air, we'd have been immune on initial check)
	
	var tiletype: int = batman.grid_tiles.get_cellv(coord)
	var tilestring: String = get_tiletype_as_string(tiletype)
	var segment: String = "entered"
	if has_method(str("TILE_",segment,"_",tilestring)):
		call(str("TILE_",segment,"_",tilestring), actor, coord)
	if has_method(str("TILE_",segment,"_ANY")):
		call(str("TILE_",segment,"_ANY"), actor, coord)
	pass

func TILE_event_rest(actor: Actor, coord: Vector2):
	if !TILE_any_event_precheck(actor): return
	
	# Any time the actor performs an action that does NOT move it tiles or count as a movement in some way (a bit ambiguous, atm). Essentially 'you remained on this tile rather than left it'
	
	var tiletype: int = batman.grid_tiles.get_cellv(coord)
	var tilestring: String = get_tiletype_as_string(tiletype)
	var segment: String = "rested_on"
	
	if has_method(str("TILE_",segment,"_",tilestring)):
		call(str("TILE_",segment,"_",tilestring), actor, coord)
	if has_method(str("TILE_",segment,"_ANY")):
		call(str("TILE_",segment,"_ANY"), actor, coord)
	pass

func TILE_event_turn_ended_on(actor: Actor, coord: Vector2):
	if !TILE_any_event_precheck(actor): return
	
	# Exclusively when the turn is normally called to end, *not* on interruption - if the actor is dead, why bother!
	
	var tiletype: int = batman.grid_tiles.get_cellv(coord)
	var tilestring: String = get_tiletype_as_string(tiletype)
	var segment: String = "ended_on"
	if has_method(str("TILE_",segment,"_",tilestring)):
		call(str("TILE_",segment,"_",tilestring), actor, coord)
	if has_method(str("TILE_",segment,"_ANY")):
		call(str("TILE_",segment,"_ANY"), actor, coord)
	pass

# Precheck must be passed to bother engaging with anything else going on here
func TILE_any_event_precheck(actor: Actor) -> bool:
	if !utils.actorpass(actor): return false
	
	if !actor.is_on_ground: return false
	
	if actor.weight == actor.weightclasses.HOVER: return false
	
	return true

func get_tiletype_as_string(tiletype: int) -> String:
	return batman.tt_as_strings[tiletype]

func get_tilestring_as_int(tilestring: String) -> int:
	var index: int = -1
	for e in batman.tt_as_strings:
		index += 1 # Makes it 0-based
		
		if e == tilestring:
			return index
		
	
	return -1
	pass

# If you START your turn on a tiletype -----------------------------------------

func TILE_started_on_HOT(actor: Actor, _coord: Vector2):
	# Gain 1 AP - fire immunity doesn't matter here, you get the upside regardless
	
	quick_effect(actor, "quick_good")
	actor.add_bonus_actions(1)
	pass

# The moment you ENTER a tiletype MID-turn -------------------------------------
	# Also triggers if a tile is changed beneath your feet, whether your turn or not

# warning-ignore:unused_argument
func TILE_entered_ICE(actor: Actor, coord: Vector2):
	if !is_affected_by_ice(actor): return
	
	# We need to know the direction-vector you entered from, and if it was a jump or 'walk' type of movement. Ignore if not walking!
	
	# Remove any existing queued 'this actor slips' ice-related actionstep - it's only ever the most RECENT ice slide that matters, and there can only be one ice actionstep per actor happening or about to happen at a time!
	
	# If we CANNOT keep sliding, give up
	
	# If we CAN slide, prepare to do so as the next actionstep for as many ice tiles in a row are happening!
		# This replaces any upcoming 'this actor slips' ice-related actionstep. There can only be one ice actionstep per actor happening or about to happen at a time!
	pass

func TILE_entered_SHRUB(actor: Actor, coord: Vector2):
	if !is_affected_by_shrub(actor): return
	actor.spend(1)
	pass

func TILE_entered_JAGGED(actor: Actor, coord: Vector2):
	if is_affected_by_jagged(actor):
		# 1 damage, 1 move debuff
		quick_effect(actor, "quick_bad")
		do_impact_damage(null, actor, 4)
		actor.spend(1)
		pass
	
	if is_fixes_jagged_on_contact(actor):
		# Then fix the tile
		support.change_tiletype_single(coord, batman.tiletypes.NORMAL)
		pass
	pass

func TILE_entered_POISON(actor: Actor, _coord: Vector2):
	if actor.is_immune_poison: return
	
	# Immediately take 1 damage
	do_quiet_damage(null, actor, 1, ["piercing"])
	pass

# If you REST on a tiletype MID-turn -------------------------------------------
	# Resting is taking an action that does not contain/involve movement

# warning-ignore:unused_argument
func TILE_rested_on_ANY(actor: Actor, _coord: Vector2):
	
	# "LODESTONE" CHECK
	TILE_check_MAGNET(actor)
	
	pass

func TILE_rested_on_POISON(actor: Actor, _coord: Vector2):
	if actor.is_immune_poison: return
	
	# Immediately take 1 damage
	do_quiet_damage(null, actor, 1, ["piercing"])
	pass

func TILE_check_MAGNET(actor: Actor) -> bool:
	if actor.is_immune_magnet: return false
	if !is_affected_by_force(actor): return false
	
	if batman.grid_tiles.get_cellv(actor.coord) == batman.tiletypes.MAGNET:
		# We're already on a magnet, so don't bother
		return false
	
	# Check for adjacent magnets! If multiple, do nothing. If there is only 1 *valid* magnet (within your traversable rules), get dragged on to it.
	var adj_valid_magnets: Array = []
	for adjcoord in support.get_adj_orthagonal_tiles(actor.coord):
		if batman.grid_tiles.get_cellv(adjcoord) == batman.tiletypes.MAGNET:
			if support.is_tile_traversable_exact(actor, adjcoord):
				adj_valid_magnets.append(adjcoord)
	
	if adj_valid_magnets.size() != 1:
		return false
	
	# Only 1 magnet + validations passed -> WE MOVE!
	var motion: Vector2 = adj_valid_magnets[0] - actor.coord
	do_quiet_motion(null, actor, motion)
	return true
	pass

# If you LEAVE a tiletype MID-turn (even mid-action) ---------------------------

# warning-ignore:unused_argument
func TILE_exited_ICE(actor: Actor, coord: Vector2):
	if !is_affected_by_ice(actor): return
	
	# Remove any 'slide on ice' actionsteps queued for this actor at the tile we're exiting (excepting the current-executing actionstep; let it clear itself). If a multi-ice slide is happening, it can just be multiple slide actions in a row. Careful not to remove ANOTHER coord's slide!
	pass

# If you END your turn on a tiletype -------------------------------------------

func TILE_ended_on_HOT(actor: Actor, _coord: Vector2):
	if !utils.actorpass(actor): return
	if actor.is_immune_fire: return
	
	# Take 1 damage unless immune
	do_quiet_damage(null, actor, 4, ["piercing", "fire"])
	pass

func TILE_ended_on_SAND(actor: Actor, _coord: Vector2):
	if !is_affected_by_sinking(actor): return

	# Lose a movestep, unless lightweight (you'll still lose 1 later for ending your turn there if that happens tho)
	pass

func TILE_ended_on_GLOWING(actor: Actor, coord: Vector2):
	if !utils.actorpass(actor): return
	
	heal_actor_at_coord(actor, coord, 4, ["light"])
	pass


# ---



func is_affected_by_jagged(actor: Actor) -> bool:
	if !TILE_any_event_precheck(actor): return false
	if actor.is_immune_jagged: return false
	if actor.weight == actor.weightclasses.HEAVY: return false
	if actor.weight == actor.weightclasses.HOVER: return false
	return true

func is_fixes_jagged_on_contact(actor: Actor) -> bool:
	if !TILE_any_event_precheck(actor): return false
	if actor.is_immune_jagged: return false # Long-term, this might not be desirable? Hotfix for Beast in June 2026
	if actor.weight == actor.weightclasses.HOVER: return false
	return true

func is_affected_by_force(actor: Actor) -> bool: # Wind AND knockback; not ice sliding - this is important because it DOESN'T fall privy to the is_on_ground or weightclasses.HOVER checks like the others!
	if !utils.actorpass(actor): return false
	
	if actor.is_unmovable: return false
	if actor.weight == actor.weightclasses.HEAVY: return false
	return true

func is_affected_by_shrub(actor: Actor) -> bool: # Overgrowth! Does it slow you down?
	if !utils.actorpass(actor): return false
	
	if actor.is_immune_shrub: return false
	return true

func is_affected_by_ice(actor: Actor) -> bool:
	if !TILE_any_event_precheck(actor): return false
	if actor.weight == actor.weightclasses.LIGHT: return false
	if actor.is_unmovable: return false
	if actor.is_immune_ice: return false
	return true

func is_affected_by_sinking(actor: Actor) -> bool:
	if !TILE_any_event_precheck(actor): return false
	if actor.weight == actor.weightclasses.LIGHT: return false
	return true

# End of tiletype checks!

# Aimflower 3x3 shorthands!

func aimflower_key_from_file(filepath: String) -> String:
	var pref: String = "res://art/bui/aimflowers/3x3 - "
	var suff: String = ".png"
	
	var key: String = filepath.replace(pref, "")
	key = key.replace(suff, "")
#	print("key is now ",key)
	return key
	pass

func aimflower_vectors_from_file(filepath: String) -> Array:
	var key: String = aimflower_key_from_file(filepath)
	return aimflower_vectors_from_key(key)
	pass

func aimflower_vectors_from_key(key: String) -> Array:
	# Note, the expected 'start' position is always the FIRST of these vectors!
	var results: Array = []
	
	match key:
		"all":
			results.append(Vector2.ZERO)
			results.append(Vector2.RIGHT)
			results.append(Vector2.LEFT)
			results.append(Vector2.DOWN)
			results.append(Vector2.UP)
			results.append(Vector2.DOWN + Vector2.RIGHT)
			results.append(Vector2.DOWN + Vector2.LEFT)
			results.append(Vector2.UP + Vector2.RIGHT)
			results.append(Vector2.UP + Vector2.LEFT)
		"backs":
			results.append(Vector2.LEFT)
			results.append(Vector2.DOWN + Vector2.LEFT)
			results.append(Vector2.UP + Vector2.LEFT)
		"diag":
			results.append(Vector2.DOWN + Vector2.RIGHT)
			results.append(Vector2.DOWN + Vector2.LEFT)
			results.append(Vector2.UP + Vector2.RIGHT)
			results.append(Vector2.UP + Vector2.LEFT)
		"east":
			results.append(Vector2.RIGHT)
		"fronts":
			results.append(Vector2.RIGHT)
			results.append(Vector2.DOWN + Vector2.RIGHT)
			results.append(Vector2.UP + Vector2.RIGHT)
		"hline":
			results.append(Vector2.ZERO)
			results.append(Vector2.RIGHT)
			results.append(Vector2.LEFT)
		"north":
			results.append(Vector2.UP)
		"orthag":
			results.append(Vector2.RIGHT)
			results.append(Vector2.LEFT)
			results.append(Vector2.DOWN)
			results.append(Vector2.UP)
		"plus":
			results.append(Vector2.ZERO)
			results.append(Vector2.RIGHT)
			results.append(Vector2.LEFT)
			results.append(Vector2.DOWN)
			results.append(Vector2.UP)
		"rim":
			results.append(Vector2.RIGHT)
			results.append(Vector2.LEFT)
			results.append(Vector2.DOWN)
			results.append(Vector2.UP)
			results.append(Vector2.DOWN + Vector2.RIGHT)
			results.append(Vector2.DOWN + Vector2.LEFT)
			results.append(Vector2.UP + Vector2.RIGHT)
			results.append(Vector2.UP + Vector2.LEFT)
		"rim_alt":
			results.append(Vector2.RIGHT)
			results.append(Vector2.LEFT)
			results.append(Vector2.DOWN)
			results.append(Vector2.UP)
			results.append(Vector2.DOWN + Vector2.RIGHT)
			results.append(Vector2.DOWN + Vector2.LEFT)
			results.append(Vector2.UP + Vector2.RIGHT)
			results.append(Vector2.UP + Vector2.LEFT)
		"sole":
			results.append(Vector2.ZERO)
		"south":
			results.append(Vector2.DOWN)
		"vline":
			results.append(Vector2.ZERO)
			results.append(Vector2.DOWN)
			results.append(Vector2.UP)
		"west":
			results.append(Vector2.LEFT)
	
#	print("variants for key [",key,"]: ",results)
	return results
	pass







