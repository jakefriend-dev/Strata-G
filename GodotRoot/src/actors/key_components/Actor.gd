extends Node2D
class_name Actor

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
var bui: Node2D

export var base_damage: int = 1 # For attack shortcuts for simple mobs

enum factions { # Local copy of TurnMgr, must be an exact duplicate!
	NEUTRAL,
	PLAYER,
	ENEMY,
}
export (factions) var faction: int = factions.ENEMY # Enemy if not manually set
var is_facing_left: bool = true # Default true for enemies; false for party

export var bui_visible: bool = true

#enum weightclasses {
#	HOVER,  # Flying; not affects by the ground beneath it at all
#	LIGHT,  # Doesn't sink into tiles; doesn't break cracked tiles
#	NORMAL, # Standard; affected by things as usual
#	HEAVY,  # Unaffected by knockback
#}

# Defaults first; manually set
#export (weightclasses) var def_weight: int = weightclasses.NORMAL

export var def_hovering:			bool = false # Not affected by ground type or pits at all
export var def_lightweight:			bool = false # Not affected by tiles that you sink in, like mud
#													# Also doesn't break cracked tiles
export var def_immune_knockback:	bool = false # Not affected by knockback
export var def_immune_fire:			bool = false # Not affected by ember floors
export var def_immune_water:		bool = false # Not slowed by water tiles (even lightweights are)
export var def_immune_ice:			bool = false # Doesn't slide on ice
export var def_immune_poison:		bool = false # Doesn't take poison damage
export var def_immune_magnet:		bool = false # Not pulled by magnet tiles
export var def_immune_elec:			bool = false # Doesn't take elec damage on static traps

#var weight: int
var is_hovering: bool
var is_lightweight: bool
var is_immune_knockback: bool
var is_immune_fire: bool
var is_immune_water: bool
var is_immune_ice: bool
var is_immune_poison: bool
var is_immune_magnet: bool
var is_immune_elec: bool

var is_ghost: bool = false # When true, allowed to break many rules. You almost ALWAYS turn this off at the end of a turn; meant as a temporary thing for like a charge-through attack.
var allowed_over_faction_lines: bool = false
export var keep_claims_at_eot: bool = false # Set true for the RARE cases (like a missile) where you don't want to wipe its claim at the end of a turn

# Convenience references; duplicate data to batman.grid_actors
var last_pos: Vector2 = Vector2.ZERO
var coord: Vector2
var claimed_tile: Vector2 = Vector2.ZERO

signal shield_broken() # Shield broke but NOT dead

# ---

func _ready():
	perform_initial_data_setup()
	$ArtMgr/HFlipper/Shadow.recenter()
	update_bui()
	
	batman.connect("pre_turn_refresh", self, "pre_turn_refresh")
	pass

func perform_initial_data_setup():
	max_health *= batman.BASE_HP_UNIT
	health = max_health
	
	max_shield *= batman.BASE_HP_UNIT # Let the start of turn determine current shield
	shield = max_shield
	
	for term in ["hovering", "lightweight", "immune_knockback", "immune_fire", "immune_water", "immune_ice", "immune_poison", "immune_magnet", "immune_elec"]:
		set( str("is_"+term), get(str("def_",term)) )
#	weight = def_weight
	pass

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

func pre_turn_refresh(who: Actor):
	if who != self: return
	
#	print("Pre-turn refresh for ",self)
	shield = max_shield
	update_bui()
	pass

func end_action():
	act.step_signal()
	pass

func end_turn():
	batman.end_turn()
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
		act.remove_actor_from_actorgrid(self)
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
		return true
	pass

func claim_tile(claiming_coord: Vector2 = Vector2(-99, -99)) -> bool:
	if Vector2(-99, -99): claiming_coord = coord
	
	# Only one claim is ever allowed at a time!
	act.release_actor_claims(self)
	claimed_tile = Vector2.ZERO
	
	if act.is_tile_available(claiming_coord, self):
		batman.grid_claims.set_cellv(claiming_coord, self)
		claimed_tile = claiming_coord
		return true
	
	return false
	pass

func release_claims():
	act.release_actor_claims(self)
	pass

func _process(_delta):
	monitor_position_as_coordinate()
	pass

func monitor_position_as_coordinate():
	if last_pos == position: return
	
	last_pos = position
	var last_coord: Vector2 = coord
	
	coord = batman.field.actorpos_to_tilecoord(position)
	if coord == last_coord: return
	if is_ghost: return
	
	# We always want to track our own coordinate personally, but don't want to manage the grid coord unless we're not a ghost
	
	act.change_actor_coord(self, coord)
	pass

# ---

func receive_damage(damage: int):
	if damage <= 0:
		print(name,": No damage to receive")
		return
	
	var og_damage: int = damage
	var og_shield: int = shield
	
	# Deduct damage and shield equally until either of them depletes fully
	while (bonus_shield > 0 or shield > 0) and damage > 0:
		damage -= 1
		if bonus_shield > 0:
			bonus_shield -= 1
		else:
			shield -= 1
	
	if og_shield > 0 and shield == 0:
		emit_signal("shield_broken")
	
	var shielded_damage: int = og_damage - damage
	if damage <= 0:
		print(name,": Blocked ",shielded_damage," and took no damage, ",shield," shield remains")
		update_bui()
		return
	
	while health > 0 and damage > 0:
		damage -= 1
		health -= 1
	
	var unshielded_damage: int = og_damage - shielded_damage - damage
	
	if health > 0:
		if shielded_damage == 0:
			print(name,": Took ",og_damage," damage, ",health," health remains")
		else:
			print(name,": Blocked ",shielded_damage," and took ",unshielded_damage," damage, ",shield," shield  and ",health," health remains")
		update_bui()
		return
	else:
		print(name,": Died from taking ",unshielded_damage," (blocked ",shielded_damage,")")
		batman.kill_actor(self)
		
	
	pass
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
	bui.visible = bui_visible
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
		sm.set_shader_param("c8f3fcf0", to_col)
	sm.set_shader_param("outline_enabled", use_outline)
	pass

# -

func is_targeted() -> bool:
	return false

func _to_string() -> String:
	if ofc_name != "--":
		return ofc_name
	else:
		return name



