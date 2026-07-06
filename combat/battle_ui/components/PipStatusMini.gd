extends HBoxContainer

var bui: Node2D
var actor: Actor

# ---

func _ready():
#	update_values() # BUI can do this
	pass

func refresh():
	
	var types_in_play: Array = actor.get_status_icons_in_play()
	
	var overall_vis: bool = !types_in_play.empty()
	var vis_buff:   bool = types_in_play.has("good")
	var vis_debuff: bool = types_in_play.has("bad")
	var vis_misc:   bool = types_in_play.has("misc")
	
	if visible != overall_vis:
		visible = overall_vis
	
	if $Buff.visible != vis_buff:
		$Buff.visible = vis_buff
	
	if $Debuff.visible != vis_debuff:
		$Debuff.visible = vis_debuff
	
	if $Misc.visible != vis_misc:
		$Misc.visible = vis_misc
	pass
