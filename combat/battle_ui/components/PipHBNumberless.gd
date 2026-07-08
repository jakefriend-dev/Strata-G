extends HBoxContainer


enum types {NOT_SET, ACTION, SHIELD}
export (types) var type: int

var value: int = 4

var bui: Node2D
var actor: Actor

# ---

func refresh():
	if type == types.SHIELD:
		value = actor.shield
	
	var to_vis: bool = true
	
	if type == types.SHIELD:
		to_vis = (value > 0)
		if visible != to_vis:
			visible = to_vis
		
		if !to_vis: return
		
		var count: int = 0 # 1-based
		for panel in get_children():
			count += 1
			var sprite: Sprite = panel.get_node("Sprite")
			var maxframe: int = count*4
			var minframe: int = maxframe-3 # Not -4 because we never actually want to see an 'empty' shield!
			var zeroframe: int = maxframe-4
			
			var pane_vis: bool = (value >= minframe)
			if panel.visible != pane_vis:
				panel.visible = pane_vis
			
			if pane_vis: # This ignores all 'value less than this icon' cases where we're invisible regardless, so value is at LEAST within our zone or higher
				if value >= maxframe:
					sprite.frame = 4
				else:
					sprite.frame = (value - zeroframe)
			
			
		
	pass
