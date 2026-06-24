extends HBoxContainer
# Change this once we know what the top node should be

enum the_types {TBD, ACTION_POINTS, HEALTH, SHIELD}
export (the_types) var type: int

var spacing_min_left: float = 6.0
var spacing_interval_left: float = 4.0
var spacing_min_right: float = 6.0
var spacing_interval_right: float = 4.0

export var max_units:  int = 0
export var curr_units: int = 0

var side_units_left: int = 0
var side_units_right: int = 0
var center_unit_value: int = 4 # Like the 4-corners of health

var actor: Actor

# ---

func refresh_against_actor():
	if !utils.actorpass(actor): return
	
	match type:
		the_types.ACTION_POINTS:
			update_values(actor.action_points, actor.action_points)
		the_types.HEALTH:
			update_values(actor.health, actor.max_health)
		the_types.SHIELD:
			update_values(actor.shield, actor.max_shield)
	pass

func update_values(new_curr: int, new_max: int = max_units):
	if new_curr < 0: return
	if new_max < 0: return
	if new_curr < new_max: new_curr = new_max # Don't worry about bonus AP/shield yet?
	
	curr_units = new_curr
	max_units = new_max
	
	determine_units()
	update_visuals()
	pass

func determine_units():
	# Take total values and update to each unit type!
	
	if max_units == 0:
		side_units_left = 0
		center_unit_value = 0
		side_units_right = 0
		return
	
	# Action points have no sub-points, unlike shields/health
	if type == the_types.ACTION_POINTS:
		side_units_right = (max_units - curr_units)
		if curr_units == 0:
			side_units_left = 0
			center_unit_value = 0
		else:
			side_units_left = (curr_units - 1)
			center_unit_value = 1
		return
	
	# Get the 'main' current values
	var full_main_units: int = floor(float(curr_units)/4.0)
	center_unit_value = (curr_units - full_main_units)
	side_units_left = full_main_units/4
	
	# Get the max beyond that (ignore the possible center 4)
	var not_right_units: int = full_main_units + 4
	var right_units: int = max_units - not_right_units
	side_units_right = right_units/4
	pass

func update_visuals():
	# Left side
	var left_to_vis: bool = true
	if side_units_left == 0:
		left_to_vis = false
	else:
		get_node("L").rect_size.x = (2 + (side_units_left*4))
	if get_node("L").visible != left_to_vis:
		get_node("L").visible = left_to_vis
	
	# Right side
	var right_to_vis: bool = true
	if side_units_right == 0:
		right_to_vis = false
	else:
		get_node("R").rect_size.x = (2 + (side_units_right*4))
		if type == the_types.ACTION_POINTS:
			get_node("C/R2").rect_size.x = get_node("R").rect_size.x
	if get_node("R").visible != right_to_vis:
		get_node("R").visible = right_to_vis
		if type == the_types.ACTION_POINTS:
			get_node("C/R2").visible = right_to_vis
	
	# Center
	match type:
		the_types.ACTION_POINTS:
			var center_to_vis: bool = (center_unit_value > 0)
			if get_node("C").visible != center_to_vis:
				get_node("C").visible = center_to_vis
		the_types.HEALTH:
			get_node("C/Sprite").frame = center_unit_value
		the_types.SHIELD:
			get_node("C/Sprite").frame = center_unit_value
			var center_to_vis: bool = (center_unit_value > 0)
			if get_node("C").visible != center_to_vis:
				get_node("C").visible = center_to_vis
	pass






#
# AP PIPS:
#	- LEFT: Mix 6, and +4 per pip
#	- RIGHT: Ditto left
#
# HEALTH PIPS:
#	- Left/Right Ditto AP
#
# SHIELD: Totally ditto Health
#
#
#
#
#
