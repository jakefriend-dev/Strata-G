extends Node2D

var lifetime: float = -1.0
var vfx_name: String = "" # Set BEFORE instancing

var intensity: float = 1.0 # Set before instancing; used by some things as a multiplier
var misc: String = ""

var par_node: Node2D

var persistent: bool = false # If true and has actor, it'll follow them until the actor dies or releases them
var actor: Actor = null # Set for non-temporary effects

var readied: bool = false
var dying: bool = false
var final_death: bool = false

# ---

func _ready():
	$sample.visible = false
	
	if !validate_or_die():
		die(true)
		return
	
	par_node = $ZPar.get_node(vfx_name)
	gather_lifetime()
	
	prep_custom_details()
	
	play_effect()
	readied = true
	pass

func validate_or_die() -> bool:
	if !$ZPar.has_node(vfx_name):
		return false
	
	if $ZPar.get_node(vfx_name).get_child_count() == 0:
		return false
	
	for p in $ZPar.get_node(vfx_name).get_children(): # SUCCESS if at least 1 child is a Particles2D
		if p is Particles2D:
			return true
	
	return false
	pass

func gather_lifetime():
	for p in par_node.get_children(): if p is Particles2D:
		var local_lifetime: float = utils.get_max_lifetime_from_particle(p)
		if local_lifetime > lifetime:
			lifetime = local_lifetime
	
	lifetime += (1.0/60.0) # Bonus frame just in case
	pass

func prep_custom_details():
	match vfx_name:
		"damage":
			for p in par_node.get_children(): if p is Particles2D:
				p.amount = intensity
		"heal":
			for p in par_node.get_children(): if p is Particles2D:
				p.amount = intensity
	pass

func play_effect():
	for p in par_node.get_children(): if p is Particles2D:
		p.emitting = true
		p.restart()
	
	if lifetime > 0 and !persistent:
		dying = true
		$Timer.start(lifetime)
		yield($Timer, "timeout")
		die()
	pass

# -

func end_persistent():
	for p in par_node.get_children(): if p is Particles2D:
		p.emitting = false
	
	if lifetime > 0:
		$Timer.start(lifetime)
		yield($Timer, "timeout")
	die()
	pass

func quick_clear():
	for p in par_node.get_children(): if p is Particles2D:
		p.emitting = false
	
	dying = true
	
	var dur: float = 12.0/60.0
	
	utils.tween.interpolate_property(self, "modulate:a", null, 0.0, dur, Tween.TRANS_CUBIC, Tween.EASE_IN)
	utils.tween.start()
	
	yield(utils.yt(dur, self), "timeout")
	die()
	pass

func die(instant: bool = false):
	# No double-calls!
	if final_death: return
	final_death = true
	
	if !instant:
		yield(utils.yping("idle", self), "ping")
	
	visible = false
	get_parent().remove_child(self)
	queue_free()
	pass

# ---

func _process(_d): # Basic position tracking, for persistent effects only
	if !readied: return
	if dying: return
	if !persistent: return
	if !utils.valid(actor): return
	
	var apos: Vector2 = actor.position
	apos.y -= actor.z
	if position != apos:
		position = apos
	pass



