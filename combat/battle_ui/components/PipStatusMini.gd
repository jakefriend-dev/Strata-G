extends HBoxContainer

var bui: Node2D
var actor: Actor

# ---

func _ready():
#	update_values() # BUI can do this
	pass

func refresh():
	
	var vis_buff: bool = bool(false)
	var vis_debuff: bool = bool(false)
	var vis_misc: bool = bool(false)
	
	if $Buff.visible != vis_buff:
		$Buff.visible = vis_buff
	
	if $Debuff.visible != vis_debuff:
		$Debuff.visible = vis_debuff
	
	if $Misc.visible != vis_misc:
		$Misc.visible = vis_misc
	pass
