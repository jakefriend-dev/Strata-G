extends NinePatchRect
class_name Sprite9Patch
tool

export var hframes: int setget set_hframes
export var vframes: int setget set_vframes
export var frame: int setget set_frame
export var sprite_overrides_size = true
var tex_size: Vector2
var frame_width: int
var frame_offset_x: int

var validated = false

func _ready():
	if utils.valid(self): validated = true
	pass

func set_vframes(num: int):
	if !validated: yield(self, "ready")
	if num < 1: return
#	vframes = num
#
#	"Determine the width of the image, then get the frame width from that"
#	tex_size = texture.get_size()
#	frame_width = int(tex_size.x / float(vframes))
##	print("TEXTURE SIZE: ",tex_size," and ",vframes," VFRAMES, so each frame is ",frame_width," wide")
#	if sprite_overrides_size:
#		update_region_rect()
#	else:
#		update_region_rect(rect_min_size.y)
	pass

func set_hframes(num: int):
	if !validated: yield(self, "ready")
	if num < 1: return
	hframes = num

	#"Determine the width of the image, then get the frame width from that"
	tex_size = texture.get_size()
	frame_width = int(tex_size.x / float(hframes))
#	print("TEXTURE SIZE: ",tex_size," and ",hframes," HFRAMES, so each frame is ",frame_width," wide")
	if sprite_overrides_size:
		update_region_rect()
	else:
		update_region_rect(rect_min_size.y)
	pass

func set_frame(num):
	if !validated: yield(self, "ready")
	if num < 0: return
	if num > hframes - 1: return
	frame = num
	
	#"Get the frame width and set the current region rect"
	frame_offset_x = frame * frame_width
	if sprite_overrides_size:
		update_region_rect()
	else:
		update_region_rect(rect_min_size.y)
	pass

func update_region_rect(recty = tex_size.y):
#	print(name,": recty going in: ",rect_min_size.y,"|",recty)
	
	region_rect = Rect2(frame_offset_x, 0, frame_width, tex_size.y)
	if sprite_overrides_size:
		rect_size.y = recty
		rect_min_size.y = recty
#	print(name,": recty going out: ",rect_min_size.y,"|",recty)
	pass
