extends Node

@onready var player = $AudioStreamPlayer

func _ready():
	player.play()
