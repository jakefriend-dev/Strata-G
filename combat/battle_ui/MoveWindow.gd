extends Node2D

export var path_movegrid: NodePath
var movegrid: GridContainer

export var path_tooltip_par: NodePath
var tooltip_par: VBoxContainer

export var path_turntaker: NodePath
var turntaker: VBoxContainer

export var path_apb: NodePath
var apb: VBoxContainer

#                             Valid           Invalid
var desccols: Array = [Color("ffdba5"), Color("fdbaf2")]
var warncols: Array = [Color("9cd8fc"), Color("ff94b3")]

# ---

func _ready():
	movegrid = get_node(path_movegrid)
	tooltip_par = get_node(path_tooltip_par)
	turntaker = get_node(path_turntaker)
	apb = get_node(path_apb)
	
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
	
	var tt_desc_text: String = ""
	var tt_warn_text: String = ""
	for moveopt in movegrid.get_children():
		moveopt.update_against_new_move()
		
		if moveopt.currently_highlighted:
			tt_warn_text = moveopt.loaded_tt_warn_text
			tt_desc_text = moveopt.loaded_tt_desc_text
	
	if tooltip_par.get_node("DescTooltip").text != tt_desc_text:
		tooltip_par.get_node("DescTooltip").text = tt_desc_text
	if tooltip_par.get_node("WarnTooltip").text != tt_warn_text:
		tooltip_par.get_node("WarnTooltip").text = tt_warn_text
	pass

func refresh_all():
	var tt_desc_text: String = ""
	var tt_warn_text: String = ""
	var tt_desc_col: Color = desccols[1]
	var tt_warn_col: Color = warncols[1]
	
	for moveopt in movegrid.get_children():
		moveopt.currently_highlighted = (moveopt.my_x_col == batman.moveselcol and moveopt.my_y_row == batman.moveselrow)
		moveopt.full_refresh()
		if moveopt.currently_highlighted:
			tt_warn_text = moveopt.loaded_tt_warn_text
			tt_desc_text = moveopt.loaded_tt_desc_text
			if moveopt.tooltips_are_valid:
				tt_desc_col = desccols[0]
				tt_warn_col = warncols[0]
	
	if tooltip_par.get_node("DescTooltip").text != tt_desc_text:
		tooltip_par.get_node("DescTooltip").text = tt_desc_text
	if tooltip_par.get_node("WarnTooltip").text != tt_warn_text:
		tooltip_par.get_node("WarnTooltip").text = tt_warn_text
	
	if tooltip_par.get_node("DescTooltip").get("custom_colors/font_color") != tt_desc_col:
		tooltip_par.get_node("DescTooltip").set("custom_colors/font_color", tt_desc_col)
	if tooltip_par.get_node("WarnTooltip").get("custom_colors/font_color") != tt_warn_col:
		tooltip_par.get_node("WarnTooltip").set("custom_colors/font_color", tt_warn_col)
	pass

func update_error_text_only():
	var error_text: String = ""
	var is_moveopt_available: bool = false
	for moveopt in movegrid.get_children():
		if moveopt.currently_highlighted:
			is_moveopt_available = (moveopt.state == moveopt.s.AVAILABLE)
			if moveopt.move != null:
				error_text = moveopt.move.error_text
				break
	
	if error_text == "": return
	
	var wtt: Label = tooltip_par.get_node("WarnTooltip")
	# This is where if there is a 'base' error (like on a cooldown) the existing texts would be preserved - but we don't want to do that if the move is ultimately available!
	if wtt.text != "" and !is_moveopt_available: return
#	if wtt.text != "": return
	
	if wtt.text != error_text:
		wtt.text = error_text
	var tt_warn_col: Color = warncols[1]
	if wtt.get("custom_colors/font_color") != tt_warn_col:
		wtt.set("custom_colors/font_color", tt_warn_col)
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

func update_ap():
	if !utils.actorpass(batman.curr_actor):
		apb.modulate.a = 0.0
		return
	apb.modulate.a = 1.0
	
	var curr: int = batman.curr_actor.action_points
	var total: int = batman.curr_actor.base_action_points
	apb.get_node("Text/Curr").text = str(curr)
	apb.get_node("Text/Total").text = str(total)
	
	var count: int = 0 # 1-based
	for pip in apb.get_node("Pips").get_children():
		if pip.name == "MinPanel": continue
		count += 1
		
		var to_vis: bool = (curr >= count or total >= count)
		if pip.visible != to_vis:
			pip.visible = to_vis
		
		var frame: int = 2 # "Greyed out" by default
		if curr >= count:
			if count > total:
				frame = 1
			else:
				frame = 0
		pip.get_node("Sprite").frame = frame
		
		var crack_frame: int = 0
		if curr == count and curr > 0:
			crack_frame = batman.curr_actor.action_cracking
		pip.get_node("Sprite/Cracking").frame = crack_frame
		
	pass

# ---

func CUSTOM_check_bag():
	print("Testing CUSTOM_check_bag()! Wow it worked!!")
	pass

