extends Node

# GameRoot's viable master scenes are stored in ITS script, not here!



# Battlefield
var res_battlecell = preload("res://combat/framing/BattleCell.tscn")
var res_factionline = preload("res://combat/framing/FactionLineOwner.tscn")



# Battle UI
var res_bui = preload("res://combat/battle_ui/BUI.tscn")
var res_hp_4  = preload("res://combat/battle_ui/components/Pip_4_Health.tscn")
var res_hp_6  = preload("res://combat/battle_ui/components/Pip_6_Health.tscn")
var res_hp_8  = preload("res://combat/battle_ui/components/Pip_8_Health.tscn")
var res_hp_10 = preload("res://combat/battle_ui/components/Pip_10_Health.tscn")

var res_turntaker = preload("res://combat/battle_ui/Turntaker.tscn")
var res_quip = preload("res://combat/framing/Quip.tscn")



# Actors
var res_vfx_particle = preload("res://combat/battle_effects/VFXParticle.tscn")

var names_players: Array = ["Bard", "Knight", "Mage"]
var names_objects: Array = ["Rock"]
# Fallback is to assume enemy since that's most common


# Common Moves (resource files)
var common_moves: Array = ["WALK", "BE_EXT_MOTIONED", "PRESS_FORWARD"]
var CM_walk: Resource = preload("res://combat/move_actions/common/MR_WALK.tres")
var CM_be_ext_motioned: Resource = preload("res://combat/move_actions/common/MR_BE_EXT_MOTIONED.tres")
var CM_press_forward: Resource = preload("res://combat/move_actions/common/MR_PRESS_FORWARD.tres")

# ---

func _ready():
	
	for key in common_moves:
		var varname: String = str("CM_",key.to_lower())
		if varname in self:
			var move: MoveAction = get(varname)
			move.do_startup_config()



