extends MoveAction


func ONE_TIME_SETUP():
	print("Melee Counter: ONE_TIME_SETUP()!")
	actor.connect("on_strife_any_contact_by_external", self, "REACT")
	pass

func PREVIEW():
	add_actor(actor, ROWS.GOOD)
	pass

func ACT():
	
	strife.quick_vfx(actor, "quick_good")
	actor.start_status("melee_counter", "Counter Stance", "good", 1, false)
	
	end_turn()
	pass

func REACT(combat_package: Dictionary):
	print("Melee Counter: REACT()!")
	if !actor.check_status("melee_counter"): return
	print("a")
	
	if !combat_package.has("attacker_is_real"): return
	print("b")
	if !combat_package["attacker_is_real"]: return
	print("c")
	var attacker: Actor = combat_package["attacker"]
	print("d")
	if !utils.actorpass(attacker): return
	print("e")
	
	var offsets: Array = [
		Vector2.ZERO,
		Vector2.ZERO + Vector2.UP,
		Vector2.ZERO + Vector2.DOWN,
		actor.my_facing,
		actor.my_facing + Vector2.UP,
		actor.my_facing + Vector2.DOWN
	]
	
	for offset in offsets:
		var check_cell: Vector2 = offset + actor.coord
		if attacker.coord == check_cell:
			strife.do_impact_damage(actor, attacker, actor.dmg(base_damage))
			strife.quick_vfx(attacker, "melee_slice")
			return
	print("f")
	pass










