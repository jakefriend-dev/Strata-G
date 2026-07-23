extends MoveAction

var motion: Vector2
var attacker: Actor
var attacker_is_real: bool

var action_type: String = ""
var knockback_damage: int = 0 # This is already set to actual unit values (NOT pip values)!

var flags: Array = []
var is_quiet: bool = false
var unit_dur: float

# ---

func reset_before_feeding_data():
	motion = Vector2.ZERO
	attacker = null
	attacker_is_real = false
	is_quiet = false
	action_type = ""
	knockback_damage = 0
	flags = []
	unit_dur = actor.tile_walk_speed
	pass

# -

#func PREVIEW(): # All our validation is handled by Strife.master_do_motion!
#	pass

func ACT():
	
	var dur: float = get_real_dur()
	var exact_coord: Vector2 = actor.coord + manual_variant
	
	match action_type:
		"recoil_in_place":
			print("recoil_in_place -> hotcollide_in_place!")
			actor.hotcollide_in_place(attacker, manual_variant, dur, knockback_damage)
		"push_collision":
			print("push_collision -> hotpush_n_collide!")
			actor.hotpush_n_collide(attacker, manual_variant, dur, knockback_damage)
		"push_smooth":
			print("push_smooth -> hotpushed!")
			actor.hotpushed(exact_coord, dur)
	
	yield(utils.yt(dur, actor), "timeout")
	if !batman.is_my_action(actor): return
	
	end_action()
	pass

# -

# This is used both internally and externally, for determining dynamic yields!
func get_real_dur() -> float:
	var tile_qty: float = round(manual_variant.length())
	var dur: float = unit_dur * tile_qty
	return dur
	pass




#do_impact_damage(attacker, defender, knockback_damage, flags)
