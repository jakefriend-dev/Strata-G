extends PopupPanel
class_name EditorToolPopup
tool

var entered_text: String = ""

func prep():
	print("prepping B ",self,", ",get_parent())
#	visible = true
	
	$PanelContainer/VBoxContainer/LineEdit.connect("text_entered", self, "on_enter")
	pass

func on_enter(text: String):
	entered_text = text
	visible = false # Autohides
	pass

func create_new_move(raw_movename: String):
	print("Editor tool create_new_move(",raw_movename,")")
	
	# Clean and prep the movename
	
	# Validate that this is not an EXISTING move name
	
	# Create a "MS" script, lowercase
	
	# Create a "MR" resource, uppercase
	
	# Assign the script & its ownership to the resource
	pass
