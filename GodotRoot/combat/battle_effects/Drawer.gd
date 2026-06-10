extends Node2D

var APD: ActionPreviewData # We never WIPE from this script though, since it might be linked
var drawing: bool = false

var prio_order: Array = [
	ActionPreviewData.ROWS.PASS,
	ActionPreviewData.ROWS.ERROR,
	ActionPreviewData.ROWS.FALLBACK,
	ActionPreviewData.ROWS.NEUTRAL,
	ActionPreviewData.ROWS.BAD,
	ActionPreviewData.ROWS.GOOD
]

func _ready():
	batman.connect("new_action_preview_data_readied", self, "draw_action_preview")
#	batman.connect("action_step_complete", self, "begin_drawing")
		# We don't want this ^ We want the actor to use this signal to redraw!
	
	batman.connect("any_actionstep_initiated", self, "end_drawing")
	batman.connect("on_turn_ended_naturally", self, "end_drawing")
	batman.connect("on_turn_ended_via_interruption", self, "end_drawing")
	pass

func clear_action_preview():
	APD = ActionPreviewData.new()
	end_drawing()
	pass

func begin_drawing():
	drawing = true
	update()
	pass

func end_drawing():
	drawing = false
	update()
	pass

func draw_action_preview(new_APD: ActionPreviewData):
	APD = new_APD # We never WIPE from this script though, since it might be linked
	begin_drawing()
	
	pass

func _draw():
	if !drawing: return
	if APD == null: return
	draw_all_arrows(true)
	draw_all_arrows(false)
	pass

func draw_all_arrows(is_outline: bool):
#	var arrowsets: Array = [] # We want to add a series of [Rect2, Color] sets!
	
	# First, GATHER all the data!
	var y: int = -1
	for row in APD.ROWS.size():
		y += 1 # 0-based
		
		var index: int = prio_order[y]
		var arrow_array: Array = APD.sets.get_cell(APD.COLS.ARROW_ARRAY, index)
		var col: Color = APD.colors[index]
		var width: float = 4.0
		if index == APD.ROWS.PASS or index == APD.ROWS.ERROR:
			width = 2.0
			if is_outline:
				continue
		if is_outline:
			width += 4.0
			col = Color.black
			col.a = 0.5
		
		for arrow_rect in arrow_array: if arrow_rect is Rect2:
			var start: Vector2 = arrow_rect.position
			var end: Vector2 = arrow_rect.size
			if is_outline:
				var adj: float = 2.0
				start += Vector2(adj, adj)
				end += Vector2(adj, adj)
			draw_arrow(start, end, col, index, width)
	pass

func draw_arrow(
	start: Vector2,
	end: Vector2,
	color: Color,
	index: int,
	width: float,
	head_length: float = 0.15,
	head_angle: float = PI / 4.0
	):
		# Get the details in order for the initial line!
		
		
		
		var dir: Vector2 = end - start
		dir = dir.normalized()
		var cell_len: Vector2 = dir * batman.field.CELL_SIZE
		var adjust: float = 0.25
		
		start = start + (cell_len * adjust)
		if index == APD.ROWS.PASS:
			end = end + (cell_len * adjust)
		elif index == APD.ROWS.ERROR:
			end = end - (cell_len * adjust)
		
		# Main line
		draw_line(start, end, color, width, true)
		
		# Now we prep the head!
		var head_len: Vector2 = cell_len * head_length
		var head_center = end + (head_len * 0.5)
		var head_right = end - head_len.rotated(head_angle)
		var head_left = end - head_len.rotated(-head_angle)
		draw_line(head_center, head_left, color, width, true)
		draw_line(head_center, head_right, color, width, true)
#		draw_polyline([head_right, head_center, head_left], color, width)
#		draw_colored_polygon([head_right, head_center, head_left], color)
		
#		target -= origin * 2
#		var head: Vector2 = -target.normalized() * head_length
#		var end = -target.normalized() * head_length / 2 + target + origin
#		target += origin
#		var head_right = target + head.rotated(head_angle)
#		var head_left = target + head.rotated(-head_angle)
#
#		if filled:
#			draw_line(origin, end, color, width)
#			draw_colored_polygon([head_right, target, head_left], color)
#		else:
#			draw_line(origin, target , color, width)
#			draw_polyline([head_right, target , head_left], color, width)
#		pass
