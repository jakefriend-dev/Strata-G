extends Node2D

onready var tween: Tween = get_node("Tween")
#var tweenqueue: Array = []
#var tweenlock: bool = false
var last_called_frame: int = -1
var scoot_time: float = 0.25
onready var halfscoot_time: float = scoot_time/2.0
var display_minimum: int = 1 # Needs to match Turntaker's enums; use 2 for testing only! Default 1 for portrait only
var max_list_qty_inclusive: int = 9

# REFERENCE TO BATMAN.TURNQUEUE ONLY
#var turnqueue: Array = [
	# Full of turndata dictionaries, already sorted in order!
	# Assumes all turntakers are ALIVE
		# actor						Null if no longer relevant, otherwise an Actor
		# init						Float; The original initiative roll (eg. 5.72013)
		# has_finished_turn			Bool that fires once its turn is complete
		# display_name					Direct from the actor's display_name
		# numerated_name			As "Doggo 1" with a space and all, even if there's only 1
		# numeration				Int; the 1 in Doggo 1
		# turncount_of_this_actor	Int; 1 by default and a boss could have 2 or 3
		# turnpos					Int; managed by batman but 
#]

var y_offscreen: float = 28.0
onready var tt_par: Node2D = $All_TT

##var back_turntaker: Node2D # Just to track the *previous* front_turntaker
#var active_turntakers: Array = []
## ^ Simple array holding refs to ALL turntaker scenes, in order!
## If a TT here is missing from batman's TQ, it gets removed/destroyed; vice versa for adding
#
#var exiting_tts: Array = [] # Queued to be deleted
#var entering_tts: Array = [] # Queued to be brought in

var front_turntaker: Node2D
var all_turntakers: Array = [] # This is the NEW approach/attempt, where TTs simply are in here from generation until they are removed!

# ---

func _ready():
	batman.connect("turnqueue_constructed", self, "on_turnqueue_construction")
	batman.connect("turnqueue_updated", self, "on_turnqueue_update")
	pass

func on_turnqueue_construction():
#	print("TT WINDOW: on_turnqueue_construction()")
	
	for ttd in batman.turnqueue: if ttd is Dictionary:
		add_new_turntaker(ttd)
	
	for tt in all_turntakers:
#	for tt in entering_tts:
		if tt.turn_order == 1:
			front_turntaker = tt
	
	refresh_tt_values_and_activeness()
#	do_full_update() # We build the scenes offscreen, then let natural turn cycling bring them down
	pass

func add_new_turntaker(ttd: Dictionary): # Instances scene OFFscreen, so there's something to tween
	var tt: Node2D = loader.res_turntaker.instance()
	
#	tt.set("actor", ttd["actor"])
	var turn_order: int = ttd["turnpos"]
	tt.set("turn_order", turn_order)
	tt.set("position", get_list_pos(turn_order, true))
#	if turn_order_to_list_order(turn_order) == 1:
#		tt.set("vis_state", tt.STATUS)
#	else:
	tt.set("vis_state", display_minimum)
	tt.set("linked_ttd", ttd)
	tt.set("name", str(ttd["numerated_name"],": T",ttd["turncount_of_this_actor"]))
	
#	if !entering_tts.has(tt):
#		entering_tts.append(tt)
	if !all_turntakers.has(tt):
		all_turntakers.append(tt)
#	active_turntakers.append(tt)
	tt_par.add_child(tt)
	tt.set_actor(ttd["actor"])
	pass

func remove_turntaker(tt: Node2D):
	if all_turntakers.has(tt):
		all_turntakers.erase(tt)
	yield(utils.yt(halfscoot_time, self), "timeout")
	tt.get_parent().remove_child(tt)
	tt.queue_free()
	pass

func on_turnqueue_update():
#	print("TT WINDOW: on_turnqueue_update()")
	do_full_update()
	pass

# ---

func do_full_update(): # Always assumes batman.turnqueue is fully up to date!
#	print("TT WINDOW: do_full_update()")
	refresh_tt_values_and_activeness()
	animate_position_changes()
	
	pass

func refresh_tt_values_and_activeness():
	
	# Updates existing (and checks exiting / preps to remove)
	for tt in all_turntakers: if !tt.no_longer_valid:
		
		# Skip anything invalid...
		if !utils.valid(tt):
			tt.no_longer_valid = true
			continue
		if !batman.turnqueue.has(tt.linked_ttd) or !utils.actorpass(tt.actor):
			tt.no_longer_valid = true
			continue
		
		# ... and update anything NOT invalid!
		tt.turn_order = tt.linked_ttd["turnpos"]
		continue
	
	# Adds new
	for ttd in batman.turnqueue: if ttd is Dictionary:
		var has_match: bool = false
		for tt in all_turntakers:
			if tt.linked_ttd == ttd:
				has_match = true
				break
		if !has_match:
			print("Manually adding 1 more turntaker bc no match in all_turntakers")
			add_new_turntaker(ttd) # Also adds to entering list (not active, yet)
	
	pass

func animate_position_changes():
	# In THIS iteration, all we care about is:
		# 1. Everyone who is onscreen and shouldn't be (or front_turntaker who isn't the front anymore) goes offscreen
		# 2. Everyone who is onscreen and SHOULD be moves to their new positions
		# 3. Everyone who is OFFscreen and shouldn't be re-enters to their intended positions
	# The main difference is we should not be blathering about the different between entering vs active TTs anymore, it's super unnecessarily confusing...
	
	var called_frame: int = get_tree().get_frame()
	if called_frame == last_called_frame: return
	last_called_frame = called_frame
	
	tween.remove_all()
	
	var final_vis_list: int = max_list_qty_inclusive
	if batman.turnqueue.size() < final_vis_list: final_vis_list = batman.turnqueue.size()
	
	
	
	# First, move things upwards if needed:
	var upmovers: Array = []
	for tt in all_turntakers:
		if tt.position.y >= 0: # Ignore anyone already offscreen
			if tt.no_longer_valid:
				upmovers.append(tt)
				continue
			var list_order: int = turn_order_to_list_order(tt.turn_order)
			if tt == front_turntaker:
				if list_order != 1:
					upmovers.append(tt)
					continue
			if list_order > final_vis_list: # Simple as 'if you have no business being in the 9 visible slots, get lost!'
				upmovers.append(tt)
				continue
		continue
	front_turntaker = null
	
	if !upmovers.empty():
		for tt in upmovers:
			tween.interpolate_property(tt, "position", null, Vector2(tt.position.x, -y_offscreen), scoot_time, Tween.TRANS_QUINT, Tween.EASE_OUT)
			tt.vis_state = display_minimum
			tt.update_visible()
		tween.start()
		yield(utils.yt(halfscoot_time, self), "timeout")
		if last_called_frame != called_frame: return # Implies a subsequent call has overwritten us
	
	
	
	# Ready for the sideway reposition movement now!
	var sidemovers: Array = []
	for tt in all_turntakers:
		if is_zero_approx(tt.position.y): # Ignore anyone already offscreen
			var target_position: Vector2 = get_list_pos(tt.turn_order)
			if !target_position.is_equal_approx(tt.position):
				sidemovers.append(tt)
				continue
		continue
	
	if !sidemovers.empty():
		for tt in sidemovers:
			tween.interpolate_property(tt, "position", null, get_list_pos(tt.turn_order), scoot_time, Tween.TRANS_QUINT, Tween.EASE_OUT)
			tt.vis_state = display_minimum
			tt.update_visible()
		tween.start()
		yield(utils.yt(halfscoot_time, self), "timeout")
		if last_called_frame != called_frame: return # Implies a subsequent call has overwritten us
	
	
	
	# Finally, the downwards enter-ers!
	var downmovers: Array = []
	for tt in all_turntakers: if !tt.no_longer_valid:
		if tt.position.y < 0: # Only consider TTs *already* offscreen
			var list_order: int = turn_order_to_list_order(tt.turn_order)
			if list_order <= final_vis_list:
				downmovers.append(tt)
				continue
		continue
	
	if !downmovers.empty():
		for tt in downmovers:
			tween.interpolate_property(tt, "position", get_list_pos(tt.turn_order, true), get_list_pos(tt.turn_order), scoot_time, Tween.TRANS_QUINT, Tween.EASE_OUT)
			tt.vis_state = display_minimum
			tt.update_visible()
		tween.start()
		yield(utils.yt(halfscoot_time, self), "timeout")
		if last_called_frame != called_frame: return # Implies a subsequent call has overwritten us
	
	
	
	
	# All done! Wrap it up
	for tt in all_turntakers: # These should all be validated prior to this point
		var list_order: int = turn_order_to_list_order(tt.turn_order)
		if list_order == 1:
			front_turntaker = tt # Just for future tracking
			front_turntaker.vis_state = front_turntaker.STATUS
			front_turntaker.refresh()
	
	if !utils.valid(front_turntaker):
		print("TT WINDOW: Error, we ended an animate function with NO new front_turntaker!")
	
	if called_frame == get_tree().get_frame():
		# Just to make sure we never emit the signal without a delay of at least a frame!
		yield(utils.yt(0.01, self), "timeout")
		if last_called_frame != called_frame: return # Implies a subsequent call has overwritten us
	
	for tt in all_turntakers: if tt.no_longer_valid:
		remove_turntaker(tt)
	batman.emit_signal("turnwindow_anims_complete")
#	tweenlock = false
	
	pass

# Positions

func get_list_pos(turn_order: int, be_offscreen: bool = false) -> Vector2:
	
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
