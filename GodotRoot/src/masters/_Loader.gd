extends Node

# Battlefield
var res_battlecell = preload("res://combat/framing/BattleCell.tscn")

# Battle UI
var res_bui = preload("res://combat/BUI.tscn")
var res_piphealth = preload("res://combat/HealthPip.tscn")
var res_pipshield = preload("res://combat/ShieldPip.tscn")
var res_pipbonusshield = preload("res://combat/BonusShieldPip.tscn")
var res_pipaction = preload("res://combat/ActionPointPip.tscn")
var res_pipbonusaction = preload("res://combat/BonusActionPointPip.tscn")

# Actors
var res_lib_helper = preload("res://src/actors/action_libraries/ALib1_Helper.gd")
var res_lib_general = preload("res://src/actors/action_libraries/ALib2_General.gd")
var res_lib_player = preload("res://src/actors/action_libraries/ALib3_Player.gd")
var res_lib_enemy = preload("res://src/actors/action_libraries/ALib4_Enemy.gd")
var res_effect_particle = preload("res://combat/battle_effects/EffectParticle.tscn")
