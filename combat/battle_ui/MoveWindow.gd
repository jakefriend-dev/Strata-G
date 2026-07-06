extends Node2D

export var path_movegrid: NodePath
var movegrid: GridContainer

export var path_movetooltip: NodePath
var movetooltip: Label

export var path_userpanel: NodePath
var userpanel: PanelContainer

# ---

func _ready():
	movegrid = get_node(path_movegrid)
	movetooltip = get_node(path_movetooltip)
	userpanel = get_node(path_userpanel)
	
	for moveopt in movegrid.get_children():
		moveopt.window = self
	pass

func load_movewindow():
	
	for moveopt in movegrid.get_children():
		moveopt.move = null
		moveopt.actor = batman.curr_actor
		moveopt.nonmove_function = "" # Allow this to be overwritten as necessary LATER
		moveopt.currently_highlighted = (moveopt.my_x_col == batman.moveselcol and moveopt.my_y_row == batman.moveselrow)
	
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
		
		if moveopt.currently_highlighted:
			tooltip_text = moveopt.loaded_tooltip
	
	if movetooltip.text != tooltip_text:
		movetooltip.text = tooltip_text
	pass

func refresh_all():
	var tooltip_text: String = ""
	var tt_col: Color
	
	for moveopt in movegrid.get_children():
		moveopt.currently_highlighted = (moveopt.my_x_col == batman.moveselcol and moveopt.my_y_row == batman.moveselrow)
		moveopt.full_refresh()
		if moveopt.currently_highlighted:
			tooltip_text = moveopt.loaded_tooltip
			tt_col = moveopt.loaded_tt_col
	
	if movetooltip.text != tooltip_text:
		movetooltip.text = tooltip_text
	if movetooltip.get("custom_colors/font_color") != tt_col:
		movetooltip.set("custom_colors/font_color", tt_col)
	pass

func get_loaded_move() -> MoveAction: # Assumes validations have ALREADY happened
	for moveopt in movegrid.get_children():
		if moveopt.currently_highlighted:
			if !moveopt.valid:
				return null
			if moveopt.state == moveopt.s.NOT_MOVE:
				return null
			return moveopt.move
	
	return null
	pass

func attempt_to_run_moveoption_custom_function() -> bool:
	# Does nothing if there's no function to run; the bool is just for SFX to hook in
	for moveopt in movegrid.get_children():
		if moveopt.currently_highlighted:
			if !moveopt.valid:
				return false
			if moveopt.state == moveopt.s.NOT_MOVE:
				var funcname: String = str("CUSTOM_",moveopt.nonmove_function)
				if has_method(funcname): # Always should, but doublecheck
					call(funcname)
					return true
				return false
	
	return false
	pass


func CUSTOM_check_bag():
	print("Testing CUSTOM_check_bag()! Wow it worked!!")
	pass

