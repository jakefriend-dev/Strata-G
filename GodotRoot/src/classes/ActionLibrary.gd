extends Node
class_name ActionLibrary

var actor: Actor # Specifically the library instance's actor

# All the common library varnames, including ourselves
	# We'll populate these in the Actor script once each library has been initialized
	# Varnames should have a 1:1 match with equivalent varnames in Actor.gd

var lib_helper  # Baseline helper functions like "Find nearest PC in dir" or "get 3x3 coords"
var lib_generic # Common behaviour/actions anyone can use, like walking 1 tile or common buffs
var lib_player  # Common players-only shared behaviour/actions
var lib_enemy   # Common enemies-only shared behaviour/actions

# Any UNIQUE actions should be given to that Actor's script, as you'd imagine

# ---

func update_all_library_references_against_actor():
	pass
