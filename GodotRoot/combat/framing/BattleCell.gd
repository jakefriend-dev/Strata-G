extends NinePatchRect

var colset: Dictionary = {
	batman.factions.PLAYER:  ["5392df"],
	batman.factions.ENEMY:   ["df538e"],
}

# Un-set; 0 is default
var row: int = -1
var col: int = -1
var coord: Vector2 = Vector2(-1, -1)
var type: int = -1
var faction: int = -1

# ---

func _ready():
	batman.connect("update_all_tiletypes", self, "update_tiletype")
#	$Crack.rect_size = rect_size
#	$Pit.rect_size = rect_size
	pass

func update_tiletype(): # Visual only; data is already handled
	var new_type: int =  batman.grid_tiles.get_cellv(coord)
	if new_type != type:
		type = new_type
	
	followup_tiletype()
	pass

func set_depth_tint(max_row: int):
	var depth: float = abs(row - max_row)-1.0 # Bottom row is 0
	var shade_delta: float = 0.075
	var depth_shade: float = 1.0 - (depth * shade_delta)
	var mod: Color = Color.white
	mod.r = depth_shade
	mod.g = depth_shade
	mod.b = depth_shade
	modulate = mod
	pass

func set_faction():
	var m: ShaderMaterial = material
	faction = batman.grid_factions.get_cellv(coord)
	
	m.set_shader_param("replacer_col_2", Color(colset[faction][0]))
	pass

func set_type(to_type: int):
	type = to_type
	followup_tiletype()
	pass

func get_center_gpos() -> Vector2:
	var gpos: Vector2 = rect_global_position
	gpos += (rect_size/2.0)
	return gpos
	pass

func followup_tiletype():
	if $Type.text != str(type):
		$Type.text = str(type)
	if $Crack.visible != (type == batman.tiletypes.CRACK):
		$Crack.visible = (type == batman.tiletypes.CRACK)
	if $Pit.visible != (type == batman.tiletypes.PIT):
		$Pit.visible = (type == batman.tiletypes.PIT)








