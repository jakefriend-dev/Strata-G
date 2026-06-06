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

# Made up a few on the fly here, probably no harm
enum elements {NORMAL, FIRE, WATER, ELEC, MAGIC, POISON, ROCK, AIR, ICE, SHADOW}

enum hitrange {CONTACT, DISTANT}

enum impacts {PHYSICAL, ABSTRACT}

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

# ---


func damage_actor_at_coord(attacker: Actor, exact_coord: Vector2, damage: int, is_melee: bool, friendly_fire: bool = true):
	if !batman.grid_actors.has_cellv(exact_coord): return
	
	var victim: Actor = batman.grid_actors.get_cellv(exact_coord)
	if victim == null:
		return
	
	if victim.faction == attacker.faction:
		if !friendly_fire:
			return
	
	victim.receive_damage(damage, is_melee)
	pass

# ---

func quick_effect(actor_or_coord, effect: String, variant = null):
	match effect:
		
		"damage":
			spawn_effect_on_actor(actor_or_coord, "damage", false, float(variant))
		
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
		
		"dust":
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

# If you START your turn on a tiletype -----------------------------------------

func TILE_started_on_HOT(_actor: Actor):
	# Gain 1 AP - fire immunity doesn't matter here, you get the upside regardless
	pass

# The moment you ENTER a tiletype MID-turn -------------------------------------
	# Also triggers if a tile is changed beneath your feet, whether your turn or not

func TILE_entered_JAGGED(actor: Actor):
	if is_affected_by_jagged(actor):
		# 1 damage, 1 move debuff
		pass
	
	if is_fixes_jagged_on_contact(actor):
		# Then fix the tile
		pass
	pass

func TILE_entered_ICE(actor: Actor):
	if !is_affected_by_ice(actor): return
	
	# We need to know the direction-vector you entered from, and if it was a jump or 'walk' type of movement. Ignore if not walking!
	
	# Remove any existing queued 'this actor slips' ice-related actionstep - it's only ever the most RECENT ice slide that matters, and there can only be one ice actionstep per actor happening or about to happen at a time!
	
	# If we CANNOT keep sliding, give up
	
	# If we CAN slide, prepare to do so as the next actionstep for as many ice tiles in a row are happening!
		# This replaces any upcoming 'this actor slips' ice-related actionstep. There can only be one ice actionstep per actor happening or about to happen at a time!
	pass

func TILE_entered_POISON(actor: Actor):
	if actor.is_immune_poison: return
	
	# Immediately take 1 damage
	pass

func TILE_entered_MUD(actor: Actor):
	if actor.is_immune_mud: return
	if !is_affected_by_sinking(actor): return
	
	# Lose a movestep, unless lightweight (in which case it checks at end-of-turn instead)
	pass

func TILE_entered_WATER(actor: Actor):
	if actor.is_immune_water: return
	# Lose a movestep, unless you're a swimmer (lightweight doesn't matter here)
	pass

# If you REST on a tiletype MID-turn -------------------------------------------
	# Resting is taking an action that does not contain/involve movement

func TILE_rested_on_ANY(actor: Actor):
	if actor.is_immune_magnet: return
	# Check for adjacent magnets! If multiple, do nothing. If there is only 1 (within your traversable rules), get dragged on to it.
	pass

# If you LEAVE a tiletype MID-turn (even mid-action) ---------------------------

func TILE_exited_ICE(actor: Actor):
	if !is_affected_by_ice(actor): return
	
	# Remove any 'slide on ice' actionsteps queued for this actor at the tile we're exiting (excepting the current-executing actionstep; let it clear itself). If a multi-ice slide is happening, it can just be multiple slide actions in a row. Careful not to remove ANOTHER coord's slide!
	pass

# If you END your turn on a tiletype -------------------------------------------

func TILE_ended_on_HOT(actor: Actor):
	if actor.is_immune_fire: return
	
	# Take 1 damage unless immune
	pass

func TILE_ended_on_SAND(actor: Actor):
	if !is_affected_by_sinking(actor): return

	# Lose a movestep, unless lightweight (you'll still lose 1 later for ending your turn there if that happens tho)
	pass

func TILE_ended_on_MUD(actor: Actor):
	if is_affected_by_sinking(actor): return
	
	# Lightweight actors should sink now, since they didn't earlier (everyone else should already be sunk)
	pass

# ---

func is_affected_by_jagged(actor: Actor) -> bool:
	if actor.is_immune_jagged: return false
	if actor.weight == actor.weightclasses.HEAVY: return false
	if actor.weight == actor.weightclasses.HOVER: return false
	return true

func is_fixes_jagged_on_contact(actor: Actor) -> bool:
	if actor.weight == actor.weightclasses.HOVER: return false
	return true

func is_affected_by_force(actor: Actor) -> bool: # Wind AND knockback; not ice sliding
	if actor.is_unmovable: return false
	if actor.weight == actor.weightclasses.HEAVY: return false
	return true

func is_affected_by_ice(actor: Actor) -> bool:
	if actor.weight == actor.weightclasses.LIGHT: return false
	if actor.is_unmovable: return false
	if actor.is_immune_ice: return false
	return true

func is_affected_by_sinking(actor: Actor) -> bool:
	if actor.weight == actor.weightclasses.LIGHT: return false
	return true

# End of tiletype checks!










