extends Node

var tween: Tween

# ---

# -

func _ready():
	tween = Tween.new()
	add_child(tween)
	pass


func does_file_exist(path):
	var directory = Directory.new()
	var tf = directory.file_exists(path)
	
	# Engine filechecker
	if !tf:
		tf = directory.file_exists(str(path, ".import"))
		
		if tf:
#			print("UTILS: Error at the original position; found at the import position")
			pass
		
	return tf

func yt(dur: float, caller, disrespect_pause: bool = false) -> YTimer:

	var ytimer = YTimer.new()
	ytimer.set("wait_time", dur)
	ytimer.set("caller", caller)
	ytimer.set("callername", caller.name)
	add_child(ytimer)

	if disrespect_pause:
		ytimer.pause_mode = Node.PAUSE_MODE_PROCESS
	else:
		ytimer.pause_mode = Node.PAUSE_MODE_STOP

	ytimer.start()
	return ytimer

enum {UNDEFINED, FRAME_VIS, FRAME_PHYS, FRAME_IDLE}#, GAME_SETUP, GAME_RELEASED} # Needs to match the list in YPing!
func yping(type: String, caller, disrespect_pause: bool = false) -> YPing:

	var yping = YPing.new()
	yping.set("caller", caller)
	yping.set("callername", caller.name)
	yping.set("ignore_pause", disrespect_pause)

	match type:
		"vis":
			yping.set("type", FRAME_VIS)
		"phys":
			yping.set("type", FRAME_PHYS)
		"idle":
			yping.set("type", FRAME_IDLE)
#		"game_setup":
#			yping.set("type", GAME_SETUP)
#		"game_ready":
#			yping.set("type", GAME_RELEASED)

	add_child(yping)

	return yping
	pass

func valid(who: Node) -> bool:
	if who == null:
		return false
	if !who.is_inside_tree():
		return false
	if !is_instance_valid(who):
		return false
	
	return true
	pass

func coin_flip() -> bool:
	return rand_range(0.00, 0.99) < 0.5

func negchance() -> float:
	if coin_flip():
		return -1.0
	return 1.0

func negchance_int() -> int:
	if coin_flip():
		return -1
	return 1

func get_rand_vecdir() -> Vector2:
	var opts: Array = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	opts.shuffle()
	return opts[0]

func get_max_lifetime_from_particle(p: Particles2D) -> float:
#	if not p.process_material is ParticlesMaterial: return -1.0
#
#	var pm: ParticlesMaterial = p.process_material
	# We don't have to worry about lifetime randomness actually, because that only SHORTENS lifetime
	
	var cycle_length: float = p.lifetime
	cycle_length /= p.speed_scale
	
	# Now we have the 'normal' lifetime - but we need to factor in the delay caused by explosiveness
	
	# 1 ex == concurrent, 0 ex == perfectly evenly spaced
	# Therefore 4 particles at 0.0 explosiveness would be 0%/25%/50%/75%
		# And the 'start' delay would need to be 75% of a whole cycle
	# Therefore 4 particles at 0.5 explosiveness would be 0%/12.5%/25%/37.5%
		# And the 'start' delay would need to be 37.5% of a whole cycle
	
	var a: float = float(p.amount)
	var delta: float = cycle_length/a
	delta *= p.explosiveness
	
	# Use that to add against the one-cycle lifetime!
	var delay: float = delta * (a-1.0) # Zero if 1a for 0/1; three if 4a for 3/4
	var lifetime: float = cycle_length + delay
	
	return lifetime
	pass




