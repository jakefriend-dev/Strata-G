extends Resource
class_name StatusCondition

export var key: String

export var display_name: String
export (String, MULTILINE) var display_desc: String

export (String, "--", "good", "bad", "misc") var icon_type: String

export var default_tick_duration: int
export (String, "Start of turn", "End of turn") var tick_point: String

export (String, MULTILINE) var listed_subtags: String
var subtags: Array = []

export var custom_start_function: String # If populated, tries to run this Actor.gd function upon STARTING the condition
export var custom_clear_function: String  # If populated, tries to run this Actor.gd function upon ENDING the condition; if NOT populated it'll default to generic_clear_status()

export var base_value: int = 0 # Can be used for damage, healing, etc.

# ---

func runtime_setup():
	listed_subtags = listed_subtags.replace(" ", "")
	subtags = listed_subtags.split(",")
	pass







