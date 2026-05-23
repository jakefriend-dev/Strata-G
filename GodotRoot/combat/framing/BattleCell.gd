extends NinePatchRect

var colset: Dictionary = {
	turn.factions.PLAYER:  ["5392df"],
	turn.factions.ENEMY:   ["df538e"],
}

# Un-set; 0 is default
var row: int = -1
var col: int = -1
var coord: Vector2 = Vector2(-1, -1)
var type: int = -1
var faction: int = -1

# ---

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
	faction = turn.grid_factions.get_cellv(coord)
	
	m.set_shader_param("replacer_col_2", Color(colset[faction][0]))
	pass

# warning-ignore:unused_argument
func set_type(to_type: int):
	type = to_type
	pass

func get_center_gpos() -> Vector2:
	var gpos: Vector2 = rect_global_position
	gpos += (rect_size/2.0)
	return gpos
	pass









