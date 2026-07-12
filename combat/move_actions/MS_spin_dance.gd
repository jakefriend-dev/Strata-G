extends MoveAction

#var DIST: int = 3

# Only uncomment this method if you want to bypass "normal" variant loading
func LOAD_VARIANTS():
	actualized_variants.append(Vector2( 9,  9))
	actualized_variants.append(Vector2(-9, -9))
	pass

# First the check position relative to our actor, then ITS relative check position

var cw_set: Array = [
	[Vector2( 0, -1),    Vector2( 1,  0)],
	[Vector2( 1, -1),    Vector2( 0,  1)],
	[Vector2( 1,  0),    Vector2( 0,  1)],
	[Vector2( 1,  1),    Vector2(-1,  0)],
	[Vector2( 0,  1),    Vector2(-1,  0)],
	[Vector2(-1,  1),    Vector2( 0, -1)],
	[Vector2(-1,  0),    Vector2( 0, -1)],
	[Vector2(-1, -1),    Vector2( 1,  0)],
]

var ccw_set: Array = [
	[Vector2( 0, -1),    Vector2(-1,  0)],
	[Vector2( 1, -1),    Vector2(-1,  0)],
	[Vector2( 1,  0),    Vector2( 0, -1)],
	[Vector2( 1,  1),    Vector2( 0, -1)],
	[Vector2( 0,  1),    Vector2( 1,  0)],
	[Vector2(-1,  1),    Vector2( 1,  0)],
	[Vector2(-1,  0),    Vector2( 0,  1)],
	[Vector2(-1, -1),    Vector2( 0,  1)],
]


func PREVIEW():
	var model_cw: bool = (batman.loaded_variant == Vector2( 9,  9))
	var sets: Array
	if model_cw:
		sets = cw_set.duplicate(true)
	else:
		sets = ccw_set.duplicate(true)
	
	strife.reset_CAMs()
	strife.set_CAM_admin("pushes_heavy", true)
	
	for set in sets:
		var origin: Vector2 = actor.coord + set[0]
		var reldest: Vector2 = set[1]
		strife.store_CAMstep_by_coord(origin, reldest)
	
	var results: Dictionary = strife.get_CAM_results() # Also runs validation!
	if results.empty():
		error_text = "No actors in range"
		return
	
	passfail = true
	
	for key in results:
		var victim: Actor = results[key]["actor"]
		if results[key]["outcome"] == "success":
			var relvec: Vector2 = results[key]["relvec"]
			var target_dest: Vector2 = victim.coord + relvec
			add_actor(victim, ROWS.NEUTRAL)
			add_arrow(victim.coord, target_dest, ROWS.NEUTRAL)
		else:
			add_actor(victim, ROWS.ERROR)
	pass

func ACT():
#	# Shoot a target in your line-of-sight; higher damage per tile travelled
#	var victim: Actor = get_first_actor_by_MPD_type(ROWS.BAD)
#
#	if utils.actorpass(victim):
#		strife.damage_actor_at_coord(actor, victim.coord, 2*batman.BASE_HP_FACTOR, ["piercing"])
#		strife.quick_vfx(victim, "spark_burst")
	
	end_action()
	pass

