extends MoveAction

var motion: Vector2
var attacker: Actor
var attacker_is_real: bool

var action_type: String = ""
var knockback_damage: int = 0

var flags: Array = []
var is_quiet: bool = false

# ---

func reset_before_feeding_data():
	motion = Vector2.ZERO
	attacker = null
	attacker_is_real = false
	is_quiet = false
	action_type = ""
	knockback_damage = 0
	flags = []
	pass

# -

#func PREVIEW(): # All our validation is handled by Strife.master_do_motion!
#	pass

func ACT():
	match action_type:
		"recoil_in_place":
			ACT_recoil_in_place()
			return
		"push_collision":
			ACT_push_collision()
			return
		"push_smooth":
			ACT_push_smooth()
			return
	end_action()
	pass

func ACT_recoil_in_place():
#	hotcollide_in_place
	
	end_action()
	pass

func ACT_push_collision():
#	hotpush_n_collide
	
	end_action()
	pass

func ACT_push_smooth():
#	hotpushed
	
	end_action()
	pass





#do_impact_damage(attacker, defender, knockback_damage, flags)
