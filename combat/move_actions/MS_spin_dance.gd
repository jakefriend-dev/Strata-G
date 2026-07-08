extends MoveAction

#var DIST: int = 3

# Only uncomment this method if you want to bypass "normal" variant loading
#func LOAD_VARIANTS():
#	for vec in plausible_variants:
#		if batman.grid_actors.has_cellv(actor.coord + vec + Vector2(DIST, 0)):
#			actualized_variants.append(vec)
#	pass

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
	
	var model_cw: bool = (batman.loaded_variant == Vector2.RIGHT)
	var sets: Array
	if model_cw:
		sets = cw_set.duplicate(true)
	else:
		sets = ccw_set.duplicate(true)
	
	var blocked_positions: Array = [] # Relative to this actor
	
	# On the first pass, we should see which units cannot move - this blocks their tile, AND the tile which would move to that position in theirs
	
	# After that, we will need to loop BACKWARDS through the cycle checking those blocked positions to see if that blocks another actor....
	
	# this is getting complicated and idk if it is overall a good idea haha
	# but let's try a little more...
	
	
	var check_vector: Vector2 = batman.loaded_variant
	
	var unoccupieds: Array = support.list_all_unoccupied_tiles_in_dir(actor.coord, check_vector)
	if !unoccupieds.empty():
		add_arrow(actor.coord, unoccupieds.back(), ROWS.PASS)
	
	var victim: Actor = support.find_nearest_actor_in_dir(actor.coord, check_vector)
	if !utils.actorpass(victim): return
	
	add_actor(victim, ROWS.BAD)
	passfail = true
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

