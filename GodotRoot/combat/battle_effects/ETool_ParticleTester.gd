extends Node2D
tool

export var start_particles: bool = false setget e_turn_on_particles
export var stop_particles: bool = false setget e_turn_off_particles

func e_turn_on_particles(tf: bool):
	if !tf: return
	if !Engine.editor_hint: return
	change_particles(true)
func e_turn_off_particles(tf: bool):
	if !tf: return
	if !Engine.editor_hint: return
	change_particles(false)


func change_particles(tf: bool):
	for p in get_children(): if p is Particles2D:
		p.emitting = tf
		if tf: p.restart()
	pass
