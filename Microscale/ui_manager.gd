extends Node

signal split_scale_entered

func _ready():
	pass

func _process(delta):
	pass

func _on_button_pressed():
	emit_signal("split_scale_entered")
