extends Timer
class_name YTimer

signal unwait() # Manually emitted by timeout AFTER confirming the user exists to be timed out
var caller # in theory any node
var callername # stored! in case it dies

func _ready():
	autostart = false
	one_shot = true
	pause_mode = Node.PAUSE_MODE_STOP
	name = "YieldTimer" # Expected to self-numerate
	connect("timeout", self, "end")
	pass

func end():
	if caller != null:
		if is_instance_valid(caller):
			emit_signal("unwait")
		else:
#			print("YTIMER: Could not safely time out ",callername)
			pass
	
	queue_free()
	pass
