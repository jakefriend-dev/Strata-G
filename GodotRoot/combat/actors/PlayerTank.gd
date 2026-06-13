extends ActorPlayer


# Note to self, reaction slash is broken & maybe should be rebuilt




# ---

func _ready():
#	print(name," connecting signals")
	connect("on_shield_consumed", self, "prep_melee_counter")
	pass

func prep_melee_counter(is_melee: bool):
#	print(name," reacting to melee damage!")
	if !is_melee: return
	
#	print(name," reacting to melee damage!")
	batman.reaction(self, "basic_melee")
	pass
