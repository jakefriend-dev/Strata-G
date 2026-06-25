extends Node2D

var actor: Actor

export var path_health: NodePath
export var path_shield: NodePath
export var path_action: NodePath
export var path_aname: NodePath
#export var path_bonusshieldpar: NodePath
#export var path_bonusactionpar: NodePath
var piphealth: PipSet
var pipshield: PipSet
var pipaction: PipSet
var aname: Label
#var bonusactionpar: GridContainer


func _ready():
	aname = get_node(path_aname)
	connect_pips()
	
	actor.connect("on_phys_combat_any_contact", self, "check_bui_tier_on_hit")
	pass

func connect_pips():
	piphealth = get_node(path_health)
	pipshield = get_node(path_shield)
	pipaction = get_node(path_action)
#	bonusshieldpar = get_node(path_bonusshieldpar)
#	bonusactionpar = get_node(path_bonusactionpar) # Not needed; shared!
	
	piphealth.actor = actor
	pipshield.actor = actor
	pipaction.actor = actor
	
	piphealth.refresh_against_actor()
	pipshield.refresh_against_actor()
	pipaction.refresh_against_actor()
	pass

func update_all():
	var print_name: String = actor.get_multifactored_actor_name()
	if aname.text != print_name:
		aname.text = print_name
	
	piphealth.refresh_against_actor()
	pipshield.refresh_against_actor()
	pipaction.refresh_against_actor()
	
	if visible != ought_be_visible():
		visible = ought_be_visible()
	pass

func ought_be_visible() -> bool:
	
	if (actor.bui_level == actor.bui_tiers.FULL
	or actor.bui_level == actor.bui_tiers.JUST_PIPS
	or actor.bui_level == actor.bui_tiers.JUST_HEALTH):
		return true
	
	return false

func check_bui_tier_on_hit():
	if actor.bui_level == actor.bui_tiers.INVIS_UNTIL_HIT:
		actor.bui_level = actor.bui_tiers.JUST_HEALTH
	pass
