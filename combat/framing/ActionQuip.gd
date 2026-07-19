extends Node2D

var text: String = ""
var prepped_to_delete: bool = false
var fullscreen_travel_time: float = 2.0
var fade_predelay: float = 0.375

var start_scale: float = 0.85
var signalled_out: bool = false

# ---

func _ready():
	$Main.text = text
	$Main/Shadow.text = text
	scale = Vector2(start_scale, start_scale)
	
	utils.tween.interpolate_property(self, "scale", null, Vector2(1, 1), 0.125, Tween.TRANS_CIRC, Tween.EASE_OUT)
	
	utils.tween.interpolate_property(self, "position:y", null, position.y-360.0, fullscreen_travel_time, Tween.TRANS_QUINT, Tween.EASE_IN, 0.375)
	
	utils.tween.interpolate_property($Main, "modulate:a", null, 0.0, fullscreen_travel_time/2.0, Tween.TRANS_CIRC, Tween.EASE_IN, fade_predelay)
	utils.tween.interpolate_property($Main/Shadow, "modulate:a", null, 0.0, fullscreen_travel_time/2.0, Tween.TRANS_CIRC, Tween.EASE_IN, fade_predelay)
	
	utils.tween.start()
	pass

func _process(_d):
	if prepped_to_delete: return
	
	if global_position.y < 0:
		delete()
		return
	
	if !signalled_out:
		if $Main.modulate.a < 0.9:
			print("flag1")
			if am_i_the_last_quip():
				batman.emit_signal("all_quips_cleared")
			signalled_out = true
	
	if is_zero_approx($Main.modulate.a):
		delete()
		return
	pass

func am_i_the_last_quip() -> bool:
	if get_parent().get_child_count() == 1:
		return true
	
	for child in get_parent().get_children():
		if child == self: continue
		if !child.signalled_out:
			return false
	
	return true

func delete():
	prepped_to_delete = true
	visible = false
	
	if !signalled_out:
		print("flag2")
		if am_i_the_last_quip():
			batman.emit_signal("all_quips_cleared")
		signalled_out = true
	
	get_parent().remove_child(self)
	queue_free()
	pass
