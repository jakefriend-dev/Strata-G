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



