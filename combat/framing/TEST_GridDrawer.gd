extends Node2D

var hcells: int = 6 # Never odd
var vcells: int = 3

export var height: float = 240.0
export var bot_width: float = 622.0 # BOTTOM side width
export var top_width: float = 502.0 # TOP side width
export var row_imbalance: float = 0.0 # Must be a positive value

var bottom_offset: float = 6.0
var left_edge_warp: float = 0.0
var right_edge_warp: float = 0.0

var lines: Array = [] # Array of sub-arrays, which are purely comprised of start/end coords

# ---

#func _ready():
#	force_redraw()
#	pass
#
#func change_hcells(inc: bool):
#	if inc:
#		hcells += 2
#	elif hcells >= 4:
#		hcells -= 2
#	force_redraw()
#	pass
#
#func change_vcells(inc: bool):
#	if inc:
#		vcells += 1
#	elif vcells > 1:
#		vcells -= 1
#	force_redraw()
#	pass
#
#func change_height(inc: bool):
#	if inc:
#		height += 1
#	elif height > 100:
#		height -= 1
#	force_redraw()
#	pass
#
#func change_bot_width(inc: bool):
#	if inc:
#		bot_width += 2
#	elif bot_width > 150:
#		bot_width -= 2
#	force_redraw()
#	pass
#
#func change_top_width(inc: bool):
#	if inc:
#		top_width += 2
#	elif top_width > 150:
#		top_width -= 2
#	force_redraw()
#	pass
#
#func change_row_imbalance(inc: bool):
#	if inc:
#		row_imbalance += 2
#	elif row_imbalance > 1:
#		row_imbalance -= 2
#	force_redraw()
#	pass
#
#func change_right_edge_warp(inc: bool):
#	if inc:
#		right_edge_warp += 2
#	elif right_edge_warp > 2:
#		right_edge_warp -= 2
#	force_redraw()
#	pass
#
#func change_left_edge_warp(inc: bool):
#	if inc:
#		left_edge_warp += 2
#	elif left_edge_warp > 2:
#		left_edge_warp -= 2
#	force_redraw()
#	pass
#
#func _process(_delta):
#	if Input.is_action_pressed("dev_0"): change_right_edge_warp(Input.is_action_pressed("dev_modifier"))
#	if Input.is_action_pressed("dev_9"): change_left_edge_warp(Input.is_action_pressed("dev_modifier"))
#	if Input.is_action_pressed("dev_8"): change_top_width(Input.is_action_pressed("dev_modifier"))
#	if Input.is_action_just_pressed("dev_7"): change_vcells(!Input.is_action_pressed("dev_modifier"))
##	if Input.is_action_pressed("dev_6"): change_top_width(Input.is_action_pressed("dev_modifier"))
#	if Input.is_action_pressed("dev_5"): change_row_imbalance(!Input.is_action_pressed("dev_modifier"))
#	if Input.is_action_pressed("dev_4"): change_height(Input.is_action_pressed("dev_modifier"))
##	if Input.is_action_pressed("dev_3"): change_top_width(Input.is_action_pressed("dev_modifier"))
#	if Input.is_action_pressed("dev_2"): change_bot_width(Input.is_action_pressed("dev_modifier"))
#	if Input.is_action_just_pressed("dev_1"): change_hcells(!Input.is_action_pressed("dev_modifier"))
#	pass
#
#func force_redraw():
#	lines.clear()
#
#	# Create our simulated grid, then populate our arrows!
#	var WINDOW: Vector2
#	WINDOW.x = ProjectSettings.get("display/window/size/width")
#	WINDOW.y = ProjectSettings.get("display/window/size/height")
#	var CENTER: float = WINDOW.x/2.0
#	var BOTTOM: float = WINDOW.y - bottom_offset
#	var TOP: float = BOTTOM - height
#
#	# Corner positions
#	var CSW: Vector2 = Vector2(CENTER - (bot_width/2.0), BOTTOM - left_edge_warp)
#	var CSE: Vector2 = Vector2(CENTER + (bot_width/2.0), BOTTOM - right_edge_warp)
#	var CNW: Vector2 = Vector2(CENTER - (top_width/2.0), TOP - left_edge_warp)
#	var CNE: Vector2 = Vector2(CENTER + (top_width/2.0), TOP - right_edge_warp)
#
#	# Base outline
#	add_line(CSW, CSE)
#	add_line(CSW, CNW)
#	add_line(CNE, CSE)
#	add_line(CNE, CNW)
#
#	# Quick refs for later
#	var left_line: Array = [CSW, CNW]
#	var right_line: Array = [CSE, CNE]
#
#	# Working out the row heights... remember there's 1 less than vcells because of top/bottom edges!
#	if vcells > 1:
#		var hlines_qty: int = (vcells)
#		var avg_rowheight: float = height/float(vcells)
##		var rowheights: Array = []
##		var rolling_offset: float = 0
#		var rolling_offset: float = (hlines_qty-1) * (row_imbalance/2)
#		var last_height: float = 0
##		print("---")
#		var count: int = 1
#		for n in hlines_qty:
#			if count == vcells: break
#			var thisheight: float = last_height + avg_rowheight + rolling_offset
##			rowheights.append(thisheight)
##			print("rolling_offset: ",rolling_offset," and row_imbalance: ",row_imbalance)
#			rolling_offset -= (row_imbalance)
##			wouldbe_height += avg_rowheight
#			last_height = thisheight
##			print("thisheight ",thisheight)
#
#			var y: float = round(BOTTOM - thisheight)
#			var leftx: float = Geometry.line_intersects_line_2d(
#				left_line[0], left_line[1] - left_line[0],
#				Vector2(0, y), Vector2(bot_width, 0)
#				).x
#			var rightx: float = Geometry.line_intersects_line_2d(
#				right_line[0], right_line[1] - right_line[0],
#				Vector2(0, y), Vector2(bot_width, 0)
#				).x
#
#			add_line(
#				Vector2(leftx, y),
#				Vector2(rightx, y)
#				)
#			count += 1
#
#	if hcells > 1: # Should always be true, think it's min 2?
#		var vlines_qty: int = hcells - 1
#		var avg_top_colwidth: float = top_width/float(hcells)
#		var avg_bot_colwidth: float = bot_width/float(hcells)
#		var top_x: float
#		var bot_x: float
#		for n in vlines_qty:
#			top_x += avg_top_colwidth
#			bot_x += avg_bot_colwidth
#			add_line(
#				Vector2(top_x + CNW.x, TOP),
#				Vector2(bot_x + CSW.x, BOTTOM)
#				)
#
#	update()
#	pass
#
#func add_line(start: Vector2, end: Vector2):
#	lines.append([start, end])
#	pass
#
#func _draw():
#	for line in lines: if line is Array: if line.size() == 2:
#		var start: Vector2 = line[0]
#		var end:   Vector2 = line[1]
#		draw_line(start, end, Color.black, 4, false)
#
#	for line in lines: if line is Array: if line.size() == 2:
#		var start: Vector2 = line[0]
#		var end:   Vector2 = line[1]
#		draw_line(start, end, Color.white, 2, false)
#
#	pass
