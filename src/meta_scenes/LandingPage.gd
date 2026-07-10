extends Node2D


func _ready():
	batman.combatstate = batman.C_OOC
	batman.flush_all_combat_details()
	pass
