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
