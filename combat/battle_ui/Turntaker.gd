extends Node2D

var actor: Actor

export var path_portrait: NodePath
export var path_nameplate: NodePath
export var path_midplate: NodePath
export var path_botplate: NodePath
export var path_actionpar: NodePath
export var path_cr: NodePath
var portrait: Node2D
var nameplate: Panel
var midplate: HBoxContainer
var botplate: HBoxContainer
var actionpar: VBoxContainer
var cr: ColorRect
# Below are relative-dynamic based on the above
var namelabel: Label
var hp_bar: HBoxContainer
var shield_bar: HBoxContainer
var hp_num: HBoxContainer
var statuspar: HBoxContainer
var apb: VBoxContainer
var portrait_art: Sprite

enum {ZERO, PORTRAIT, NAME, HEALTH, STATUS, ACTIONS, MAXIMUM} # In progressive order; typically STATUS for current turntaker and PORTRAIT for non-currents
var vis_state: int = STATUS

var turn_order: int = -1 # Treat -1 as invalid; numbers >0 as valid
var linked_ttd: Dictionary

var shake_dur: float = 0.0

# Used by TurntakerWindow to vet us!
var no_longer_valid: bool = false

# ---

func _ready():
	portrait = get_node(path_portrait)
	nameplate = get_node(path_nameplate)
	midplate = get_node(path_midplate)
	botplate = get_node(path_botplate)
	actionpar = get_node(path_actionpar)
	cr = get_node(path_cr)
	
	namelabel = nameplate.get_node("NameActual")
	hp_bar = midplate.get_node("HealthBar")
	shield_bar = midplate.get_node("ShieldBar")
	hp_num = botplate.get_node("HealthNum")
	statuspar = botplate.get_node("Status")
	apb = actionpar.get_node("ActionPointBar")
	portrait_art = portrait.get_node("IconSprite")
	
	batman.connect("this_actor_any_bui_update", self, "check_for_updates")
	
	var count: int = 0 # 1-based
	for panel in hp_bar.get_children():
		count += 1
		panel.pipcount = count
	
	count = 0
	for panel in shield_bar.get_children():
		count += 1
		panel.pipcount = count
	pass

func set_actor(incoming_actor: Actor):
	if !utils.actorpass(incoming_actor): return
	
	actor = incoming_actor
	statuspar.actor = actor
	
	update_values()
	update_visible()
	pass

func refresh():
	update_values()
	update_visible()
	pass

func check_for_updates(check_actor: Actor):
	if check_actor != actor: return
	update_values()
	update_visible()
	pass

func update_values():
	if !utils.actorpass(actor): return
	
	# Section here for portrait, *eventually!*
	
	# Name
	if namelabel.text != actor.ofc_name:
		namelabel.text = actor.ofc_name
	
	# Healthbar
	var hp_percent: float = float(actor.health)/float(actor.max_health)
	var value_for_bar: int = round((hp_percent*20.0))*2 # Slightly different formula here means we're not going to have any quarters, just halves, for a cleaner 'bar' visual
	for panel in hp_bar.get_children():
		var value_max: int = panel.pipcount * 4
		var value_min: int = value_max - 4
		
		var sprite: Sprite = panel.get_node("Sprite")
		var to_frame: int
		if value_for_bar >= value_max:
			to_frame = 4
		elif value_for_bar <= value_min:
			to_frame = 0
		else:
			to_frame = value_max - value_for_bar
		if sprite.frame != to_frame:
			sprite.frame = to_frame
	
	# Health colour tint
	var target_height: float = round((1.0 - hp_percent) * 24.0)
	if cr.rect_size.y != target_height:
		# We've taken damage!
		damage_impact_effect()
		cr.rect_size.y = target_height
	
	# Health number
	var hp_fullnum: int = floor(float(actor.health)/4.0)
	var hp_label: Label = hp_num.get_node("VB/HP_Count")
	if hp_label.text != str(hp_fullnum):
		hp_label.text = str(hp_fullnum)
		
	var hp_singlepip_frame: int = actor.health - (hp_fullnum*4)
	var hp_singlepip: Sprite = hp_num.get_node("PanelPip/Sprite")
	if hp_singlepip_frame == 0 and actor.health > 0: hp_singlepip_frame = 4
	if hp_singlepip.frame != hp_singlepip_frame:
		hp_singlepip.frame = hp_singlepip_frame
	
	# Shieldbar
	value_for_bar = actor.shield
	for panel in shield_bar.get_children():
		var to_vis: bool = true # Only shield visibility is handled here, because it's part of how it's counted
		
		var value_max: int = panel.pipcount * 4
		var value_min: int = value_max - 4
		
		var sprite: Sprite = panel.get_node("Sprite")
		var to_frame: int
		if value_for_bar >= value_max:
			to_frame = 4
		elif value_for_bar <= value_min:
			to_frame = 0
			to_vis = false
		else:
			to_frame = value_for_bar - value_min
		if sprite.frame != to_frame:
			sprite.frame = to_frame
		
		if panel.visible != to_vis:
			panel.visible = to_vis
	
	# Statuses
	statuspar.refresh()
	
	# Action points
	var ap_curr: int = actor.action_points
	var ap_total: int = actor.base_action_points
	apb.get_node("Text/Curr").text = str(ap_curr)
	apb.get_node("Text/Total").text = str(ap_total)
	
	var ap_count: int = 0 # 1-based
	for pip in apb.get_node("Pips").get_children():
		if pip.name == "MinPanel": continue
		ap_count += 1
		
		var to_vis: bool = (ap_curr >= ap_count or ap_total >= ap_count)
		if pip.visible != to_vis:
			pip.visible = to_vis
		
		var frame: int = 2 # "Greyed out" by default
		if ap_curr >= ap_count:
			if ap_count > ap_total:
				frame = 1
			else:
				frame = 0
		pip.get_node("Sprite").frame = frame
		
		var crack_frame: int = 0
		if ap_curr == ap_count and ap_curr > 0:
			crack_frame = actor.action_cracking
		pip.get_node("Sprite/Cracking").frame = crack_frame
	pass

func update_visible():
	var effective_state: int = vis_state
	if !utils.actorpass(actor):
		effective_state = PORTRAIT
#		effective_state = ZERO
	
	if visible != (effective_state >= PORTRAIT):
		visible = (effective_state >= PORTRAIT)
	
	if utils.actorpass(actor):
		portrait_art.visible = (actor.ofc_name == "Mage")
	
	if nameplate.visible != (effective_state >= NAME):
		nameplate.visible = (effective_state >= NAME)
	
	if midplate.visible != (effective_state >= HEALTH):
		midplate.visible = (effective_state >= HEALTH)
	
	if botplate.visible != (effective_state >= STATUS):
		botplate.visible = (effective_state >= STATUS)
	
	if actionpar.visible != (effective_state >= ACTIONS):
		actionpar.visible = (effective_state >= ACTIONS)
	
	pass

# ---

func damage_impact_effect():
	shake_dur = 0.125
	pass

func _physics_process(d: float):
	if is_zero_approx(shake_dur):
		if portrait.position != Vector2.ZERO:
			portrait.position = Vector2.ZERO
	else:
		var shake: float = 2.5
		portrait.position.x = rand_range(-shake, shake)
		portrait.position.y = rand_range(-shake, shake)
	
	if shake_dur > 0:
		shake_dur -= d
		if shake_dur < 0: shake_dur = 0
	pass





