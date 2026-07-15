extends Node2D

onready var tween: Tween = get_node("Tween")

# REFERENCE TO BATMAN.TURNQUEUE ONLY
#var turnqueue: Array = [
	# Full of turndata dictionaries, already sorted in order!
	# Assumes all turntakers are ALIVE
		# actor						Null if no longer relevant, otherwise an Actor
		# init						Float; The original initiative roll (eg. 5.72013)
		# has_finished_turn			Bool that fires once its turn is complete
		# ofc_name					Direct from the actor's ofc_name
		# numerated_name			As "Doggo 1" with a space and all, even if there's only 1
		# numeration				Int; the 1 in Doggo 1
		# turncount_of_this_actor	Int; 1 by default and a boss could have 2 or 3
		# turnpos					Int; managed by batman but 
#]

var y_offscreen: float = 28.0
var turntakers: Array = [] # Simple array holding refs to ALL turntaker scenes
onready var tt_par: Node2D = $All_TT

# ---

func _ready():
	batman.connect("turnqueue_constructed", self, "on_turnqueue_construction")
	batman.connect("turnqueue_updated", self, "on_turnqueue_update")
	pass

func on_turnqueue_construction():
	for ttd in batman.turnqueue: if ttd is Dictionary:
		var tt: Node2D = loader.res_turntaker.instance()
		
#		tt.set("actor", ttd["actor"])
		var order: int = ttd["turnpos"]
		tt.set("order", order)
		tt.set("position", get_pos(order, true))
		tt.set("vis_state", tt.PORTRAIT)
		
		turntakers.append(tt)
		tt_par.add_child(tt)
		tt.set_actor(ttd["actor"])
	pass

func on_turnqueue_update():
	
	pass

# Positions

func get_pos(order: int, be_offscreen: bool = false) -> Vector2:
	if order < 1: return Vector2.ZERO
	
	if order > 9:
		order = 9
		be_offscreen = true
	
	var pos2D: Position2D = $All_POS.get_node(str("Order",order))
	var pos: Vector2 = pos2D.position
	if be_offscreen:
		pos.y -= y_offscreen
	
	return pos
	pass

# Tweens!

func move_tt_offscreen():
	pass
