extends Resource
class_name ActionPreviewData

var actor
# Colours needed: 5 (bad, good, neutral, passthrough/pass, error)
var colors: Dictionary = {
	ROWS.BAD:      Color("e9148a"),
	ROWS.GOOD:     Color("00c84c"),
	ROWS.NEUTRAL:  Color("f4dd30"),
	ROWS.PASS:     Color("488a75"),
	ROWS.ERROR:    Color("595565"),
	ROWS.FALLBACK: Color("f3fcf0"),
}
var sets: Array2D

enum ROWS {  # TOP TO BOTTOM
	BAD,      # Negative effect, like a debuff OR just plain damage
	GOOD,     # Positive effect, like a buff
	NEUTRAL,  # Repositioning
	PASS,     # Shooting through an empty tile
	ERROR,    # When an actor blocks a movement from playing out, eg
	FALLBACK  # Whatever's left; often just the acting actor's tile
}
enum COLS { # LEFT TO RIGHT
#	COLOR, # REMOVED; cheaper data-wise to reference a const rather than set it manually
	ACTOR_ARRAY, # An array of Actors. Adding an Actor MUST add its cell. Only for later quick reference, though.
	ARROW_ARRAY, # An array of Rect2s representing Line2Ds. The line travel data is stored as "size - position". Adding an arrow MUST add cells to the cell arrays.
	CELL_ARRAY, # An array of Vector2s showing cells affeted by each colourtype. Can be added manually, via actor, or via arrow.
	PRIORITY_CELLS, # An array of cells AFTER the priority function has been run, which will ensure that ALL listed cells in ALL cell arrays are unique and do not recur across the entire dataset
}

# You can either manually feed in a celldirectly, or manually feed in an actor (whose coord will auto-feed-in as a cell)

# Actors on a N cell *must* have N outline highlighting and be considered 'affected' (even if ghost)

# The actions can shorthand target the actors by their coords, where "attack all bad cells by coord" will tackle the actor without having to log it twice... right?

var affected_actors: Array = [] # All of em! Just for reference.
var unique_cells: Array = []
var passfail: bool = false # Default false; only mark it true when, you know, true
var ready_to_use: bool = false # Default false; only mark it true when it is VALID TO PICK AND USE

# ---

func initialize():
	sets = Array2D.new()
	sets.resize(COLS.size(), ROWS.size())
	clear() # Also sets up arrays
	pass

func clear():
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

# Determines all relevant cells for the APD, including priorities
func generate_cell_highlights():
	unique_cells.clear()
	
	# First, loop through and quickly get all cells
	
	var y: int = 0
	for row in ROWS.size():
		var cell_array: Array = sets.get_cell(COLS.CELL_ARRAY, y)
		for cell in cell_array:
			if !unique_cells.has(cell):
				unique_cells.append(cell)
		y += 1
		pass
	
	if utils.actorpass(actor):
		if !unique_cells.has(actor.coord):
			unique_cells.append(actor.coord)
	
	# Second, loop through in a specific priority order (first to last) and map each cell to a 'final' colour
	var bads:   Array = sets.get_cell(COLS.CELL_ARRAY, ROWS.BAD)
	var goods:  Array = sets.get_cell(COLS.CELL_ARRAY, ROWS.GOOD)
	var neuts:  Array = sets.get_cell(COLS.CELL_ARRAY, ROWS.NEUTRAL)
	var passes: Array = sets.get_cell(COLS.CELL_ARRAY, ROWS.PASS)
	var errs:   Array = sets.get_cell(COLS.CELL_ARRAY, ROWS.ERROR)
	
	# No duplicates, AND a fallbak case - we're covered!
	for cell in unique_cells:
		if bads.has(cell):
			if goods.has(cell):
				add_priority_cell(cell, ROWS.PASS) # Used for 'both'
			else:
				add_priority_cell(cell, ROWS.BAD)
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
	
	var cell_array: Array = sets.get_cell(COLS.CELL_ARRAY, type)
	if !cell_array.has(new_actor.coord):
		cell_array.append(new_actor.coord)
	
	var actor_array: Array = sets.get_cell(COLS.ACTOR_ARRAY, type)
	if !actor_array.has(new_actor):
		actor_array.append(new_actor)
	
	if !affected_actors.has(new_actor):
		affected_actors.append(new_actor)
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
	while !step_coord.is_equal_approx(end_coord):
		add_cell(step_coord, type)
		step_coord += step
		if !batman.grid_tiles.has_cellv(step_coord): break
	pass

func add_cell(coord: Vector2, type: int):
	if type >= ROWS.size() or type < 0: return
	if !batman.grid_tiles.has_cellv(coord): return
	###
	
	var cell_array: Array = sets.get_cell(COLS.CELL_ARRAY, type)
	if !cell_array.has(coord):
		cell_array.append(coord)
	pass

func add_cellset(coords: Array, type: int):
	if type >= ROWS.size() or type < 0: return
	###
	
	var cell_array: Array = sets.get_cell(COLS.CELL_ARRAY, type)
	for coord in coords: if coord is Vector2:
		if !batman.grid_tiles.has_cellv(coord): continue
		###
		if !cell_array.has(coord):
			cell_array.append(coord)
		pass
	
	pass

func add_priority_cell(coord: Vector2, type: int):
	if type >= ROWS.size() or type < 0: return
	if !batman.grid_tiles.has_cellv(coord): return
	###
	
	var cell_array: Array = sets.get_cell(COLS.PRIORITY_CELLS, type)
	if !cell_array.has(coord):
		cell_array.append(coord)
	pass

# ---

# Returns the FIRST Actor - only helpful if you expect there to only be one, for convenience
func get_actor_by_type(type: int) -> Object:
	var actor_array: Array = sets.get_cell(COLS.ACTOR_ARRAY, type)
	if actor_array.empty(): return null
	return actor_array[0]
	pass





