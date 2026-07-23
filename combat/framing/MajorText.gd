extends Node2D

var mt_time: float = 0.125
var avg_wait_time: float

# -

func _ready():
	visible = true
	for child in get_children():
		child.visible = false
	pass

func clear_existing_tweens():
	utils.tween.remove(self, "modulate:a")
	for child in get_children():
		utils.tween.remove(child, "modulate:a")
	pass

func show_solo_text(big_text: String, instant: bool = false):
#	clear_existing_tweens()
	
	var mtpar: Node2D = $MajorCentered
	if !mtpar.visible:
		mtpar.visible = true
	
	mtpar.position.y = 0
	var bl: Label = mtpar.get_node("BigLabel")
	var sl: Label = mtpar.get_node("SmallLabel")
	update_text(bl, big_text, sl, "")
	
	if instant:
		modulate.a = 1.0
	else:
		utils.tween.interpolate_property(mtpar, "modulate:a", null, 1.0, mt_time, Tween.TRANS_CIRC, Tween.EASE_OUT)
		utils.tween.start()
	pass

func show_prefixed_text(big_text: String, lesser_text: String, instant: bool = false):
#	clear_existing_tweens()
	
	var mtpar: Node2D = $MajorCentered
	if !mtpar.visible:
		mtpar.visible = true
	
	mtpar.position.y = 32
	var bl: Label = mtpar.get_node("BigLabel")
	var sl: Label = mtpar.get_node("SmallLabel")
	update_text(bl, big_text, sl, lesser_text)
	
	if instant:
		modulate.a = 1.0
	else:
		utils.tween.interpolate_property(mtpar, "modulate:a", null, 1.0, mt_time, Tween.TRANS_CIRC, Tween.EASE_OUT)
		utils.tween.start()
	pass

func show_new_turn_text(turntaker: Actor, lesser_text: String, instant: bool = false):
#	clear_existing_tweens()
	
	var mtpar: Node2D = $TurnHighlight
	if !mtpar.visible:
		mtpar.visible = true
	
	var big_text: String = str("“",turntaker.display_name,"”")
	var actorx: float = turntaker.position.x
	mtpar.get_node("BG/Centerpoint").position.x = actorx
	
	var offset: float = 0.2
	if turntaker is ActorPlayer:
		mtpar.get_node("Text").position.x = batman.WINDOW_SIZE.x * offset
	else:
		mtpar.get_node("Text").position.x = batman.WINDOW_SIZE.x * -offset
	
	var bl: Label = mtpar.get_node("Text/BigLabel")
	var sl: Label = mtpar.get_node("Text/SmallLabel")
	update_text(bl, big_text, sl, lesser_text)
	
	if instant:
		modulate.a = 1.0
	else:
		utils.tween.interpolate_property(mtpar, "modulate:a", null, 1.0, mt_time, Tween.TRANS_CIRC, Tween.EASE_OUT)
	
	var texs: Node2D = $TurnHighlight/BG/Centerpoint/MainTexs
	var hili: Node2D = $TurnHighlight/BG/Centerpoint/Highlight
	var yshift: float = 20.0 # MAX about 100 or so
	utils.tween.interpolate_property(texs, "position:y", -yshift, yshift, batman.timeout_major_text, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	utils.tween.interpolate_property(hili, "position:y", yshift, -yshift, batman.timeout_major_text, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	
	utils.tween.start()
	pass

# ---

func update_text(bl: Label, big_text: String, sl: Label, lesser_text: String):
	bl.text = big_text
	bl.get_node("Shadow").text = big_text
	sl.text = lesser_text
	sl.get_node("Shadow").text = lesser_text
	pass

func hide_major_text(instant: bool = false):
	if instant:
		clear_existing_tweens()
		modulate.a = 0.0
		for child in get_children():
			child.modulate.a = 0.0
	
	else:
		for child in get_children():
			utils.tween.interpolate_property(child, "modulate:a", null, 0.0, mt_time, Tween.TRANS_CIRC, Tween.EASE_OUT)
		utils.tween.start()
	pass




