tool
extends EditorPlugin

# -

func _enter_tree():
	add_tool_menu_item('Create New MoveAction', self, 'pre_create_new_move')
	pass

func _exit_tree():
	remove_tool_menu_item('Create New MoveAction')
	pass



# ---

func pre_create_new_move(arguments = null):
	var res = load("res://addons/editor_tools/EditorInputPopup.tscn")
	var popup: EditorInputPopup = res.instance()
	var base: Node = get_editor_interface()
	base.add_child(popup)
	
#	popup.popup_centered_minsize()
	popup.prep("Enter a new MoveAction key")

	yield(popup, "popup_hide")

	var entered_text: String = popup.entered_text
	popup.get_parent().remove_child(popup)
	popup.queue_free()

	if entered_text != "":
		create_new_move(entered_text)
	pass

func create_new_move(raw_movename: String):
	var og_raw_movename: String = raw_movename
	print("Editor tool create_new_move(",raw_movename,")")
	
	# Clean and prep the movename
	raw_movename = raw_movename.strip_escapes()
	raw_movename = raw_movename.strip_edges()
	raw_movename = raw_movename.replace(" ", "_")
	
	var unwanted_chars = [".",",",":","?","!","/"]
	for uc in unwanted_chars:
		raw_movename = raw_movename.replace(uc, "")
	
	# Validate that this is not an EXISTING move name
	if og_raw_movename != raw_movename:
		print("Cleaned to: ",raw_movename)
	var prepath: String = "res://combat/move_actions/"
	var ms_path: String = str(prepath,"MS_",raw_movename.to_lower(),".gd")
	var mr_path: String = str(prepath,"MR_",raw_movename.to_upper(),".tres")
	if utils.does_file_exist(ms_path) or utils.does_file_exist(mr_path):
		print("File for new MoveAction [",raw_movename,"] already exists, error!!")
		return
	
#	print("File is NEW and we ok!")
	
	# Create a "MS" script, lowercase
	var template_path: String = "res://combat/move_actions/templates/MS_template.gd"
	var dir: Directory = Directory.new()
	var mscode: int = dir.copy(template_path, ms_path)
	if mscode != OK:
		print("Error when copying new MS script template file, code: ",mscode)
		return
	
	# Create a "MR" resource, uppercase
	var mr_res: MoveAction = MoveAction.new()
	mr_res.resource_name = raw_movename.to_upper()
	mr_res.resource_local_to_scene = true
	mr_res.resource_path = mr_path
	var script: Script = load(ms_path)
	mr_res.set_script(script)
	var mrcode: int = ResourceSaver.save(mr_path, mr_res)
	if mrcode != OK:
		print("Error when saving/creating new MR resource file, code: ",mrcode)
		return
	
	print("Success, new MR and MS files for [",raw_movename.to_upper(),"] created!")
	pass
