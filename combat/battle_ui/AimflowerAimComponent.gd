extends Node2D
#tool

enum gridspaces {TOP_LEFT, TOP_CENTER, TOP_RIGHT, LEFT_CENTER, CENTER, RIGHT_CENTER, BOTTOM_LEFT, BOTTOM_CENTER, BOTTOM_RIGHT}
export (gridspaces) var grid_angle: int
var grid_vec: Vector2

enum states {DISABLED, ENABLED_INVALID, ENABLED_INERT, ENABLED_SELECTED}
var state: int = -1

# Order is always backing, arrow, arrow-edge
var colsets: Array = [
	# Disabled
	[Color("7b424d"), Color("683c34"), Color("7b424d")],
	# Invalid
	[Color("566a89"), Color("79808d"), Color("566a89")],
	# Inert
	[Color("9cd8fc"), Color("cce2e1"), Color("9cd8fc")],
	# Selected
	[Color("fdd18c"), Color("ffffff"), Color("f5b4ff")],
]

#export var e_run_setup: bool = false setget run_editor_preview

# ---

#func run_editor_preview(tf: bool):
#	if !tf: return
#	if !Engine.editor_hint: return
#	_ready()
#	pass

func _ready():
	for child in get_children(): if child is Sprite:
		child.frame = grid_angle
	map_int_to_vec()
	update_visual()
	batman.connect("action_option_view_changed", self, "update_visual")
	batman.connect("new_action_preview_data_readied", self, "update_visual")
	batman.connect("on_turn_ended_naturally", self, "update_visual")
	batman.connect("on_turn_ended_via_interruption", self, "update_visual")
	batman.connect("pre_turn_setup", self, "update_visual")
	pass

func map_int_to_vec():
	match grid_angle:
		gridspaces.TOP_LEFT:
			grid_vec = Vector2.UP + Vector2.LEFT
		gridspaces.TOP_CENTER:
			grid_vec = Vector2.UP
		gridspaces.TOP_RIGHT:
			grid_vec = Vector2.UP + Vector2.RIGHT
		gridspaces.LEFT_CENTER:
			grid_vec = Vector2.LEFT
		gridspaces.CENTER:
			grid_vec = Vector2.ZERO
		gridspaces.RIGHT_CENTER:
			grid_vec = Vector2.RIGHT
		gridspaces.BOTTOM_LEFT:
			grid_vec = Vector2.DOWN + Vector2.LEFT
		gridspaces.BOTTOM_CENTER:
			grid_vec = Vector2.DOWN
		gridspaces.BOTTOM_RIGHT:
			grid_vec = Vector2.DOWN + Vector2.RIGHT
	pass

func update_visual(_na = null):
	if batman.loaded_move == null: return
	
	var last_state: int = state
	
	if batman.loaded_variant == grid_vec:
		state = states.ENABLED_SELECTED
	elif batman.loaded_move.actualized_variants.has(grid_vec):
		state = states.ENABLED_INERT
	elif batman.loaded_move.plausible_variants.has(grid_vec):
		state = states.ENABLED_INVALID
	else:
		state = states.DISABLED
	
	if state == last_state: return
	
	var sm: ShaderMaterial = $Top.material
	sm.set_shader_param("replacer_col_1", colsets[state][0])
	sm.set_shader_param("replacer_col_2", colsets[state][1])
	sm.set_shader_param("replacer_col_3", colsets[state][2])
	
	if state == states.ENABLED_SELECTED:
		$Top.position = Vector2(-1, -1)
	else:
		$Top.position = Vector2.ZERO
	pass












