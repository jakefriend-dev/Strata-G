extends Node
class_name YPing

signal ping() # Manually emitted by timeout AFTER confirming the user exists to be timed out
var caller # in theory any node
var callername # stored! in case it dies

enum {UNDEFINED, FRAME_VIS, FRAME_PHYS, FRAME_IDLE, GAME_SETUP, GAME_RELEASED}
var type = UNDEFINED

var ignore_pause: bool = false

var needs_pre_setup: bool = false

func _ready():
	if ignore_pause:
		pause_mode = Node.PAUSE_MODE_PROCESS
	else:
		pause_mode = Node.PAUSE_MODE_INHERIT
	
	name = "YieldPing" # Expected to self-numerate
	var allocated: bool = false
	
	match type:
		FRAME_VIS:
			needs_pre_setup = true
			VisualServer.connect("frame_pre_draw", self, "pre_end")
			VisualServer.connect("frame_post_draw", self, "end")
			allocated = true
		FRAME_PHYS:
			get_tree().connect("physics_frame", self, "end")
			allocated = true
		FRAME_IDLE:
			get_tree().connect("idle_frame", self, "end")
			allocated = true
#		GAME_SETUP:
#			if utils.valid(globals.game): globals.game.connect("done_fully_loading_room", self, "end")
#			allocated = true
#		GAME_RELEASED:
#			if utils.valid(globals.game): globals.game.connect("ready_to_proceed", self, "end")
#			allocated = true
	
	if !allocated:
		queue_free()
	pass

func pre_end():
	if !needs_pre_setup: return
	
	match type:
		FRAME_VIS:
			needs_pre_setup = false
	pass

func end():
	if needs_pre_setup: return
	
	if caller != null:
		if is_instance_valid(caller):
			emit_signal("ping")
		else:
#			print("YPING [type ",type,"]: Could not safely time out ",callername)
			pass
	
	queue_free()
	pass
