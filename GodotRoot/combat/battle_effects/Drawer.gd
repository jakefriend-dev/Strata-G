extends Node2D

var APD: ActionPreviewData # We never WIPE from this script though, since it might be linked
var drawing: bool = false

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
	draw_all_arrows()
	pass

func draw_all_arrows():
#	var arrowsets: Array = [] # We want to add a series of [Rect2, Color] sets!
	
	# First, GATHER all the data!
	var y: int = -1
	for row in APD.ROWS.size():
		y += 1 # 0-based
		
		var arrow_array: Array = APD.sets.get_cell(APD.COLS.ARROW_ARRAY, y)
		var col: Color = APD.colors[y]
		
		for arrow_rect in arrow_array: if arrow_rect is Rect2:
			var start: Vector2 = arrow_rect.position
			var end: Vector2 = arrow_rect.size
			draw_arrow(start, end, col, y)
	pass

func draw_arrow(
	start: Vector2,
	end: Vector2,
	color: Color,
	y: int,
#	width: float = -1,
	filled: bool = false,
	head_length: float = 0.25,
	head_angle: float = PI / 4.0
	):
		var width: float = 4.0
		if y == APD.ROWS.PASS:
			width = 2.0
		
		var dir: Vector2 = end - start
		dir = dir.normalized()
		var cell_len: Vector2 = dir * batman.field.CELL_SIZE
		var adjust: float = 0.25
		
		start = start + (cell_len * adjust)
		if y == APD.ROWS.PASS:
			end = end + (cell_len * adjust)
		elif y == APD.ROWS.ERROR:
			end = end - (cell_len * adjust)
		
		draw_line(start, end, color, width)
		
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
