tool
extends EditorPlugin

# -

func _enter_tree():
	add_tool_menu_item('Create new MoveAction', self, 'pre_create_new_move')
	pass


func _exit_tree():
	remove_tool_menu_item('Create new MoveAction')
	pass

# ---

func pre_create_new_move():
	var popup: EditorToolPopup = EditorToolPopup.new()
	get_editor_interface().add_child(popup)
	
	popup.popup_centered_minsize()
	
	yield(popup, "popup_hide")
	
	var entered_text: String = popup.entered_text
	get_editor_interface().remove_child(popup)
	popup.queue_free()
	
	if entered_text != "":
		create_new_move(entered_text)
	pass

func create_new_move(raw_movename: String):
	print("Editor tool create_new_move(",raw_movename,")")
	
	# Clean and prep the movename
	
	# Validate that this is not an EXISTING move name
	
	# Create a "MS" script, lowercase
	
	# Create a "MR" resource, uppercase
	
	# Assign the script & its ownership to the resource
	pass
