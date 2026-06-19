extends Node2D

var hcells: int = 6 # Never odd
var vcells: int = 3

export var height: float = 240.0
export var bot_width: float = 622.0 # BOTTOM side width
export var top_width: float = 502.0 # TOP side width
export var row_imbalance: float = 0.0 # Must be a positive value

var bottom_offset: float = 6.0

var lines: Array = [] # Array of sub-arrays, which are purely comprised of start/end coords

# ---

func _ready():
	force_redraw()
	pass

func change_hcells(inc: bool):
	if inc:
		hcells += 2
	elif hcells > 2:
		hcells -= 2
	force_redraw()
	pass

func change_vcells(inc: bool):
	if inc:
		vcells += 1
	elif vcells > 1:
		vcells -= 1
	force_redraw()
	pass

func change_height(inc: bool):
	if inc:
		height += 1
	elif height > 100:
		height -= 1
	force_redraw()
	pass

func change_bot_width(inc: bool):
	if inc:
		bot_width += 1
	elif bot_width > 150:
		bot_width -= 1
	force_redraw()
	pass

func change_top_width(inc: bool):
	if inc:
		top_width += 1
	elif top_width > 150:
		top_width -= 1
	force_redraw()
	pass

func change_row_imbalance(inc: bool):
	if inc:
		row_imbalance += 1
	elif row_imbalance > 1:
		row_imbalance -= 1
	force_redraw()
	pass

func force_redraw():
	# Create our simulated grid, then populate our arrows!
	var WINDOW: Vector2
	WINDOW.x = ProjectSettings.get("display/window/size/width")
	WINDOW.y = ProjectSettings.get("display/window/size/height")
	var CENTER: float = WINDOW.x/2.0
	
	# Corner positions
	var CSW: Vector2 = Vector2(CENTER - (bot_width/2.0), WINDOW.y - bottom_offset)
	var CSE: Vector2 = Vector2(CENTER + (bot_width/2.0), WINDOW.y - bottom_offset)
	var CNW: Vector2 = Vector2(CENTER - (top_width/2.0), CSW.y - height)
	var CNE: Vector2 = Vector2(CENTER + (top_width/2.0), CSE.y - height)
	
	# Base outline
	add_line(CSW, CSE)
	add_line(CSW, CNW)
	add_line(CNE, CSE)
	add_line(CNE, CNW)
	
	update()
	pass

func add_line(start: Vector2, end: Vector2):
	lines.append([start, end])
	pass

func _draw():
	for line in lines: if line is Array: if line.size() == 2:
		var start: Vector2 = line[0]
		var end:   Vector2 = line[1]
		draw_line(start, end, Color.black, 4, false)
	
	for line in lines: if line is Array: if line.size() == 2:
		var start: Vector2 = line[0]
		var end:   Vector2 = line[1]
		draw_line(start, end, Color.white, 2, false)
	
	pass
