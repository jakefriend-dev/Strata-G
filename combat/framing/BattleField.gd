extends Node2D

export var path_board: NodePath
export var path_actors: NodePath
export var path_vfx: NodePath
export var path_misc: NodePath
export var path_debuglog_par: NodePath
export var path_turndisplay_par: NodePath
#export var path_actionsel_par: NodePath
export var path_movewindow: NodePath
var board: Node2D
var actors: YSort
var vfx: YSort
var misc: YSort
var debuglog_par: VBoxContainer
var turndisplay_par: VBoxContainer
#var actionsel_par: VBoxContainer
var movewindow: Node2D
var tq_window: Node2D
var tt_par: Node2D

export var path_major_text: NodePath
var major_text: Node2D
#export var path_curr_turntaker: NodePath
#var curr_turntaker: Node2D

var board_offset: Vector2

const CELL_SIZE: Vector2 = Vector2(64, 48)
var board_size: Vector2

# ---

func _ready():
	board = get_node(path_board)
	actors = get_node(path_actors)
	vfx = get_node(path_vfx)
	misc = get_node(path_misc)
	debuglog_par = get_node(path_debuglog_par)
	turndisplay_par = get_node(path_turndisplay_par)
#	actionsel_par = get_node(path_actionsel_par)
	movewindow = get_node(path_movewindow)
	major_text = get_node(path_major_text)
#	curr_turntaker = get_node(path_curr_turntaker)
	
	batman.field = self
	batman.drawer = $FieldFore/Drawer
	batman.actors = actors
	batman.board = board
	
	update_debuglog()
	
	$BG/TestOverlay.visible = false
	
	batman.connect("action_log_updated", self, "update_debuglog")
	batman.connect("set_up_board", self, "set_up_board")
	batman.connect("populate_actors", self, "populate_actors")
	
	hide_major_text()
	pass

func set_up_board():
	
	# Clear the board
	while board.get_child_count() > 0:
		var c = board.get_child(0)
		board.remove_child(c)
		c.queue_free()
	
	board_size = batman.battle_details["board_size"]
	var w: int = batman.battle_details["board_size"].x #Always even
	var h: int = batman.battle_details["board_size"].y
	
	var first_enemy_col: int = (w/2)+1
	
	for y in h:
		for x in w:
			var cell: Node2D = loader.res_battlecell.instance()
			cell.set("field", self)
			cell.set("position", batman.grid_gpos.get_cell(x+1, y+1))
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
			
			if cell.col == first_enemy_col:
				var flo: YSort = loader.res_factionline.instance()
				flo.set("coord", coord)
				flo.set("position", cell.position)
				$FieldObjects/Misc/FactionLines.add_child(flo)
	pass

func populate_actors():
	
	# Clear any historical actors
	while actors.get_child_count() > 0:
		var c = actors.get_child(0)
		actors.remove_child(c)
		c.queue_free()
	
	# Time to populate the board!
	var actorset: Array = batman.grid_actors.get_dataset_with_coords()
	
	var og_path: String = "res://combat/actors/"
	
	for set in actorset: if set is Array:
		var actor_scenename: String = set[0]
		var coord: Vector2 = set[1]
		var gpos: Vector2 = batman.grid_gpos.get_cellv(coord)
		
		var path: String = og_path
		var midpath: String
		if loader.names_players.has(actor_scenename):
			midpath = "player_chars"
		elif loader.names_objects.has(actor_scenename):
			midpath = "objects"
		else:
			midpath = "enemies"
		path += midpath
		path += "/"
		
		var thispath: String = path + actor_scenename + ".tscn"
		if !utils.does_file_exist(thispath):
			print("BATTLEFIELD: Error, path ",thispath," does not exist! Skipping + erasing from grid")
			batman.grid_actors.set_cellv(coord, null)
			continue
		
		var res_actor = load(thispath)
		var actor: Node2D = res_actor.instance()
		
		actor.set("position", gpos)
		if actor.get("ofc_name") == "--":
			actor.set("ofc_name", actor.get("name"))
		if midpath == "player_chars":
			actor.set("faction", batman.factions.PLAYER)
		elif midpath == "enemies":
			actor.set("faction", batman.factions.ENEMY)
		actor.set("coord", coord)
		
		actors.add_child(actor)
		
		batman.living_actors.append(actor)
		batman.grid_actors.set_cellv(coord, actor) # Overwrites the "text" with the actual object
	
	pass

func update_targeting():
	for actor in actors.get_children():
		actor.update_outline()
		actor.update_facing()
	pass

func update_debuglog():
	var newtext: String = ""
	var oldtext: String = ""
	
	var index: int = 0
	var dupe_log: Array = batman.actionlog.duplicate()
	for n in 8:
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

# ---

var mt_time: float = 0.125

func show_major_text(big_text: String, lesser_text: String, instant: bool = false):
	utils.tween.remove(major_text, "modulate:a")
	if !major_text.visible:
		major_text.visible = true
	
	if lesser_text == "":
		major_text.position.y = 0
		major_text.get_node("BigLabel").text = big_text
		major_text.get_node("SmallLabel").text = ""
	else:
		major_text.position.y = 32
#		major_text.get_node("SmallLabel").text = str("\"",lesser_text,"\"")
		major_text.get_node("BigLabel").text = str("“",big_text,"”")
		major_text.get_node("SmallLabel").text = lesser_text
#		major_text.get_node("SmallLabel").text = str("“",lesser_text,"”")
	
	if instant:
#		major_text.visible = true
		major_text.modulate.a = 1.0
	else:
		utils.tween.interpolate_property(major_text, "modulate:a", null, 1.0, mt_time, Tween.TRANS_CIRC, Tween.EASE_OUT)
		utils.tween.start()
	
	pass

func hide_major_text(instant: bool = false):
	utils.tween.remove(major_text, "modulate:a")
	if instant:
#		major_text.visible = false
		major_text.modulate.a = 0.0
	else:
		utils.tween.interpolate_property(major_text, "modulate:a", null, 0.0, mt_time, Tween.TRANS_CIRC, Tween.EASE_OUT)
		utils.tween.start()
	pass

# -

var frontline_move_time: float = 1.25
func move_frontline(toward_enemy: bool):
	if toward_enemy:
		if batman.enemy_frontline_col == board_size.x:
			print("BATTLEFIELD: Attempted to move enemy frontline beyond its final column!")
			return
		batman.enemy_frontline_col += 1
		batman.player_frontline_col += 1
		
	else:
		if batman.player_frontline_col == 1:
			print("BATTLEFIELD: Attempted to move player frontline beyond its final column!")
			return
		batman.enemy_frontline_col -= 1
		batman.player_frontline_col -= 1
	
	var faction_dataset: Array = batman.grid_factions.get_dataset_with_coords(true)
	for set in faction_dataset:
		var coord: Vector2 = set[1]
		if coord.x <= batman.player_frontline_col:
			batman.grid_factions.set_cellv(coord, batman.factions.PLAYER)
		else:
			batman.grid_factions.set_cellv(coord, batman.factions.ENEMY)
	
	for flo in $FieldObjects/Misc/FactionLines.get_children():
		if toward_enemy:
			flo.coord.x = flo.coord.x + 1
		else:
			flo.coord.x = flo.coord.x - 1
		utils.tween.interpolate_property(flo, "position", null, batman.grid_gpos.get_cellv(flo.coord), frontline_move_time, Tween.TRANS_CIRC, Tween.EASE_OUT)
	utils.tween.start()
	pass





