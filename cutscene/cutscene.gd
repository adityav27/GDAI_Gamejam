extends Control

@onready var image = $TextureRect
@onready var text = $Panel/DialogueText

var images = [
	preload("res://cutscene/img1.png"),
	preload("res://cutscene/img2.png"),
	#preload("res://cutscene/img3.png")
]

var dialogue = [
	"You ran out of fuel while on a space mission and have to make an emergency landing on a
	 nearby planet ...",
	"But what you did not realise was the planet was overrun by deadly robots.
	 Your goal? Collect 4 keycards and get outta there"
]

var step := 0
var typing := false
var typing_speed := 0.03


func _ready():
	update_scene()


func update_scene():

	# fade transition
	var tween = create_tween()
	tween.tween_property(image, "modulate:a", 0.0, 0.3)
	await tween.finished

	image.texture = images[step]

	var tween2 = create_tween()
	tween2.tween_property(image, "modulate:a", 1.0, 0.3)

	await tween2.finished

	start_typewriter(dialogue[step])


func start_typewriter(sentence):

	text.text = sentence
	text.visible_characters = 0
	typing = true

	for i in sentence.length():
		text.visible_characters += 1
		await get_tree().create_timer(typing_speed).timeout

	typing = false




func _on_next_pressed() -> void:
	# if text still typing → finish instantly
	if typing:
		text.visible_characters = text.text.length()
		typing = false
		return

	step += 1

	if step >= images.size():
		get_tree().change_scene_to_file("res://scene/level_1.tscn")
		return

	update_scene()
