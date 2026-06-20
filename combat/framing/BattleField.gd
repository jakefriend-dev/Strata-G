extends Node2D

export var path_board: NodePath
export var path_actors: NodePath
export var path_effects: NodePath
export var path_misc: NodePath
export var path_debuglog_par: NodePath
export var path_turndisplay_par: NodePath
export var path_actionsel_par: NodePath
var board: GridContainer
var actors: YSort
var effects: YSort
var misc: YSort
var debuglog_par: VBoxContainer
var turndisplay_par: VBoxContainer
var actionsel_par: VBoxContainer

var board_offset: Vector2

const CELL_SIZE: Vector2 = Vector2(64, 48)

# ---

func _ready():
	board = get_node(path_board)
	actors = get_node(path_actors)
	effects = get_node(path_effects)
	misc = get_node(path_misc)
	debuglog_par = get_node(path_debuglog_par)
	turndisplay_par = get_node(path_turndisplay_par)
	actionsel_par = get_node(path_actionsel_par)
	
	batman.field = self
	batman.drawer = $Drawer
	batman.actors = actors
	batman.board = board
	
	update_debuglog()
	update_turn_display()
	
	$BoardOwner/MC.rect_size = Vector2(
		ProjectSettings.get_setting("display/window/size/width"),
		ProjectSettings.get_setting("display/window/size/height"))
	
	batman.connect("action_log_updated", self, "update_debuglog")
	batman.connect("set_up_board", self, "set_up_board")
	batman.connect("populate_gpos_data", self, "populate_gpos_data")
	batman.connect("populate_actors", self, "populate_actors")
	batman.connect("action_option_view_changed", self, "update_action_selector")
	pass

func set_up_board():
	
	# Clear the board
	while board.get_child_count() > 0:
		var c = board.get_child(0)
		board.remove_child(c)
		c.queue_free()
	
	var w: int = batman.battle_details["board_size"].x #Always even
	var h: int = batman.battle_details["board_size"].y
	board.columns = w
	
	for y in h:
		for x in w:
			var cell: NinePatchRect = loader.res_battlecell.instance()
#			cell.set("field", self)
			board.add_child(cell)
			
			var coord: Vector2 = Vector2(x+1, y+1)
			cell.coord = coord
			cell.col = coord.x
			cell.row = coord.y
			
			cell.set_faction()
			
			cell.set_depth_tint(h)
			
			cell.detach_battle_threat()
			
			var type: int = batman.grid_tiles.get_cellv(coord)
			cell.set_type(type)
	pass

func populate_gpos_data():# This happens AFTER yielding a draw frame, so it's reliable
	
	board_offset = board.rect_global_position
	
	var w: int = batman.battle_details["board_size"][0] # Always even
	var _h: int = batman.battle_details["board_size"][1]
	
	var xcoord: int = 1
	var ycoord: int = 1
	for cell in board.get_children():
		batman.grid_gpos.set_cell(xcoord, ycoord, cell.get_center_gpos())
		xcoord += 1
		if xcoord > w:
			xcoord = 1 # Back to the leftmost column, onebased
			ycoord += 1
	
	pass

func populate_actors():
	# Clear any historical actors
	while actors.get_child_count() > 0:
		var c = actors.get_child(0)
		actors.remove_child(c)
		c.queue_free()
	
	# Time to populate the board!
	var actorset: Array = batman.grid_actors.get_dataset_with_coords()
	
	var path: String = "res://combat/actors/"
	
	for set in actorset: if set is Array:
		var actor_scenename: String = set[0]
		var coord: Vector2 = set[1]
		var gpos: Vector2 = batman.grid_gpos.get_cellv(coord)
		
		var thispath: String = path + actor_scenename + ".tscn"
		if !utils.does_file_exist(thispath):
			print("BATTLEFIELD: Error, path ",thispath," does not exist! Skipping + erasing from grid")
			batman.grid_actors.set_cellv(coord, null)
			continue
		
		var res_actor = load(thispath)
		var actor: Node2D = res_actor.instance()
		
		actor.set("position", gpos)
#		actor.set("name", actorname)
		if actor.get("ofc_name") == "--":
			actor.set("ofc_name", actor.get("name"))
		if ["P1", "P2", "P3"].has(actor_scenename):
			actor.set("faction", batman.factions.PLAYER)
		else:
			actor.set("faction", batman.factions.ENEMY)
		actor.set("coord", coord)
		
		actors.add_child(actor)
		
		batman.living_actors.append(actor)
		batman.grid_actors.set_cellv(coord, actor) # Overwrites the "text" with the actual object
	
	# Manual step just to get test gameplay going
#	batman.pc_actors.append(actors.get_node("P1"))
#	batman.pc_actors.append(actors.get_node("P2"))
#	batman.pc_actors.append(actors.get_node("P3"))
#	batman.curr_actor = batman.pc_actors[0]
	pass

func update_targeting():
	for actor in actors.get_children():
		actor.update_outline()
	pass

func update_debuglog():
	var newtext: String = ""
	var oldtext: String = ""
	
	var index: int = 0
	var dupe_log: Array = batman.actionlog.duplicate()
	for n in 5:
		# This is the number of lines we want to display to the player; separate from the number of lines being logged at all
		
		# Prevent us from checking 'past' the line in question
		var needsize: int = index + 1
		if batman.actionlog.size() < needsize:
			break
		
		if index == 0:
			newtext = dupe_log[index]
		elif index == 1:
			oldtext = dupe_log[index]
		else:
			oldtext = str(dupe_log[index] + "\n" + oldtext)
		
		index += 1
		pass
	
	var labelnew: Label = debuglog_par.get_node("LabelNew")
	if labelnew.text != newtext:
		labelnew.text = newtext
	
	var labelold: Label = debuglog_par.get_node("LabelOld")
	if labelold.text != oldtext:
		labelold.text = oldtext
	
	if labelold.visible != (labelold.text != ""):
		labelold.visible = (labelold.text != "")
	pass

func update_turn_display():
	var currtext: String = ""
	var nexttext: String = ""
	
	if batman.combatstate == batman.C_OOC:
		push_turn_display_changes(currtext, nexttext)
		return
	
	# Once we're actually IN combat, we can do the real code!
	
	var prev: Array = []
	var next: Array = []
	
	for turndata in batman.turnqueue: if turndata is Dictionary:
		var actor: Actor = turndata["actor"]
		var n: String = actor.get_multifactored_actor_name()
		if actor.faction == batman.factions.PLAYER:
			n += " *"
		else:
			n += "  "
		
		if turndata["turnpos"] == batman.turncount:
			currtext = n
			continue
		if turndata["turnpos"] < batman.turncount:
			prev.append(n)
			continue
		next.append(n)
		pass
	
#	print("prev: ",prev)
#	print("curr: ",currtext)
#	print("next: ",next)
	
	var first: bool = true
	for n in next:
		if first:
			first = false
		else:
			nexttext += "\n"
		nexttext += n
	for n in prev:
		if first:
			first = false
		else:
			nexttext += "\n"
		nexttext += n
	
	push_turn_display_changes(currtext, nexttext)
	pass

func push_turn_display_changes(currtext: String, nexttext: String):
	var labelcurr: Label = turndisplay_par.get_node("Curr")
	var labelnext: Label = turndisplay_par.get_node("Next")
	
	if labelcurr.text != currtext:
		labelcurr.text = currtext
	if labelnext.text != nexttext:
		labelnext.text = nexttext
	if labelcurr.visible != (labelcurr.text != ""):
		labelcurr.visible = (labelcurr.text != "")
	if labelnext.visible != (labelnext.text != ""):
		labelnext.visible = (labelnext.text != "")
	pass

# -

func update_action_selector(_tf: bool):
	if not batman.curr_actor is ActorPlayer:
		push_action_selector_changes()
		return
	
	var pre_list: Array = []
	var current: String = ""
	var post_list: Array = []
	
	var index: int = -1
	for key in batman.loaded_moveset:
		index += 1 # Zero-based
		var movename: String = batman.loaded_moveset[index]
		var move: MoveAction = batman.curr_actor.moveset[movename]
		
		var formal: String = move.display_name
		if index == batman.loaded_m_index:
			current = str("* ",formal)
			continue
		
		if current == "":
			pre_list.append(formal)
		else:
			post_list.append(formal)
		
		pass
	
	# Now we should have all our strings!
	var p: String = ""
	var n: String = ""
	
	for line in pre_list:
		p += "  "
		p += line
		if line != pre_list.back():
			p += "\n"
	
	for line in post_list:
		n += "  "
		n += line
		if line != post_list.back():
			n += "\n"
	
	push_action_selector_changes(p, current, n)
	pass

func push_action_selector_changes(p: String = "", c: String = "", n: String = ""):
	var prev: Label = actionsel_par.get_node("Prev")
	var curr: Label = actionsel_par.get_node("Curr")
	var next: Label = actionsel_par.get_node("Next")
	
	if prev.text != p: prev.text = p
	if curr.text != c: curr.text = c
	if next.text != n: next.text = n
	
	if prev.visible != (p != ""):
		prev.visible = (p != "")
	if curr.visible != (c != ""):
		curr.visible = (c != "")
	if next.visible != (n != ""):
		next.visible = (n != "")
	pass

func actorpos_to_tilecoord(actorpos: Vector2) -> Vector2:
	actorpos -= board_offset # Adjust it to board-local coordinates
	
	var tpos: Vector2 = actorpos / CELL_SIZE
	tpos = tpos.floor()
	tpos += Vector2(1, 1) # Always one-based!
	
	return tpos
	pass







