extends Node

# GameRoot's viable master scenes are stored in ITS script, not here!

# Battlefield
var res_battlecell = preload("res://combat/framing/BattleCell.tscn")

# Battle UI
var res_bui = preload("res://combat/battle_ui/BUI.tscn")
var res_hp_4  = preload("res://combat/battle_ui/components/Pip_4_Health.tscn")
var res_hp_6  = preload("res://combat/battle_ui/components/Pip_6_Health.tscn")
var res_hp_8  = preload("res://combat/battle_ui/components/Pip_8_Health.tscn")
var res_hp_10 = preload("res://combat/battle_ui/components/Pip_10_Health.tscn")
#var res_piphealth = preload("res://combat/battle_ui/HealthPip.tscn")
#var res_pipshield = preload("res://combat/battle_ui/ShieldPip.tscn")
#var res_pipbonusshield = preload("res://combat/battle_ui/BonusShieldPip.tscn")
#var res_pipaction = preload("res://combat/battle_ui/ActionPointPip.tscn")
#var res_pipbonusaction = preload("res://combat/battle_ui/BonusActionPointPip.tscn")

# Actors
var res_vfx_particle = preload("res://combat/battle_effects/VFXParticle.tscn")

var names_players: Array = ["Bard", "Knight", "Mage"]
var names_objects: Array = ["Rock"]
# Fallback is to assume enemy since that's most common
