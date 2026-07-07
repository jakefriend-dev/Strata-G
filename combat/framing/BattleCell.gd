extends Node2D

#var colset: Dictionary = {
#	batman.factions.PLAYER:  ["5e96dd"],
#	batman.factions.ENEMY:   ["bd1f3f"],
#}

#var targetcol: Color = Color("ff9696")

# Un-set; 0 is default
var row: int = -1
var col: int = -1
var coord: Vector2 = Vector2(-1, -1)
var type: int = -1
var faction: int = -1

var max_row: int # Just stored as a shortcut
var threat: YSort

# ---

func _ready():
	batman.connect("update_all_tiletypes", self, "update_tiletype")
	batman.connect("targeted_tiles_updated", self, "update_targeting")
	batman.connect("new_action_preview_data_readied", self, "update_cell_highlighting_temp")
	batman.connect("any_actionstep_initiated", self, "reset_cell_highlighting_temp")
	batman.connect("on_turn_ended_naturally", self, "reset_cell_highlighting_temp")
	batman.connect("on_turn_ended_via_interruption", self, "reset_cell_highlighting_temp")
	
	pass

func detach_battle_threat():
	threat = $BattleThreat
	threat.cell = self
	threat.get_parent().remove_child(threat)
	batman.field.get_node("FieldObjects/Threats").add_child(threat)
#	yield(VisualServer, "frame_post_draw")
	threat.position = global_position + Vector2(-20, -24)
	pass

func update_tiletype(): # Visual only; data is already handled
	var new_type: int =  batman.grid_tiles.get_cellv(coord)
	if new_type != type:
		type = new_type
	
	followup_tiletype()
	pass

func update_targeting():
	var to_visible: bool = batman.targeted_tiles.has(coord)
	if $Threat.visible != to_visible:
		$Threat.visible = to_visible
	if threat.visible != to_visible:
		threat.visible = to_visible
	pass

func reset_cell_highlighting_temp():
	var to_col: Color = Color.white
	$Highlights.modulate = to_col
	for h in $Highlights.get_children():
		if h.visible:
			h.visible = false
	set_depth_tint(max_row)
	pass

func update_cell_highlighting_temp(move: MoveAction):
	var to_col: Color = Color.white
	var hname: String = ""
	var hcol: Color
	
	if move == null:
		set_depth_tint(max_row, Color.gray)
	elif move.unique_cells.has(coord):
		set_depth_tint(max_row) # White if non-darkened
		
		# The highlights!
		var index: int = -1
		for ea in move.ROWS.size():
			index += 1 # 0-based
			var list: Array = move.sets.get_cell(move.COLS.DISPLAY_CELLS, index)
#			if !list.empty(): print("index: ",index,", list: ",list)
			if list.has(coord):
#				print(index)
				hcol = move.colors[index]
				match index:
					0: hname = "Big"	# bad
					1: hname = "Big"	# Good
					2: hname = "Med"	# Neutral
					3: hname = "Pass"	# Pass
					4: hname = "Big"	# Error
					5: hname = "Small"	# Fallback
				break
	else:
		set_depth_tint(max_row, Color.gray)
	
	$Highlights.modulate = to_col
	for h in $Highlights.get_children():
		if h.visible != (hname == h.name):
			h.visible = (hname == h.name)
		if h.visible and h.modulate != hcol:
			h.modulate = hcol
	pass

func set_depth_tint(in_max_row: int, in_color: Color = Color.white):
	
	max_row = in_max_row
	var depth: float = abs(row - max_row)-1.0 # Bottom row is 0
	var shade_delta: float = 0.125
#	var shade_delta: float = 0.075
	var depth_shade: float = 1.0 - (depth * shade_delta)
	var mod: Color = in_color
	mod.r *= depth_shade
	mod.g *= depth_shade
	mod.b *= depth_shade
#	mod.a = 0.0
	self_modulate = mod
	pass

func set_faction():
#	var m: ShaderMaterial = $BaseSprite.material
#	faction = batman.grid_factions.get_cellv(coord)
#
#	m.set_shader_param("replacer_col_2", Color(colset[faction][0]))
	pass

func set_type(to_type: int):
	type = to_type
	followup_tiletype()
	pass

func get_center_gpos() -> Vector2:
	var gpos: Vector2 = global_position
#	gpos += (rect_size/2.0)
	return gpos
	pass

func followup_tiletype():
	if $TypeNum.text != str(type):
		$TypeNum.text = str(type)
	var plaintext: String = batman.tt_as_strings[type]
	if plaintext == "NORMAL": plaintext = ""
	if $TypeStr.text != plaintext:
		$TypeStr.text = plaintext
	if $Pit.visible != (type == batman.tiletypes.PIT):
		$Pit.visible = (type == batman.tiletypes.PIT)
	pass







