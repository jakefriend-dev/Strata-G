extends Node2D
class_name Actor

enum initspeeds {
	DOES_NOT_ACT,
	AUTOLAST,
	LOWGEAR_SLOW,
	LOWGEAR_FAST,
	PC_TANK,
	MIDGEAR_SLOW,
	MIDGEAR_FAST,
	PC_SNIPER,
	HIGHGEAR_SLOW,
	HIGHGEAR_FAST,
	PC_LEADER,
	TOPGEAR_SLOW,
	TOPGEAR_FAST,
	AUTOFIRST,
}
export (initspeeds) var first_initiative: int = initspeeds.LOWGEAR_FAST
export (initspeeds) var second_initiative: int = initspeeds.DOES_NOT_ACT
export (initspeeds) var third_initiative: int = initspeeds.DOES_NOT_ACT
	# An actor can optionally have up to 3 turns, for a boss; matching the party
var variance_initiative: float  = -1.0 # Cued by batman at start of combat; percentage from 0-99%

export var max_hp: int = 4
var hp: int = 4

export var def_shield: int = 0
var shield: int = 0

export var ofc_name: String = "--"

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

# Convenience references; duplicate data
var coord: Vector2

# ---

func _ready():
	perform_initial_data_setup()
	$ArtMgr/HFlipper/Shadow.recenter()
	update_bui()
	pass

func perform_initial_data_setup():
	max_hp *= 10
	hp = max_hp
	
	def_shield *= 10 # Let the start of turn determine current shield
	
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

func update_bui():
	if faction == batman.factions.PLAYER:
		is_facing_left = false
	
	if !is_facing_left:
		$ArtMgr/HFlipper.scale.x = -1.0
	
	if !has_node("BUI"):
		var bui = loader.res_bui.instance()
		add_child(bui)
	
	$BUI/MC/VB/Name.text = ofc_name
	$BUI/MC/VB/GC/Health/Value.text = str(hp)
	$BUI/MC/VB/GC/Shield/Value.text = str(def_shield)
#	$BUI/MC/VB/GC/Move/Value.text = str(hp)
#	$BUI/MC/VB/GC/Actions/Value.text = str(hp)
	
	$BUI.visible = bui_visible
	pass

# -

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



