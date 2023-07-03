extends Control

@onready var singleplayer_button = $Singleplayer
@onready var multiplayer_button = $Multiplayer
@onready var settings_button = $Settings
@onready var quit_button = $Quit

# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().get_root().connect("size_changed", Callable(self, "resolution_change"))
	singleplayer_button.connect("button_down", Callable(self, "singleplayer_button_pressed"))
	multiplayer_button.connect("button_down", Callable(self, "multiplayer_button_pressed"))
	settings_button.connect("button_down", Callable(self, "settings_button_pressed"))
	quit_button.connect("button_down", Callable(self, "quit_button_pressed"))
	resolution_change()

func resolution_change():
	var aspect_ratio = Vector2(get_viewport().get_size().x, get_viewport().get_size().y).normalized()
	$Panel.position = Vector2(0,0)
	#$Panel.size = Vector2(aspect_ratio.x*500,aspect_ratio.y*2500)

func singleplayer_button_pressed():
	get_tree().change_scene_to_file("res://Menus/singleplayer_world_select.tscn")

func multiplayer_button_pressed():
	get_tree().change_scene_to_file("res://Menus/multiplayer_world_select.tscn")

func settings_button_pressed():
	get_tree().change_scene_to_file("res://Menus/settings.tscn")

func quit_button_pressed():
	get_tree().quit()
