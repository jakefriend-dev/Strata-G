extends Node

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

enum {UNDEFINED, FRAME_VIS, FRAME_PHYS, FRAME_IDLE, GAME_SETUP, GAME_RELEASED} # Needs to match the list in YPing!
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
		"game_setup":
			yping.set("type", GAME_SETUP)
		"game_ready":
			yping.set("type", GAME_RELEASED)

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
