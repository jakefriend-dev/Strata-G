extends Node2D

export var path_movegrid: NodePath
var movegrid: GridContainer

export var path_movetooltip: NodePath
var movetooltip: Label

export var path_userpanel: NodePath
var userpanel: PanelContainer

var selcol: int = 0 # 0-based; up to 1
var selrow: int = 0 # 0-based; up to 3

# ---

func _ready():
	movegrid = get_node(path_movegrid)
	movetooltip = get_node(path_movetooltip)
	userpanel = get_node(path_userpanel)
	pass

func load_moves():
	selcol = 0
	selrow = 0
	
	for moveopt in movegrid.get_children():
		moveopt.move = null
		moveopt.actor = batman.curr_actor
		moveopt.nonmove_function = "" # Allow this to be overwritten as necessary LATER
	
	if batman.curr_actor is ActorPlayer:
		var movelist: Array = batman.curr_actor.moveset.keys()
		
		var count: int = 0 # 1-based
		for n in 8:
			count += 1
			var moveopt: HBoxContainer = movegrid.get_node(str("Option",count))
			
			if count == 8: # Custom code for the 8th 'custom function, not a move'
				moveopt.nonmove_function = "check_bag"
				moveopt.nonmove_tooltip = "Check shared party inventory"
				moveopt.nonmove_display_name = "Check Bag"
				break
			
			# Otherwise, try to load a player move (if it has this many)
			if count > movelist.size():
				continue
			
			var index: int = count-1
			var key: String = movelist[index]
			if !batman.curr_actor.moveset.has(key):
				continue
			
			var move: MoveAction = batman.curr_actor.moveset[key]
			# At this point I think we can be SURE it's not null?
			
			moveopt.move = move
			continue
		
		pass
	
	var tooltip_text: String = ""
	for moveopt in movegrid.get_children():
		moveopt.update_against_new_move()
		
		moveopt.currently_highlighted = (moveopt.my_x_col == selcol and moveopt.my_y_row == selrow)
		
		if moveopt.currently_highlighted:
			tooltip_text = moveopt.loaded_tooltip
	
	if movetooltip.text != tooltip_text:
		movetooltip.text = tooltip_text
	pass

func refresh_all():
	var tooltip_text: String = ""
	
	for moveopt in movegrid.get_children():
		moveopt.currently_highlighted = (moveopt.my_x_col == selcol and moveopt.my_y_row == selrow)
		moveopt.full_refresh()
		if moveopt.currently_highlighted:
			tooltip_text = moveopt.loaded_tooltip
	
	if movetooltip.text != tooltip_text:
		movetooltip.text = tooltip_text
	pass

func change_selrow(amount: int):
	selrow += amount
	if selrow > 3:
		selrow = 0
	elif selrow < 0:
		selrow = 3
	
	refresh_all()
	pass

func change_selcol(amount: int):
	selcol += amount
	if selcol > 1:
		selcol = 0
	elif selcol < 0:
		selcol = 1
	
	refresh_all()
	pass

