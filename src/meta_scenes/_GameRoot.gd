extends Node2D

var fade_trans_time: float = 0.5
signal any_fade_completed()
signal fade_from_black_completed()
signal fade_to_black_completed()
signal scene_transition_completed()

signal new_scene_readied()

# ---

func _ready():
	utils.root = self
	$ViewportContainer/Viewport/BlackFader.modulate.a = 1.0
	$ViewportContainer/Viewport/BlackFader.visible = true
	blackfade(false)
	pass



# Scenes that we may load
var scene_battlefield = preload("res://combat/framing/BattleField.tscn")
var scene_landing = preload("res://src/meta_scenes/LandingPage.tscn")

func change_master_scene(to_scene: String):
	var varname: String = str("scene_",to_scene)
	if not varname in self:
		print("GAME ROOT: Error, ",to_scene," scene is not preloaded!")
		return
	
	blackfade(true)
	yield(self, "fade_to_black_completed")
	
	# We're valid, let's clear existing scenes then load!
	for child in $ViewportContainer/Viewport/SceneOwner.get_children():
		$ViewportContainer/Viewport/SceneOwner.remove_child(child)
		child.queue_free()
	
	var scene = get(varname).instance()
	$ViewportContainer/Viewport/SceneOwner.add_child(scene)
	print("GAME ROOT: Loaded new master scene [",to_scene,"] successfully!")
	emit_signal("new_scene_readied")
	
	blackfade(false)
	yield(self, "fade_to_black_completed")
	
	emit_signal("scene_transition_completed")
	pass

func blackfade(to_opaque: bool):
	utils.tween.interpolate_property($ViewportContainer/Viewport/BlackFader, "modulate:a", null, float(to_opaque), fade_trans_time, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	utils.tween.start()
	
	yield(utils.yt(fade_trans_time, self), "timeout")
	
	if to_opaque:
		emit_signal("fade_to_black_completed")
	else:
		emit_signal("fade_from_black_completed")
	emit_signal("any_fade_completed")
	pass
