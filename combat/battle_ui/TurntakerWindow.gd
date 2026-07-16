extends Node2D

onready var tween: Tween = get_node("Tween")
var tweenqueue: Array = []
var tweenlock: bool = false
var scoot_time: float = 0.25
var display_minimum: int = 2 # Needs to match Turntaker's enums; use this for testing only! Default 1 for portrait only
var max_list_qty_inclusive: int = 9

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

var front_turntaker: Node2D
#var back_turntaker: Node2D # Just to track the *previous* front_turntaker
var active_turntakers: Array = []
# ^ Simple array holding refs to ALL turntaker scenes, in order!
# If a TT here is missing from batman's TQ, it gets removed/destroyed; vice versa for adding

var exiting_tts: Array = [] # Queued to be deleted
var entering_tts: Array = [] # Queued to be brought in

# ---

func _ready():
	batman.connect("turnqueue_constructed", self, "on_turnqueue_construction")
	batman.connect("turnqueue_updated", self, "on_turnqueue_update")
	pass

func on_turnqueue_construction():
	print("TT WINDOW: on_turnqueue_construction()")
	
	for ttd in batman.turnqueue: if ttd is Dictionary:
		add_new_turntaker(ttd)
	
	for tt in entering_tts:
		if tt.turn_order == 1:
			front_turntaker = tt
	
	refresh_tt_values_and_activeness()
#	do_full_update()
	pass

func add_new_turntaker(ttd: Dictionary): # Instances scene OFFscreen, so there's something to tween
	var tt: Node2D = loader.res_turntaker.instance()
	
#	tt.set("actor", ttd["actor"])
	var turn_order: int = ttd["turnpos"]
	tt.set("turn_order", turn_order)
	tt.set("position", get_list_pos(turn_order, true))
	if turn_order_to_list_order(turn_order) == 1:
		tt.set("vis_state", tt.STATUS)
	else:
		tt.set("vis_state", display_minimum)
	tt.set("linked_ttd", ttd)
	tt.set("name", str(ttd["numerated_name"],": T",ttd["turncount_of_this_actor"]))
	
	if !entering_tts.has(tt):
		entering_tts.append(tt)
#	active_turntakers.append(tt)
	tt_par.add_child(tt)
	tt.set_actor(ttd["actor"])
	pass

func remove_turntaker(tt: Node2D):
#	if active_turntakers.has(tt):
#		active_turntakers.erase(tt)
	if exiting_tts.has(tt):
		exiting_tts.erase(tt)
	tt.get_parent().remove_child(tt)
	tt.queue_free()
	pass

func on_turnqueue_update():
	print("TT WINDOW: on_turnqueue_update()")
	do_full_update()
	pass

# ---

func do_full_update(): # Always assumes batman.turnqueue is fully up to date!
	print("TT WINDOW: do_full_update()")
	refresh_tt_values_and_activeness()
	# Our entering/exiting should be set up after this ^
	
	animate_position_changes()
	
#	for tt in active_turntakers:
#		tt.position = get_pos(tt.turn_order)
#		if turn_order_to_list_order(tt.turn_order) == 1:
#			tt.vis_state = tt.STATUS
#		else:
#			tt.vis_state = display_minimum
#		tt.update_visible()
	pass

func refresh_tt_values_and_activeness():
	
	# Updates existing (and checks exiting / preps to remove)
	for tt in active_turntakers:
		if !utils.valid(tt):
			if !exiting_tts.has(tt):
				exiting_tts.append(tt)
			continue
		if !batman.turnqueue.has(tt.linked_ttd) or !utils.actorpass(tt.actor):
			if !exiting_tts.has(tt):
				exiting_tts.append(tt)
			continue
		tt.turn_order = tt.linked_ttd["turnpos"]
	for tt in exiting_tts:
		if active_turntakers.has(tt):
			active_turntakers.erase(tt)
	if !exiting_tts.empty():
		print("Exiting TTs: ",exiting_tts)
	
	#
	
	# Adds new
	for ttd in batman.turnqueue: if ttd is Dictionary:
		var has_match: bool = false
		for tt in active_turntakers:
			if tt.linked_ttd == ttd:
				has_match = true
				break
		if !has_match: for tt in entering_tts:
			if tt.linked_ttd == ttd:
				has_match = true
				break
		if !has_match:
			print("Manually adding 1 more turntaker bc no match in active_turntakers OR entering_tts")
			add_new_turntaker(ttd) # Also adds to entering list (not active, yet)
	
	#
	
#	# Removes exiting
#	for tt in exiting_tts:
#		remove_turntaker(tt)
	pass

func animate_position_changes():
	if tweenlock: return
	
	var back_turntaker: Node2D = null # Clear, since this is only used in the tweening followup
	tweenlock = true
	tween.remove_all()
	var final_vis_list: int = max_list_qty_inclusive
	if batman.turnqueue.size() < final_vis_list: final_vis_list = batman.turnqueue.size()
	
	
	
	# All deleted turns should move up to ready for destruction
	var offscreen_check: bool = false
	if !exiting_tts.empty():
		offscreen_check = true
		for tt in exiting_tts:
			tween.interpolate_property(tt, "position", null, Vector2(tt.position.x, -y_offscreen), scoot_time, Tween.TRANS_QUINT, Tween.EASE_OUT)
			tt.vis_state = display_minimum
			tt.update_visible()
	
	# This should include whoever the current turntaker is moving up too
	# (It's expected that we ALREADY KNOW who the prior front turntaker is at this point)
	if utils.valid(front_turntaker):
		var list_order: int = turn_order_to_list_order(front_turntaker.turn_order)
		if list_order != 1:
			offscreen_check = true
			tween.interpolate_property(front_turntaker, "position", null, Vector2(front_turntaker.position.x, -26), scoot_time, Tween.TRANS_QUINT, Tween.EASE_OUT)
			front_turntaker.vis_state = display_minimum
			front_turntaker.update_visible()
	
	if offscreen_check:
		tween.start()
		yield(utils.yt(scoot_time, self), "timeout")
		
		for tt in exiting_tts:
			remove_turntaker(tt)
		
		if utils.valid(front_turntaker):
			var list_order: int = turn_order_to_list_order(front_turntaker.turn_order)
			if list_order != 1:
				# Snap the position so we tween in from a clean spot
				front_turntaker.position = get_list_pos(front_turntaker.turn_order, true)
	front_turntaker = null
	# At/after this point, we need to know who the 'new' front_turntaker is based on list order. We'll determine back_turntaker later as whoever is NOW in 9th place.
	
	
	
	# Then we update TT positions against turns, *knowing* there could be a new TT ready to add
	var repo_check: bool = false
	for tt in active_turntakers: # These should all be validated prior to this point
		var list_order: int = turn_order_to_list_order(tt.turn_order)
		if list_order == final_vis_list: # Not an elif because there's a fringe scenario where only one turntaker exists??
			back_turntaker = tt
			tt.vis_state = display_minimum
			tt.update_visible()
			if tt.position.y < 0: # If offscreen... leave for later!
#				tt.position = get_list_pos(final_vis_list, true) #...prepare to go onscreen at the right X position!
#				# But we don't want to manipulate its X position in THIS step
				continue
		
		if list_order > max_list_qty_inclusive: # Only bother with the ones that will actually be onscreen!
			tt.position = get_list_pos(9, true)
			continue
		
		var target_pos: Vector2 = get_list_pos(tt.turn_order)
		if tt.position != target_pos:
			repo_check = true
			tween.interpolate_property(tt, "position", null, get_list_pos(tt.turn_order), scoot_time, Tween.TRANS_QUINT, Tween.EASE_OUT)
		
		tt.vis_state = display_minimum
		tt.update_visible()
		continue
	
	if repo_check:
		tween.start()
		yield(utils.yt(scoot_time, self), "timeout")
	
	
	
	# Then we make the new TTs enter (the scenes are already created, just offscreen)
	# This should include whoever the previous turntaker was moving down
	var entry_check: bool = false
	if back_turntaker != null: # (It shouldn't be!!)
		var list_order = turn_order_to_list_order(back_turntaker.turn_order)
		if back_turntaker.position.y < 0: # If offscreen...
			entry_check = true
			tween.interpolate_property(back_turntaker, "position", get_list_pos(back_turntaker.turn_order, true), get_list_pos(back_turntaker.turn_order), scoot_time, Tween.TRANS_QUINT, Tween.EASE_OUT)
	
	for tt in entering_tts:
		var list_order = turn_order_to_list_order(tt.turn_order)
		if list_order <= max_list_qty_inclusive:
			entry_check = true
			tween.interpolate_property(tt, "position", get_list_pos(tt.turn_order, true), get_list_pos(tt.turn_order), scoot_time, Tween.TRANS_QUINT, Tween.EASE_OUT)
		if !active_turntakers.has(tt):
			active_turntakers.append(tt) # Move them to the regular list either way; they had their chance!
	entering_tts.clear()
	
	if entry_check:
		tween.start()
		yield(utils.yt(scoot_time, self), "timeout")
	
	
	
	# All done! Wrap it up
	for tt in active_turntakers: # These should all be validated prior to this point
		var list_order: int = turn_order_to_list_order(tt.turn_order)
		if list_order == 1:
			front_turntaker = tt # Just for future tracking
	
	if !utils.valid(front_turntaker):
		print("TT WINDOW: Error, we ended an animate function with NO new front_turntaker!")
	
	if !entry_check and !repo_check and !offscreen_check:
		# Just to make sure we never emit the signal without a delay of at least a frame
		yield(utils.yt(0.01, self), "timeout")
	
	batman.emit_signal("turnwindow_anims_complete")
	tweenlock = false
	pass

func NEW_animate_position_changes():
	# In THIS iteration, all we care about is:
		# 1. Everyone who is onscreen and shouldn't be (or front_turntaker who isn't the front anymore) goes offscreen
		# 2. Everyone who is onscreen and SHOULD be moves to their new positions
		# 3. Everyone who is OFFscreen and shouldn't be re-enters to their intended positions
	# The main difference is we should not be blathering about the different between entering vs active TTs anymore, it's super unnecessarily confusing...
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
