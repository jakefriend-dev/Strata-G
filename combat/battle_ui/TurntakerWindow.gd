extends Node2D

onready var tween: Tween = get_node("Tween")
var tweenqueue: Array = []

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
onready var tt_par: Node2D = $All_TT

var active_turntakers: Array = []
# ^ Simple array holding refs to ALL turntaker scenes, in order!
# If a TT here is missing from batman's TQ, it gets removed/destroyed; vice versa for adding

# ---

func _ready():
	batman.connect("turnqueue_constructed", self, "on_turnqueue_construction")
	batman.connect("turnqueue_updated", self, "on_turnqueue_update")
	pass

func on_turnqueue_construction():
	for ttd in batman.turnqueue: if ttd is Dictionary:
		add_new_turntaker(ttd)
	pass

func add_new_turntaker(ttd: Dictionary):
	var tt: Node2D = loader.res_turntaker.instance()
	
#	tt.set("actor", ttd["actor"])
	var turn_order: int = ttd["turnpos"]
	tt.set("turn_order", turn_order)
	tt.set("position", get_pos(turn_order))
	if turn_order_to_list_order(turn_order) == 1:
		tt.set("vis_state", tt.STATUS)
	else:
		tt.set("vis_state", tt.PORTRAIT)
	tt.set("linked_ttd", ttd)
	
	active_turntakers.append(tt)
	tt_par.add_child(tt)
	tt.set_actor(ttd["actor"])
	pass

func remove_turntaker(tt: Node2D):
	tt.get_parent().remove_child(tt)
	tt.queue_free()
	pass

func on_turnqueue_update():
	refresh_tt_values_and_activeness()
	
	for tt in active_turntakers:
		tt.position = get_pos(tt.turn_order)
		if turn_order_to_list_order(tt.turn_order) == 1:
			tt.vis_state = tt.STATUS
		else:
			tt.vis_state = tt.PORTRAIT
		tt.update_visible()
	pass

func refresh_tt_values_and_activeness():
	var exiting_tts: Array = []
	
	# Updates existing (and checks exiting)
	for tt in active_turntakers:
		if !batman.turnqueue.has(tt.linked_ttd) or !utils.actorpass(tt.actor):
			exiting_tts.append(tt)
			continue
		
		tt.turn_order = tt.linked_ttd["turnpos"]
	
	# Adds new
	for ttd in batman.turnqueue: if ttd is Dictionary:
		var has_match: bool = false
		for tt in active_turntakers:
			if tt.linked_ttd == ttd:
				has_match = true
				break
		if !has_match:
			add_new_turntaker(ttd)
	
	# Removes exiting
	for tt in exiting_tts:
		remove_turntaker(tt)
	pass

# Positions

func get_pos(turn_order: int, be_offscreen: bool = false) -> Vector2:
	
	var list_order: int = turn_order_to_list_order(turn_order)
	
	if list_order < 1: return Vector2.ZERO
	
	if list_order > 9:
		list_order = 9
		be_offscreen = true
	
	var pos2D: Position2D = $All_POS.get_node(str("Order",list_order))
	var pos: Vector2 = pos2D.position
	if be_offscreen:
		pos.y -= y_offscreen
	
	return pos
	pass

func turn_order_to_list_order(turn_order: int) -> int:
	var current_turn: int = batman.turncount
	if current_turn == 0: current_turn = 1
	
	var max_turn_order: int = batman.turnqueue.size()
	var list_order: int
	
	if turn_order >= current_turn:
		# If turn order is 4 and batman.turncount is 3, we want to return position 2
		list_order = turn_order - current_turn + 1 # The 1 turns it from 0based to 1based
	else:
		# 7 turntakers, we're order 2, and it's turn 3
			# So we turn 2+7=9, then 9-3=6, 6+1=7, to 7th position
		# Same scenario but it's turn 5?
			# We turn 2+7=9, then 9-5=4, 6+1=5, to 5th position
			# In +4 turns we'll be up (6, 7, 1, 2)
		list_order = (turn_order+max_turn_order) - current_turn + 1 # The 1 turns it from 0based to 1based
	
	return list_order
	pass

# Tweens!

func move_tt_offscreen():
	pass
