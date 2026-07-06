extends Resource
class_name MoveAction

# Export vars for the TRES file ------------------------------------------------

export var display_name: String
export (String, MULTILINE) var short_desc: String
export (String, MULTILINE) var display_desc: String
var key: String # For "Yank-Shot" it's "yank" - whatever the resource name is. Just a convenient reference point; almost certainly a redundancy.

#export (int, 1, 8) var options: int = 1 # Deprecated in favour of variants & aimflower!
export var option_image: Texture
export (String, MULTILINE) var option_desc: String

export (int, 0, 8) var cost: int = 1

#	NOT_MOVING,
#	BY_TRAVEL, # Affected by ice! Does not factor in hover etc; this is a plain adjacency thing
#	BY_JUMP,
#	BY_WARP,
#	BY_SPECIAL_TRAVEL, # A cartwheel might be immune to slipping, for instance
#	MOVED_EXTERNALLY, # Similar to BY_TRAVEL but helps separate external forces from ourselves
#		# If someone else warps our position, we'll just use BY_WARP rather than make another WARPED_EXTERNALLY
#	DNU

enum motionchecks {REST, TRAVEL, JUMP, WARP}
export (motionchecks) var motion_type: int = motionchecks.REST

export (int, 0, 8) var on_use_cooldown: int = 0
export (int, 0, 8) var initial_cooldown: int = 0
var current_cooldown: int = 0

export var display_tags: String # EG piercing, fire, knockback, heavy

export (int, 0, 8) var uses_per_turn: int = 0
export (int, 0, 8) var uses_per_battle: int = 0
var current_turn_uses: int = 0
var current_battle_uses: int = 0

export var req_successful_preview: bool = false

# Input control and selection styles, for aimflower control
enum inputstyles {
	RELATIVE,	# Treats 3x3 grid as positions to move between
	EXACT,		# Exact input is selected (can't reach middle tile!)
	TOGGLE,		# Toggles exclusively back and forth between states A and B; must be a binary!
}
export (inputstyles) var selection_style: int = 0
#var toggle_cell_options: Array = [] # Can hold either exact cells, or subarrays of exact cells
#var toggle_index: int = 0 # Current position within the toggle_options array

#export var use_exact_input_vector: bool = false # If false, it's relative (almost always)
export var override_global_variant_on_move_load: bool = false # If true, when selecting this move we ALWAYS the batman var back to this starting var.
export var misc: String

var actor: Actor # Quickref!
var variant: int # Shortcut that gets updated against batman.highlighted_subactop


# Preview data's storage -------------------------------------------------------

# Colours needed: 5 (bad, good, neutral, passthrough/pass, error)
var colors: Dictionary = {
	ROWS.BAD:      Color("e9148a"), # 0
	ROWS.GOOD:     Color("00c84c"), # 1
	ROWS.NEUTRAL:  Color("f4dd30"), # 2
	ROWS.PASS:     Color("488a75"), # 3
	ROWS.ERROR:    Color("595565"), # 4
	ROWS.FALLBACK: Color("f3fcf0"), # 5
}
var sets: Array2D

enum ROWS {  # TOP TO BOTTOM
	BAD,      # Negative outcome, like a debuff OR just plain damage
	GOOD,     # Positive outcome, like a buff
	NEUTRAL,  # Repositioning
	PASS,     # Shooting through an empty tile
	ERROR,    # When an actor blocks a movement from playing out, eg
	FALLBACK  # Whatever's left; often just the acting actor's tile
}
enum COLS { # LEFT TO RIGHT
#	COLOR, # REMOVED; cheaper data-wise to reference a const rather than set it manually
	ACTOR_ARRAY, # An array of Actors. Adding an Actor MUST add its cell. Only for later quick reference, though.
	ARROW_ARRAY, # An array of Rect2s representing Line2Ds. The line travel data is stored as "size - position". Adding an arrow MUST add cells to the cell arrays.
	ALLCELL_ARRAY, # Cells determined by the arrows AND manual cells; kept separate just for easy processing of move actions keeping "legit" cells relevant; combined into display cells
	PURECELL_ARRAY, # An array of Vector2s showing cells affeted by each colourtype, ONLY set by add_actor() or add_cell(), NOT add_arrow()!
	DISPLAY_CELLS, # An array of cells AFTER the priority function has been run, which will ensure that ALL listed cells in ALL cell arrays are unique and do not recur across the entire dataset
}

# You can either manually feed in a celldirectly, or manually feed in an actor (whose coord will auto-feed-in as a cell)

# Actors on a N cell *must* have N outline highlighting and be considered 'affected' (even if ghost)

# The actions can shorthand target the actors by their coords, where "attack all bad cells by coord" will tackle the actor without having to log it twice... right?

var starting_variant: Vector2
var actualized_variants: Array = [] # The below list, restricted to only what's situationally possible
var plausible_variants: Array = [] # ALL the plausible variant vectots, regardless of what might be situationally POSSIBLE

var affected_actors: Array = [] # All of em! Just for reference.
var unique_cells: Array = []
var passfail: bool = false # Default false; only mark it true when, you know, true
var ready_to_use: bool = false # Default false; only mark it true when it is VALID TO PICK AND USE

# ------------------------------------------------------------------------------

func log_move_use():
	actor.spend(cost)
	
	if on_use_cooldown > 0:
		current_cooldown = (on_use_cooldown + 1) # Adds 1 to account for current turn
	
	current_battle_uses += 1
	current_turn_uses += 1
	pass

func is_usable(ignore_ap: bool = false) -> bool:
	if !ignore_ap:
		if cost > actor.action_points:
			return false
	
#	if !passfail: return false
	
	if current_cooldown > 0:
		return false
	
	if current_turn_uses >= uses_per_turn:
		return false
	
	if current_battle_uses >= uses_per_battle:
		return false
	
	return true

func prepare_actualized_variants():
	actualized_variants.clear()
#	starting_variant = Vector2.ZERO
	
	# Custom path, if custom logic is desired
	if has_method("LOAD_VARIANTS"):
		call("LOAD_VARIANTS")
	else: # Default path otherwise
		for vec in plausible_variants:
			if batman.grid_actors.has_cellv(actor.coord + vec):
				actualized_variants.append(vec)
	
	# Our preferred default is the first one on the list
	if !actualized_variants.empty():
		# If the one we were using is no longer possible, find another one! (We'll probably want to replace this later?)
		if !actualized_variants.has(starting_variant):
			starting_variant = actualized_variants.front()
	
#	print("actualized_variants for ",self," now: ",actualized_variants)
	pass

func end_action():
	actor.end_action()
	pass

var pref: String = "["
var suff: String = "]"
func _to_string() -> String:
	if resource_name != "":
		return str(pref,resource_name,suff)
	return str(pref,utils.get_resource_name(self),suff)
	pass

# ActionPreviewData method dump! -----------------------------------------------

func initialize_MPD():
	sets = Array2D.new()
	sets.resize(COLS.size(), ROWS.size())
	clear_MPD() # Also sets up arrays
	pass

func clear_MPD():
	passfail = false
	ready_to_use = false
	unique_cells.clear()
	affected_actors.clear()
	
	var x: int = 0
	for nx in COLS.size():
		var y: int = 0
		for ny in ROWS.size():
			sets.set_cell(x, y, [])
			y += 1
		x += 1
	pass

# -

# Determines all relevant cells for the MPD, including priorities
func generate_cell_highlights():
	unique_cells.clear()
	
	# First, loop through and quickly get all cells
	
	var y: int = 0
	for row in ROWS.size():
		var cell_array: Array = sets.get_cell(COLS.ALLCELL_ARRAY, y)
		for cell in cell_array:
			if !unique_cells.has(cell):
				unique_cells.append(cell)
		y += 1
		pass
	
	if utils.actorpass(actor):
		if !unique_cells.has(actor.coord):
			unique_cells.append(actor.coord)
	
	# Second, loop through in a specific priority order (first to last) and map each cell to a 'final' colour
	var bads:   Array = sets.get_cell(COLS.ALLCELL_ARRAY, ROWS.BAD)
	var goods:  Array = sets.get_cell(COLS.ALLCELL_ARRAY, ROWS.GOOD)
	var neuts:  Array = sets.get_cell(COLS.ALLCELL_ARRAY, ROWS.NEUTRAL)
	var passes: Array = sets.get_cell(COLS.ALLCELL_ARRAY, ROWS.PASS)
	var errs:   Array = sets.get_cell(COLS.ALLCELL_ARRAY, ROWS.ERROR)
	
	# No duplicates, AND a fallbak case - we're covered!
	for cell in unique_cells:
		if bads.has(cell):
			if goods.has(cell):
				add_priority_cell(cell, ROWS.PASS) # Used for 'both'
			else:
				add_priority_cell(cell, ROWS.BAD)
		elif goods.has(cell): # We know it's not Bad+Good because of the above
			add_priority_cell(cell, ROWS.GOOD)
		elif neuts.has(cell):
			add_priority_cell(cell, ROWS.NEUTRAL)
		elif errs.has(cell):
			add_priority_cell(cell, ROWS.ERROR)
		elif passes.has(cell):
			add_priority_cell(cell, ROWS.PASS)
		else:
			add_priority_cell(cell, ROWS.FALLBACK)
	pass

# ---

func add_actor(new_actor, type: int):
	if type >= ROWS.size() or type < 0: return
	if !utils.actorpass(new_actor): return
	###
	
	var cell_array: Array = sets.get_cell(COLS.PURECELL_ARRAY, type)
	if !cell_array.has(new_actor.coord):
		cell_array.append(new_actor.coord)
	
	var allcell_array: Array = sets.get_cell(COLS.ALLCELL_ARRAY, type)
	if !allcell_array.has(new_actor.coord):
		allcell_array.append(new_actor.coord)
	
	var actor_array: Array = sets.get_cell(COLS.ACTOR_ARRAY, type)
	if !actor_array.has(new_actor):
		actor_array.append(new_actor)
	
	if !affected_actors.has(new_actor):
		affected_actors.append(new_actor)
	pass

func add_cell(coord: Vector2, type: int, from_arrow: bool = false):
	if type >= ROWS.size() or type < 0: return
	if !batman.grid_tiles.has_cellv(coord): return
	###
	
#	print("adding cell for ",actor)
	
	var cell_array_all: Array = sets.get_cell(COLS.ALLCELL_ARRAY, type)
	if !cell_array_all.has(coord):
		cell_array_all.append(coord)
	
	if from_arrow: return
	
	var cell_array_pure: Array = sets.get_cell(COLS.PURECELL_ARRAY, type)
	if !cell_array_pure.has(coord):
		cell_array_pure.append(coord)
	pass

func add_cellset(coords: Array, type: int, is_exact: bool = true):
	if type >= ROWS.size() or type < 0: return
	
	
	var purecell_array: Array = sets.get_cell(COLS.PURECELL_ARRAY, type)
	var allcell_array: Array = sets.get_cell(COLS.ALLCELL_ARRAY, type)
	for coord in coords: if coord is Vector2:
		if !is_exact: coord += actor.coord
		if !batman.grid_tiles.has_cellv(coord): continue
		###
		if !purecell_array.has(coord):
			purecell_array.append(coord)
		if !allcell_array.has(coord):
			allcell_array.append(coord)
		pass
	
	pass

func add_arrow(start_coord: Vector2, end_coord: Vector2, type: int, enforce_line: bool = true):
	if type >= ROWS.size() or type < 0: return
	if start_coord == end_coord: return
	if !batman.grid_tiles.has_cellv(start_coord): return
	if !batman.grid_tiles.has_cellv(end_coord): return
	if enforce_line:
		if !support.is_arrow_a_line(start_coord, end_coord): return
	###
	
	var arrow_array: Array = sets.get_cell(COLS.ARROW_ARRAY, type)
	var dupe: bool = false
	for arrowset in arrow_array: if arrowset is Rect2:
		if arrowset.position.is_equal_approx(start_coord):
			if arrowset.size.is_equal_approx(end_coord):
				dupe = true
				break
	if dupe: return
	
	# Size - Position = travel vector (motion) for the arrow!
#	var new_arrow: Rect2 = Rect2(start_coord, end_coord)
	var new_arrow: Rect2 = Rect2(
		batman.grid_gpos.get_cellv(start_coord),
		batman.grid_gpos.get_cellv(end_coord)
		)
	arrow_array.append(new_arrow)
	
	# Then we add each cell within the arrow to our cell arrays!
	var motion: Vector2 = end_coord - start_coord
	var step: Vector2 = motion.normalized()
	var step_coord: Vector2 = start_coord
	var maxlen: float = motion.length()
	while !step_coord.is_equal_approx(end_coord):
		add_cell(step_coord.round(), type, true)
		step_coord += step
		var thismotion: Vector2 = step_coord - start_coord
		var thislen: float = thismotion.length()
		if thislen > maxlen: break
		if !batman.grid_tiles.has_cellv(step_coord): break
	add_cell(end_coord, type, true)
	pass

func add_priority_cell(coord: Vector2, type: int):
	if type >= ROWS.size() or type < 0: return
	if !batman.grid_tiles.has_cellv(coord): return
	###
	
	var cell_array: Array = sets.get_cell(COLS.DISPLAY_CELLS, type)
	if !cell_array.has(coord):
		cell_array.append(coord)
	pass

# ---

# Returns the FIRST Actor - only helpful if you expect there to only be one, for convenience
func get_first_actor_by_MPD_type(type: int) -> Object:
	var actor_array: Array = sets.get_cell(COLS.ACTOR_ARRAY, type)
	if actor_array.empty(): return null
	return actor_array[0]
	pass

func get_all_actors_by_MPD_type(type: int) -> Array:
	var actor_array: Array = sets.get_cell(COLS.ACTOR_ARRAY, type)
	return actor_array
	pass

func get_first_cell_by_MPD_type(type: int, use_arrowcells = false) -> Vector2:
	var cells: Array
	if use_arrowcells:
		cells = sets.get_cell(COLS.ALLCELL_ARRAY, type)
	else:
		cells = sets.get_cell(COLS.PURECELL_ARRAY, type)
	if cells.empty(): return Vector2(-99, -99) # Should never happen - you only add cells to this AFTER validating, and if you have no cells to work with in the preview you shouldn't be allowed to get further.
	return cells.front()
	pass

func get_all_cells_by_MPD_type(type: int, use_arrowcells = false) -> Array:
	if use_arrowcells:
		return sets.get_cell(COLS.ALLCELL_ARRAY, type)
	return sets.get_cell(COLS.PURECELL_ARRAY, type)





