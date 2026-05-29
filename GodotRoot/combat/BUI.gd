extends Node2D

var actor: Actor

export var path_healthpar: NodePath
export var path_shieldpar: NodePath
var healthpar: GridContainer
var shieldpar: GridContainer
var res_piphealth = preload("res://combat/HealthPip.tscn")
var res_pipshield = preload("res://combat/ShieldPip.tscn")

func _ready():
	healthpar = get_node(path_healthpar)
	shieldpar = get_node(path_shieldpar)
	pass

func update_all():
	if $MC/VB/Name.text != actor.ofc_name:
		$MC/VB/Name.text = actor.ofc_name
	edit_max_pips("health", actor.max_health)
	edit_max_pips("shield", actor.def_shield)
	pass

# Use a USER max, not a BASE max - should already be x4'd (or whatever)
func edit_max_pips(piptype: String, new_max: int):
	if new_max < 0:
		return
	
	var par: GridContainer
	var res
	if piptype == "health":
		par = healthpar
		res = res_piphealth
	elif piptype == "shield":
		par = shieldpar
		res = res_pipshield
	else:
		return
	
	# Okay, from here it's valid! Unless there's no change to make, I guess
	
	var old_pipcount: int = par.get_child_count()
	var new_pipcount: int = int(ceil(float(new_max)/float(batman.BASE_HP_UNIT)))
#	if new_max == 0: new_pipcount = 0
	if par.visible != (new_max > 0):
		par.visible = (new_max > 0)
	
	if new_pipcount == old_pipcount:
		update_values_to_current(piptype)
		return
	
	var delta: int = new_pipcount - old_pipcount
#	print("For actor ",actor,", has ",old_pipcount," ",piptype," pips but needs ",new_pipcount)
	
	if delta < 0: # Need to remove excess pips!
		delta *= -1 # Flip to positive
#		print("Removing ",delta," pips!")
		for n in delta:
			var dyingpip = par.get_child(new_pipcount)
			# So basically, if the new number is 6 and the old is 8, we need to remove 2
			# get_child() is 0-based, so we want to end up with "5" o-based children
			# Therefore if we keep getting the new count, it'll always target whichever pip is just over the new desired end-count
			par.remove_child(dyingpip)
			dyingpip.queue_free()
		pass # We should now have the right quantity of pips
	
	else: # Need to add missing pips!
		var thiscount: int = old_pipcount
#		print("Adding ",delta," pips!")
		for n in delta:
			thiscount += 1
			var newpip = res.instance()
			newpip.set("name", str(thiscount))
			newpip.set("owner", self)
			par.add_child(newpip)
		pass # We should now have the right quantity of pips
	
	# Run a value updater regardless!
	update_values_to_current(piptype)
	pass

# This function DOESN'T KNOW if our pip quantity is correct or not! Assume max pips are already set correctly! If you want to do both, make a general-master function.
func update_values_to_current(piptype: String):
	var par: GridContainer
	var value: int
	if piptype == "health":
		par = healthpar
		value = actor.health
	elif piptype == "shield":
		par = shieldpar
		value = actor.shield
	else:
		return
	
	# Should be post-validation now
	
	# Base value rounds UP: 7 health would be base 2 even though that's 8
	var base_value: int = int(ceil(float(value)/float(batman.BASE_HP_UNIT)))
	
	for pip in par.get_children():
		var this_base: int = int(pip.name)
		var s: Sprite = pip.get_node("Sprite")
		
		if this_base < base_value: # We're 'full'
			s.frame = 4
		elif this_base > base_value: # We're 'empty'
			s.frame = 0
		else: # We're the one in contention!
			# Base 6 and x4 would mean this covers health values 21, 22, 23, 24
			var under_value: int = (base_value-1)*4
			var remnant_value: int = value - under_value
			s.frame = remnant_value
		pass
		
#		if piptype == "health":
#			if pip.visible != (s.frame > 0):
#				pip.visible = (s.frame > 0)
	pass



