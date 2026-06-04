extends Node

var actor: Actor

# ---

# If you START your turn on a tiletype -----------------------------------------

func ACT_started_on_hot():
	# Gain 1 AP
	pass

# The moment you ENTER a tiletype mid-turn -------------------------------------

func ACT_stepped_on_jagged():
	# 1 damage, 1 move debuff
	# Then fix the tile
	pass


func ACT_stepped_on_ice():
	# We need to know the direction-vector you entered from, and if it was a jump or step
	# If a step, attempt to continue moving! Unless immune, ofc
	pass

func ACT_stepped_on_poison():
	# Immediately take 1 damage
	pass
func ACT_stepped_in_mud():
	# Lose a movestep, unless lightweight
	pass

func ACT_stepped_in_water():
	# Lose a movestep, unless you're a swimmer
	pass

# If you END your turn on a tiletype -------------------------------------------

func ACT_ended_on_hot():
	# Take 1 damage unless immune
	pass

func ACT_ended_on_sand():
	# Lose a movestep, unless lightweight
	pass

# CHECKS -----------------------------------------------------------------------

func affected_by_jagged() -> bool:
	if actor.is_immune_jagged: return false
	if actor.weight == actor.weightclasses.HEAVY: return false
	if actor.weight == actor.weightclasses.HOVER: return false
	return true

func fixes_jagged_on_contact() -> bool:
	if actor.weight == actor.weightclasses.HOVER: return false
	return true

func affected_by_force() -> bool: # Wind AND knockback
	if actor.is_unmovable: return false
	if actor.weight == actor.weightclasses.HEAVY: return false
	return true

func affected_by_ice() -> bool:
	if actor.weight == actor.weightclasses.LIGHT: return false
	if actor.is_unmovable: return false
	if actor.is_immune_ice: return false
	return true

func affected_by_sinking() -> bool:
	if actor.weight == actor.weightclasses.LIGHT: return false
	return true















