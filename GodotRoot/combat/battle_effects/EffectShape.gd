extends Node2D

var lifetime: float = -1.0
var effect_name: String = "" # Set BEFORE instancing

var intensity: float = 1.0 # Set before instancing; used by some things as a multiplier
var misc: String = ""

var par_node: Node2D

var persistent: bool = false # If true and has actor, it'll follow them until the actor dies or releases them
var actor: Actor = null # Set for non-temporary effects

# ---

func _ready():
	$sample.visible = false
	
	if !validate_or_die():
		die(true)
		return
	
	par_node = $ZPar.get_node(effect_name)
	gather_lifetime()
	
	prep_custom_details()
	
	play_effect()
	pass

func gather_lifetime():
	if persistent:
		lifetime = -1.0
		return
	
	for p in par_node.get_children(): if p is Particles2D:
		var local_lifetime: float = utils.get_max_lifetime_from_particle(p)
		if local_lifetime > lifetime:
			lifetime = local_lifetime
	
	lifetime += (1.0/60.0) # Bonus frame just in case
	pass

func prep_custom_details():
	match effect_name:
		"DamageBoom":
			for p in par_node.get_children(): if p is Particles2D:
				p.amount = intensity
	pass

func play_effect():
	for p in par_node.get_children(): if p is Particles2D:
		p.emitting = true
		p.restart()
	
	if lifetime > 0 and !persistent:
		$Timer.start(lifetime)
		yield($Timer, "timeout")
		die()
	pass

# -

func validate_or_die() -> bool:
	if !$ZPar.has_node(effect_name):
		return false
	
	if $ZPar.get_node(effect_name).get_child_count() == 0:
		return false
	
	for p in $ZPar.get_node(effect_name).get_children(): # SUCCESS if at least 1 child is a Particles2D
		if p is Particles2D:
			return true
	
	return false
	pass

func die(instant: bool = false):
	if !instant:
		yield(utils.yping("idle", self), "ping")
	
	visible = false
	get_parent().remove_child(self)
	queue_free()
	pass





