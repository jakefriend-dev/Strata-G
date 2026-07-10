extends Node2D

func _ready():
	utils.root = self
	pass

# Scenes that we may load
var scene_battlefield = preload("res://combat/framing/BattleField.tscn")
var scene_landing = preload("res://src/meta_scenes/LandingPage.tscn")

func change_master_scene(to_scene: String):
	var varname: String = str("scene_",to_scene)
	if not varname in self:
		print("GAME ROOT: Error, ",to_scene," scene is not preloaded!")
		return
	
	# We're valid, let's clear existing scenes then load!
	for child in $ViewportContainer/Viewport/SceneOwner.get_children():
		$ViewportContainer/Viewport/SceneOwner.remove_child(child)
		child.queue_free()
	
	var scene = get(varname).instance()
	$ViewportContainer/Viewport/SceneOwner.add_child(scene)
	print("GAME ROOT: Loaded new master scene [",to_scene,"] successfully!")
	pass
