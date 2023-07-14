extends Control

@onready var back_button = $Panel/Back_Button
@onready var create_button = $Panel/Create_Button
@onready var random_name_button = $Panel/Random_Name


func _ready():
	back_button.connect("button_down", Callable(self, "on_back_button_pressed"))
	create_button.connect("button_down", Callable(self, "on_create_button_pressed"))
	random_name_button.connect("button_down", Callable(self, "on_random_name_button_pressed"))
	$Panel/LineEdit.text = utils.random_country_name()

func on_back_button_pressed():
	var lobby_prompt = preload("res://UI/MISC/lobby_prompt.tscn").instantiate()
	get_parent().add_child(lobby_prompt)
	self.queue_free()

func on_create_button_pressed():
	Queue.add_command(Queue.types.create_country, { "color" : Color(randf_range(0,1), randf_range(0,1), randf_range(0,1)), "display_name" : $Panel/LineEdit.text})
	Player.country_id = $Panel/LineEdit.text
	var starting_city_prompt = preload("res://UI/MISC/starting_city_prompt.tscn").instantiate()
	get_parent().add_child(starting_city_prompt)
	self.queue_free()

func on_random_name_button_pressed():
	$Panel/LineEdit.text = utils.random_country_name()
