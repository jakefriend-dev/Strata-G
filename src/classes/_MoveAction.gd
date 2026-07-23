extends Resource
class_name MoveAction

# Export vars for the TRES file ------------------------------------------------

export var display_name: String
export var shorthand_name: String = "" # Explicitly for fitting the MoveWindow; if blank it'll just use display name
export (String, MULTILINE) var short_desc: String
export (String, MULTILINE) var display_desc: String
var key: String # For "Yank-Shot" it's "yank" - whatever the resource name is. Just a convenient reference point; almost certainly a redundancy.

#export (int, 1, 8) var options: int = 1 # Deprecated in favour of variants & aimflower!
export var option_image: Texture
export (String, MULTILINE) var option_desc: String

export (int, 0, 8) var cost: int = 1
export (int, 0, 8) var base_damage: int = 0 # Partly just a shortcut, but used to calculate descriptions live by replacing any text reading "DMG" with a calculation of (base_damage + actor.get_damage_buff())

enum motionchecks {
	REST,
	TRAVEL,
	JUMP,
	WARP,
	SPECIAL_TRAVEL, # Something like "A cartwheel which bypasses Travel rules"
	DNU}
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
	CYCLE,		# Preloads a set of Vector2 options within an array and cycles between those exclusively! For 'Toggle' style, just load 2 options.
}
export (inputstyles) var selection_style: int = 0
#var cycle_cell_options: Array = [] # Can hold either exact cells, or relative cells - must be Vector2s!
var cycle_index: int = 0 # Current position within the toggle_options array

#export var use_exact_input_vector: bool = false # If false, it's relative (almost always)
export var override_global_variant_on_move_load: bool = false # If true, when selecting this move we ALWAYS the batman var back to this starting var.

# These should generally only be needed for ENEMY moves:
export var req_successful_telegraph: bool = false # If true, the move MUST contain a "PREVIEW()" function which has its own cost; telegraphs should also (like reactions) end the turn. A successful telegraph does NOT mean a guarantee of a successful attack execution!
export (int, 0, 8) var telegraph_cost: int = 0
#var telegraph_pass: bool = false # True once telegraph is passed, and remains true until 'consumed' by use or RE_PREVIEW fails.
export (motionchecks) var telegraph_motion_type: int = motionchecks.REST

export var fracture_on_use: bool = false
export var misc: String # As of July 18, still not used anywhere...!

var actor: Actor # Quickref!
var variant: int # Shortcut that gets updated against batman.highlighted_subactop



# Preview data's storage (and telegraphs) --------------------------------------

# Colours needed: 5 (bad, good, neutral, passthrough/pass, error)
var colors: Dictionary = {
	ROWS.BAD:      Color("c34b91"), # 0
	ROWS.GOOD:     Color("45b8b3"), # 1
	ROWS.NEUTRAL:  Color("ffa468"), # 2
	ROWS.PASS:     Color("566a89"), # 3
	ROWS.ERROR:    Color("4a3858"), # 4
	ROWS.FALLBACK: Color("cfedd0"), # 5
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
var plausible_variants: Array = [] # ALL the plausible variant vectors, regardless of what might be situationally POSSIBLE
var manual_variant: Vector2 = Vector2(-99, -99) # Must be manually set immediately before use; like for Walk

var affected_actors: Array = [] # All of em! Just for reference.
var unique_cells: Array = []
var passfail: bool = false # Default false; only mark it true when, you know, true
var error_text: String = "" # When failing a passfail, provide text that MoveWindow can use!
var ready_to_use: bool = false # Default false; only mark it true when it is VALID TO PICK AND USE

var config_complete: bool = false

# ------------------------------------------------------------------------------

func do_startup_config():
	if config_complete: return
#	print(self,".do_startup_config()")
	
	set_local_to_scene(true) # I don't think this does anything, frankly. If you want local copies, call .duplicate() when loading the move.
	config_complete = true # One-time - maybe validation overkill, but in case of duplicates.
	
	if resource_name == "":
		resource_name = utils.get_resource_name(self)
	
	restage_MPD("MoveAction startup")
	
	plausible_variants = strife.aimflower_vectors_from_file(option_image.resource_path)
	
	if req_successful_telegraph:
		strife.connect("notable_combatstate_event", self, "update_telegraph_previews")
	pass

func run_validation_pass(print_soft_errors: bool = false) -> bool:
	if !has_method("PREVIEW"):
		if !utils.actorpass(actor):
			if req_successful_preview:
				print("Actorless move ",self," can't find PREVIEW() method, but previews are required!")
				return false
		elif actor.faction == batman.factions.PLAYER: # Ah so we can't use this, it's recursion
			if req_successful_preview:
				print(actor.name," can't find PREVIEW() method for move ",self,", but previews are required!")
				return false
		else:
			if req_successful_telegraph and req_successful_preview:
				print(actor.name," separately tagged to require a successful preview AND a telegraph; should only be one or the other!")
				return false
			elif req_successful_telegraph or req_successful_preview:
				print(actor.name," can't find PREVIEW() method for move ",self,", but previews/telegraphs are required!")
				return false
	
	if !has_method("ACT"):
		print(self," can't be loaded, no ACT() method!")
		return false
	
	if option_image == null:
		print(self," can't be loaded, no option_image!")
		return false
	
	if selection_style == inputstyles.CYCLE:
		if !has_method("LOAD_VARIANTS"):
			print(self," can't be loaded, it's CYCLE type but has no LOAD_VARIANTS() method!")
			return false
	
	if req_successful_telegraph:
		if !has_method("RE_PREVIEW"):
			if print_soft_errors: print(self," can't find RE_PREVIEW() method! Allowed to bypass via re-running PREVIEW... *SOFT* error!")
#			return false
	
	return true
	pass

# ---

func usability_check(a: Actor = null, do_print: bool = false) -> bool:
	# VALIDATION FIRST
	if utils.actorpass(actor):
		a = actor
	else:
		# We're sending an actor even though MOST moves do have them, just since common moves don't!
		if !utils.actorpass(a):
			print(self,": usability_check() failed b/c no valid actor!")
			return false
	
	# We have an actor (as expected), so actual checks!
	
	prepare_actualized_variants() # Needed since this function is skipped by 'normal' player moves
	
	if !a.can_afford(effective_cost()): # Enemy telegraphs accounted for!
		if do_print: print(a.name," can't afford ",effective_cost(),"-AP for ",self)
		return false
	
	if current_cooldown > 0:
		if do_print: print(a.name," still on cooldown for ",current_cooldown," turns: ",self)
		return false
	
	if req_successful_preview and !passfail:
		if do_print: print(a.name," needs preview pass for ",self)
		return false
	
	if actualized_variants.empty():
		if do_print: print(a.name," has zero possible variants for ",self," at this position! Plausible variants: ",plausible_variants)
		return false
	
	if uses_per_turn > 0: # Ignore if unlimited
		if current_turn_uses >= uses_per_turn:
			if do_print: print(a.name," already maxed per-turn uses of ",self)
			return false
	
	if uses_per_battle > 0: # Ignore if unlimited
		if current_battle_uses >= uses_per_battle:
			if do_print: print(a.name," already maxed per-battle uses of ",self)
			return false
	
	return true
	pass

func quick_context_passfail_check() -> bool:
	if passfail:
		if req_successful_telegraph:
			return true # Already verified!
	
	if req_successful_preview:
		var repreviewed: bool = false
		if has_method("RE_PREVIEW"):
			if passfail:
				repreviewed = true
				call("RE_PREVIEW")
		
		if !repreviewed:
			passfail = false # Always reset passfail if it is NEITHER a telegraph or a RE-preview
			print(self," quick_context_passfail_check A")
			call("PREVIEW")
		
		if !passfail:
			if !utils.actorpass(actor):
				actor.release_targeted_tiles()
		return passfail
	
	if req_successful_telegraph:
		# If it's a telegraph, we want to approve it - telegraphs have to 'execute' their PREVIEWs as an action and speak for themselves.
		return true
	
	# And lower priority, we'll do a PREVIEW cycle anyways, cuz why not!
	
	if has_method("RE_PREVIEW"): # Prioritized slightly over PREVIEW!
		call("RE_PREVIEW")
		if !passfail:
			if !utils.actorpass(actor):
				actor.release_targeted_tiles()
		return passfail
	
	passfail = false # Always reset passfail if it is NEITHER a telegraph or a RE-preview
	if has_method("PREVIEW"):
		print(self," quick_context_passfail_check B")
		call("PREVIEW")
		if !passfail:
			if !utils.actorpass(actor):
				actor.release_targeted_tiles()
		return passfail
	
	return true # Otherwise, by default assume if no conditions need to be met, we're good to go!
	pass

func totality_check(a: Actor = null, do_print: bool = false) -> bool:
	if !quick_context_passfail_check():
		print(self,".totality_check() failed context check")
		return false
	
	if !usability_check(a, do_print):
		print(self,".totality_check() failed usability check")
		return false
	
	return true
	pass

func will_next_use_be_a_telegraph() -> bool:
	if !req_successful_telegraph:
		return false
	
	if !utils.actorpass(actor):
		return false
	
	if actor.telegraphed_move != self:
		return false
	
	return true
	pass

func update_telegraph_previews():
	if !utils.actorpass(actor): return
	if actor.telegraphed_move != self: return
	if batman.is_my_action(actor): return # We do NOT DO THIS during live actions, or we'll risk ending them!
	
	
#	print(self,".update_telegraph_previews()")
	passfail = false # Regardless of if we clear or not
	
	if has_method("RE_PREVIEW"):
		# We DON'T clear MPD/targets here, because re-previews tweak existing data without need for a total rerun.
		call("RE_PREVIEW")
	elif has_method("PREVIEW"):
		# We DO clear here, because we're starting from scratch.
		restage_MPD("MoveAction preview update A")
		actor.release_targeted_tiles()
		print(self," update_telegraph_previews")
		call("PREVIEW")
	else:
		print(self,": This is a pre-validated impossible case. How did you get here?? Breakpoint!")
		
		pass
	
	if !passfail:
		restage_MPD("MoveAction preview update B")
		actor.release_targeted_tiles()
		actor.telegraphed_move = null
		actor.emit_signal("on_telegraph_failed", self)
	pass

# ---

func log_move_use():
	
	actor.spend(self) # This works out telegraph vs non-telegraph costs on its own!
	
	if will_next_use_be_a_telegraph(): return
	
	if on_use_cooldown > 0:
		current_cooldown = (on_use_cooldown + 1) # Adds 1 to account for current turn
	
	current_battle_uses += 1
	current_turn_uses += 1
	pass

func effective_cost() -> int:
	if utils.actorpass(actor):
		if actor.faction == batman.factions.PLAYER:
			return (cost + telegraph_cost) # Players treat the telegraph cost as part of the package
	
	# If not a player, separate telegraph cost is possible!
	if will_next_use_be_a_telegraph():
		return telegraph_cost
	
	return cost
	pass

func translate_desc(desc: String) -> String:
	var dmg: String = str(get_damage())
	desc = desc.replace("DMG", dmg)
	
	return desc
	pass

func get_damage() -> int:
	var damage: int = base_damage
	
	if utils.actorpass(actor): # Weird fringe case going to the turn of someone who just died, I guess...?
		damage += actor.get_damage_mod_total()
	
	if damage < 0: return 0
	return damage
	pass

# ---

func prepare_actualized_variants():
	error_text = ""
	actualized_variants.clear()
	
	# Custom path, if custom logic is desired
	if has_method("LOAD_VARIANTS"):
		if selection_style == inputstyles.CYCLE:
			starting_variant = Vector2(-99, -99) # We want to FORCE starting at the 'front of the line' so to speak!
		call("LOAD_VARIANTS")
	else: # Default path otherwise
		for vec in plausible_variants:
			if utils.actorpass(actor):
				if batman.grid_actors.has_cellv(actor.coord + vec):
					actualized_variants.append(vec)
			else:
				actualized_variants.append(vec) # Common moves can bypass
	
	# Our preferred default is the first one on the list
	if !actualized_variants.empty():
		# If the one we were using is no longer possible, find another one! (We'll probably want to replace this later?)
		if !actualized_variants.has(starting_variant):
			starting_variant = actualized_variants.front()
	
#	print("actualized_variants for ",self," now: ",actualized_variants," when starting_variant: ",starting_variant)
	pass

func end_action():
	batman.end_action()
	pass

func end_turn():
	batman.end_turn()
	pass

func end_telegraph():
	if utils.actorpass(actor):
		actor.set_targeted_tiles(get_all_cells_by_MPD_type(ROWS.BAD)) # This is the OVERWRITE function, not append, jfyi! So no need to release first
#		print(actor.name,"'s targeted tiles: ",actor.targeted_tiles)
		
#		print(self,".end_telegraph()")
		if batman.is_my_action(actor):
			end_action()
	pass

var pref: String = "["
var suff: String = "]"
func _to_string() -> String:
	if resource_name != "":
		return str(pref,resource_name,suff)
	return str(pref,utils.get_resource_name(self),suff)
	pass

# ActionPreviewData method dump! -----------------------------------------------

# warning-ignore:unused_argument
# "source" is only for debugging
func restage_MPD(source: String): # Replaces BOTH initialize_MPD() and clear_MPD() of olde
	if resource_name == "SPIN_DANCE": print(self,".restage_MPD(",source,")")
	
	if sets == null: # One-time setup
		sets = Array2D.new()
		sets.resize(COLS.size(), ROWS.size())
	
	passfail = false
	ready_to_use = false
	unique_cells.clear()
	affected_actors.clear()
	manual_variant = Vector2(-99, -99)
	
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

# -

func clear_all_arrows_by_type(type: int):
	sets.set_cell(COLS.ARROW_ARRAY, type, [])
	pass



