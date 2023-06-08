extends Control

@onready var generate_button = $Generate
@onready var load_button = $Load
@onready var return_button = $Panel/Return


# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().get_root().connect("size_changed", Callable(self, "resolution_change"))
	return_button.connect("button_down", Callable(self, "return_button_button_pressed"))
	resolution_change()

func resolution_change():
	var aspect_ratio = Vector2(get_viewport().get_size().x, get_viewport().get_size().y).normalized()
	#$Panel.position = Vector2(0,0)
	#$Panel.size = Vector2(aspect_ratio.x*1000,aspect_ratio.y*1000)

func generate_button_pressed():
	get_tree().change_scene_to_file("res://Menus/singleplayer_world_select.tscn")

func return_button_button_pressed():
	get_tree().change_scene_to_file("res://Menus/main_menu.tscn")
