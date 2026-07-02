extends HBoxContainer

enum types {NOT_SET, ACTION, SHIELD}
export (types) var type: int

var value: int = 4
# Preset on instancing BEFORE adding to tree, but in theory always max
# Setting this is controlled by BUI so all data is fed at once from the same general algorithm

var label: Label
var sprite: Sprite
var bui: Node2D
var actor: Actor

# ---

func _ready():
	label = $Count
	sprite = $Icon/Sprite
#	update_values() # BUI can do this
	pass

func refresh():
	if type == types.SHIELD:
		value = actor.shield
	elif type == types.ACTION:
		value = actor.action_points
	
	# Default
	var spriteframe_value: int = value
	var text_value: String = str(value)
	var to_vis: bool = true
	
	if type == types.SHIELD:
		if value == 0:
			to_vis = false
		else: # Normal circumstances, if there's ANY shield at all
			var full_pips: int = floor(float(value)/4.0)
			var full_value: int = full_pips * 4
			spriteframe_value = value - full_value
			if spriteframe_value == 0: spriteframe_value = 4
			text_value = str(full_pips)
	
	elif type == types.ACTION:
		if actor.base_action_points == 0 and value == 0:
			to_vis = false
			spriteframe_value = 5
		else:
			if value > actor.base_action_points:
				spriteframe_value = 1
			elif value > 0:
				spriteframe_value = 0
			else:
				spriteframe_value = 2
	
	# Close off by updating everything
	
	if sprite.frame != spriteframe_value:
		sprite.frame = spriteframe_value
	
	if label.text != text_value:
		label.text = text_value
	
	if visible != to_vis:
		visible = to_vis
	pass


