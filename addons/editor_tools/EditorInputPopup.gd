extends PopupPanel
class_name EditorInputPopup
tool

var entered_text: String = ""

func prep(desc: String = "Popup descriptive text"):
	$PanelContainer/VBoxContainer/Label.text = desc
	$PanelContainer/VBoxContainer/LineEdit.connect("text_entered", self, "on_enter")
	yield(VisualServer, "frame_pre_draw")
	yield(VisualServer, "frame_post_draw")
	popup_centered_minsize()
	pass

func on_enter(text: String):
	entered_text = text
	visible = false # Autohides
	pass
