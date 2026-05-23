extends Node2D

export var path_board: NodePath
var board: GridContainer

enum {} # put hover, fire, etc states here - one value per current state AND default of that state

# ---

func _ready():
	board = get_node(path_board)
	turn.field = self
	turn.actors = $Actors
	turn.board = board
	act.field = self
	act.actors = $Actors
	act.board = board
	
	$Control/MC.rect_size = Vector2(
		ProjectSettings.get_setting("display/window/size/width"),
		ProjectSettings.get_setting("display/window/size/height"))
	
	turn.connect("set_up_board", self, "set_up_board")
	turn.connect("populate_gpos_data", self, "populate_gpos_data")
	turn.connect("populate_actors", self, "populate_actors")
	pass

func set_up_board():
	
	# Clear the board
	while board.get_child_count() > 0:
		var c = board.get_child(0)
		board.remove_child(c)
		c.queue_free()
	
	var w: int = turn.battle_details["board_size"][0] # Always even
	var h: int = turn.battle_details["board_size"][1]
	board.columns = w
	
	for y in h:
		for x in w:
			var cell: NinePatchRect = loader.res_battlecell.instance()
			board.add_child(cell)
			
			cell.col = x
			cell.row = y
			var coord: Vector2 = Vector2(x, y)
			cell.coord = coord
			
			cell.set_faction()
			
			cell.set_depth_tint(h)
			
			var type: int = turn.grid_tiles.get_cellv(coord)
			cell.set_type(type)
	pass

func populate_gpos_data():
	var w: int = turn.battle_details["board_size"][0] # Always even
	var _h: int = turn.battle_details["board_size"][1]
	
	var xcoord: int = 0
	var ycoord: int = 0
	for cell in board.get_children():
		turn.grid_gpos.set_cell(xcoord, ycoord, cell.get_center_gpos())
		xcoord += 1
		if xcoord >= w:
			xcoord = 0
			ycoord += 1
	
	pass

func populate_actors():
	# Clear any historical actors
	while $Actors.get_child_count() > 0:
		var c = $Actors.get_child(0)
		$Actors.remove_child(c)
		c.queue_free()
	
	# Time to populate the board!
	var actorset: Array = turn.grid_actors.get_dataset_with_coords()
#	var res_actor = load("res://src/prefabs/_ActorTEMPLATE.tscn")
#	print(actorset)
	
	var path: String = "res://src/actors/"
	
	for set in actorset: if set is Array:
		var actorname: String = set[0]
		var coord: Vector2 = set[1]
		var gpos: Vector2 = turn.grid_gpos.get_cellv(coord)
		
		var thispath: String = path + actorname + ".tscn"
		if !utils.does_file_exist(thispath):
			print("BATTLEFIELD: Error, path ",thispath," does not exist! Skipping + erasing from grid")
			turn.grid_actors.set_cellv(coord, null)
			continue
		
		var res_actor = load(thispath)
		var actor: Node2D = res_actor.instance()
		
		actor.set("position", gpos)
		actor.set("name", actorname)
		if actor.get("ofc_name") == "--":
			actor.set("ofc_name", actorname)
		if ["P1", "P2", "P3"].has(actorname):
			actor.set("faction", turn.factions.PLAYER)
		else:
			actor.set("faction", turn.factions.ENEMY)
		actor.set("coord", coord)
		
		$Actors.add_child(actor)
		
		turn.grid_actors.set_cellv(coord, actor) # Overwrites the "text" with the actual object
	
	# Manual step just to get test gameplay going
	turn.pc_actors.append($Actors.get_node("P1"))
	turn.pc_actors.append($Actors.get_node("P2"))
	turn.pc_actors.append($Actors.get_node("P3"))
	turn.curr_actor = turn.pc_actors[0]
	pass

func update_targeting():
	for actor in $Actors.get_children():
		actor.update_outline()
	pass







