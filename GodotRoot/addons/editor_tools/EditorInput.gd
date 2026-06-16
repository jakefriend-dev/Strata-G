extends Popup
class_name EditorToolPopup
tool

var entered_text: String = ""

func _ready():
	$PanelContainer/VBoxContainer/LineEdit.connect("text_entered", self, "on_enter")
	pass

func on_enter(text: String):
	entered_text = text
	visible = false # Autohides
	pass
