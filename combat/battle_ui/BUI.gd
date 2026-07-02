extends Node2D

var actor: Actor

export var path_actorname: NodePath
export var path_midplate: NodePath
export var path_action: NodePath
export var path_shield: NodePath
export var path_status: NodePath

var actorname: Label
var midplate: HBoxContainer
var health: VBoxContainer
var action: HBoxContainer
var shield: HBoxContainer
var status: HBoxContainer

var res_hp
var hpips: Array = []
var hp_row_size: int = 4

# Just quick local references; updated immediately before each refresh
var CH: int
var MH: int

# ---

func _ready():
	connect_pips()
	
	actor.connect("on_phys_combat_any_contact", self, "check_bui_tier_on_hit")
	pass

func connect_pips():
	actorname = get_node(path_actorname)
	midplate = get_node(path_midplate)
	action = get_node(path_action)
	shield = get_node(path_shield)
	status = get_node(path_status)
	
	action.bui = self
	action.actor = actor
	
	shield.bui = self
	shield.actor = actor
	
	status.bui = self
	status.actor = actor
	
	if actor.base_health_pips <= 8:
		health = midplate.get_node("10xSize")
		res_hp = loader.res_hp_10
		if actor.base_health_pips <= 5:
			hp_row_size = 5
		else:
			hp_row_size = 4
	elif actor.base_health_pips <= 12:
		res_hp = loader.res_hp_8
		health = midplate.get_node("8xSize")
		hp_row_size = 6
	else:
		health = midplate.get_node("6xSize")
		res_hp = loader.res_hp_6
		hp_row_size = 9
	
	# Generate all needed health pip scene instances, add them to our array, and add them to the scene (under the appropriate row)
	
	var count: int = 0 # 1-based shortly
	var col_num: int = 0 # 1-based shortly
	var row_num: int = 1
	var row: HBoxContainer = health.get_node(str("R",row_num))
	for n in actor.base_health_pips:
		count += 1
		if count > 27: break # Our max possible, atm
		
		col_num += 1
		if col_num > hp_row_size:
			col_num = 1
			row_num += 1
			row = health.get_node(str("R",row_num))
			row.visible = true
		
		var pip = res_hp.instance()
		pip.set("name", str(count))
		pip.set("value", 4)
		pip.set("pipcount", count)
		pip.set("bui", self)
		row.add_child(pip)
		hpips.append(pip)
	pass

func refresh():
	# Get the simple stuff out of the way first
	var print_name: String = actor.get_multifactored_actor_name()
	if actorname.text != print_name:
		actorname.text = print_name
	
	action.refresh()
	shield.refresh()
	status.refresh()
	
	# Now for health!
	
	CH = actor.health
	MH = actor.max_health
	
	for pip in hpips:
		var to_frame: int
		var hmax: int = pip.pipcount*4
		var hmin: int = hmax-4
		
		if CH <= hmin:
			to_frame = 0
		elif CH >= hmax:
			to_frame = 4
		else:
			to_frame = CH - hmin
		
		pip.value = to_frame
		pip.refresh()
		pass
	
	#
	
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
