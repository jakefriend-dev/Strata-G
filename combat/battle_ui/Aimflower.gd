extends Node2D

var last_update_frame: int

func _ready():
	update_visual()
	batman.connect("action_option_view_changed", self, "update_visual")
	batman.connect("new_action_preview_data_readied", self, "update_visual")
	batman.connect("on_turn_ended_naturally", self, "update_visual")
	batman.connect("on_turn_ended_via_interruption", self, "update_visual")
	batman.connect("pre_turn_setup", self, "update_visual")
	pass

func update_visual(_na = null):
	var to_vis: bool = false
	if utils.actorpass(batman.curr_actor):
		if batman.curr_actor is ActorPlayer:
			to_vis = true
	
	if visible != to_vis:
		visible = to_vis
	
	if !to_vis: return
	
	#
	
	for afc in $ObjPar.get_children():
		afc.update_visual()
	
	var cycle_vis: bool = false
	if batman.loaded_move != null:
		if batman.loaded_move.selection_style == MoveAction.inputstyles.CYCLE:
			cycle_vis = true
	
	if $CycleSprite.visible != cycle_vis:
		$CycleSprite.visible = cycle_vis
	
	var this_frame: int = get_tree().get_frame()
	if this_frame == last_update_frame: return
	
	last_update_frame = this_frame
	
	var to_frame: int = $CycleSprite.frame
	to_frame += 1
	if to_frame > 3:
		to_frame = 0
	$CycleSprite.frame = to_frame
	pass
