extends HBoxContainer

var move: MoveAction # Linked upon Moveset generation (unless is_not_move)
var actor: Actor # Also linked, for quickref
export var nonmove_function: String = "" # If NOT blank and VALIDATED, signals that this MovesetOption is not a 'move' and instead a function, like "check party bag"

var tooltips_are_valid: bool = false # Used for colour control by MoveWindow
var loaded_tt_desc_text: String = ""
var loaded_tt_warn_text: String = ""

var nonmove_tooltip: String # Loaded externally!
var loaded_display_name: String = ""
var nonmove_display_name: String # Loaded externally!

var loaded_iconpar: HBoxContainer
var loaded_value: String = ""

export var my_x_col: int = 0
export var my_y_row: int = 0

#

enum s { # States represent the unselected AND selected variants!
	TBD,
	NOT_MOVE,
	UNAVAILABLE,
	AVAILABLE,
}

var colsets: Dictionary = {
	# Array indices are: Light colour, dark colour, unfill_height shader param
	s.NOT_MOVE: {
		0: [Color("cfedd0"), Color("8babbf"), 5],
#		0: [Color("8babbf"), Color("79808d"), 5],
		1: [Color("ffffff"), Color("ffda70"), 9],
		"highlight_shape": Color("cfedd0"),
	},
	s.UNAVAILABLE: {
		0: [Color("79808d"), Color("566a89"), 5],
		1: [Color("cfedd0"), Color("8babbf"), 9],
		"highlight_shape": Color("ff94b3"),
	},
	s.AVAILABLE: {
		0: [Color("ffdba5"), Color("ffa468"), 5],
		1: [Color("ffffff"), Color("94eed4"), 9],
		"highlight_shape": Color("94eed4"),
	},
}

var state: int = s.TBD
var valid: bool = false
var currently_highlighted: bool = false # Controlled externally

var window: Node2D # Our parent; sets itself

# ---

func update_against_new_move():
	validate()
	visual_refresh()
	pass

func full_refresh():
	validate()
	visual_refresh()
	pass

func validate():
	valid = false
	state = s.TBD
	loaded_tt_desc_text = ""
	loaded_tt_warn_text = ""
	loaded_iconpar = null
	loaded_value = ""
	loaded_display_name = ""
	tooltips_are_valid = false
	
	if nonmove_function != "":
		var funcname: String = str("CUSTOM_",nonmove_function)
		if window.has_method(funcname):
			valid = true
			state = s.NOT_MOVE
			loaded_tt_desc_text = nonmove_tooltip
			loaded_iconpar = $AllIcons/Arrow
			loaded_display_name = nonmove_display_name
			tooltips_are_valid = true
			return
	
	# Regular moves
	if move == null: return
	
#	print(name,".update_against_new_move().validate move ",move)
	
	valid = true
	loaded_display_name = move.display_name
	loaded_tt_desc_text = move.translate_desc(move.short_desc)
	
	if move.current_cooldown > 0:
		state = s.UNAVAILABLE
		loaded_iconpar = $AllIcons/Cooldown
		loaded_value = str(move.current_cooldown)
		loaded_tt_warn_text = str("Move in cooldown for ",move.current_cooldown," more turns")
	
	elif move.current_battle_uses >= move.uses_per_battle and move.uses_per_battle > 0:
		state = s.UNAVAILABLE
		loaded_iconpar = $AllIcons/Error
		loaded_value = "b"
		loaded_tt_warn_text = str("Move has reached per-battle limit [ ",move.uses_per_battle," ]")
	
	elif move.current_turn_uses >= move.uses_per_turn and move.uses_per_turn > 0:
		state = s.UNAVAILABLE
		loaded_iconpar = $AllIcons/Error
		loaded_value = "t"
		loaded_tt_warn_text = str("Move has reached per-turn limit [ ",move.uses_per_turn," ]")
	
	# At this point it should just be a matter of whether we can afford the AP cost or not
	
	elif move.effective_cost() > actor.action_points:
		state = s.UNAVAILABLE
		loaded_iconpar = $AllIcons/ActionNo
		loaded_value = str(move.effective_cost())
		loaded_tt_warn_text = str("Cannot afford ",move.effective_cost()," cost with ",actor.action_points," AP remaining")
	
	else: # We CAN afford it! Finally!
		state = s.AVAILABLE
		loaded_iconpar = $AllIcons/ActionYes
		loaded_value = str(move.effective_cost())
		tooltips_are_valid = true
		
		if move.on_use_cooldown > 0:
			loaded_tt_warn_text = str("Enters ",move.on_use_cooldown,"-turn cooldown after use")
		elif move.uses_per_battle > 0:
			var rem_uses: int = move.uses_per_battle - move.current_battle_uses
			loaded_tt_warn_text = str(rem_uses," per-battle uses remaining")
		elif move.uses_per_turn > 0:
			var rem_uses: int = move.uses_per_turn - move.current_turn_uses
			loaded_tt_warn_text = str(rem_uses," per-turn uses remaining")
		else:
			# ...And if it's just an AP cost issue and we CAN afford it, no message to really show?
			pass
	
	pass

func visual_refresh():
	
	if !valid:
		if $AllIcons.visible:
			$AllIcons.visible = false
		if $MoveName.text != "":
			$MoveName.text = ""
		
		if not batman.curr_actor is ActorPlayer:
			if $Highlight.visible:
				$Highlight.visible = false
		elif $Highlight.visible != currently_highlighted:
			$Highlight.visible = currently_highlighted
		if $Highlight.modulate != Color("000000"):
			$Highlight.modulate = Color("000000")
		return
	
	# Generic visibility setups
	if !$AllIcons.visible:
		$AllIcons.visible = true
	
	for child in $AllIcons.get_children():
		if child == loaded_iconpar:
			if !child.visible: child.visible = true
		else:
			if child.visible: child.visible = false
	
	if state != s.NOT_MOVE:
		loaded_iconpar.get_node("Count").text = loaded_value
	
	if $MoveName.text != loaded_display_name:
		$MoveName.text = loaded_display_name
	
	var m: ShaderMaterial = $MoveName.material
	
	var colset: Array = colsets[state][int(currently_highlighted)]
	
	m.set_shader_param("col_body",       colset[0])
	m.set_shader_param("col_mid",        colset[1])
	m.set_shader_param("unfill_height",  colset[2])
	
	if $Highlight.modulate != colsets[state]["highlight_shape"]:
		$Highlight.modulate = colsets[state]["highlight_shape"]
	
	if $Highlight.visible != currently_highlighted:
		$Highlight.visible = currently_highlighted
	pass

# ---








