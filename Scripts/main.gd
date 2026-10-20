extends Node2D

func _ready() -> void:
	# Mengalihkan ke scene Level 1 (level_root.tscn)
	get_tree().change_scene_to_file("res://Scenes/level_root.tscn")
