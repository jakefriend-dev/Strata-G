extends HBoxContainer

var move: MoveAction # Linked upon Moveset generation
var actor: Actor # Also linked, for quickref

export var is_not_move: bool = false # Turn TRUE for things like 'check the party pouch' where a custom command is played

var icon_bases: Dictionary = { # 1-based Aseprite frames for when the FIRST of that count appears
	"cooldown": 2,
	"other": 3,
	0: 5,
	1: 7,
	2: 10,
	3: 14,
	4: 19,
}

# ---

func update_icon(is_selected: bool):
	var base_frame: int = 0
	
	if is_not_move:
		base_frame = icon_bases["other"]
		if is_selected: base_frame += 1
	elif !move.is_usable(true):
		base_frame = icon_bases["cooldown"]
	else:
		base_frame = icon_bases[move.cost]
		var emptiest: int = base_frame
		var full_unsel: int = base_frame + move.cost
		var full_sel: int = full_unsel + 1
		
		# I have more than enough to afford!
		if actor.action_points >= move.cost:
			if is_selected:
				base_frame = full_sel
			else:
				base_frame = full_unsel
		
		else: # I *cannot* afford!
			base_frame = emptiest + actor.action_points
		
		pass
	
	$Icons/APCost.frame = base_frame
	pass
