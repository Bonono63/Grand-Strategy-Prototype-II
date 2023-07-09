extends Control

@onready var list = $Panel/ItemList
@onready var new_button = $"Panel/New Country"
@onready var play_button = $"Panel/Play as Selected"

func _ready():
	var countries = Map.countries
	for country in countries:
		list.add_item(country.display_name, country.flag, true)
	new_button.connect("button_down", Callable(self, "on_new_button_pressed"))
	play_button.connect("button_down", Callable(self, "on_play_button_pressed"))
	$Panel/ItemList.connect("item_selected", Callable(self, "on_item_selected"))
	$Panel/ItemList.connect("empty_clicked", Callable(self, "on_empty_selected"))

func on_new_button_pressed():
	var starting_city_prompt = preload("res://UI/starting_city_prompt.tscn").instantiate()
	get_parent().add_child(starting_city_prompt)
	self.queue_free()

func on_play_button_pressed():
	var selected = list.get_selected_items()
	Player.current_country_id = selected[0]
	get_parent().get_parent().emit_signal("setup_finished")
	self.queue_free()

func on_item_selected(index : int):
	play_button.disabled = false

func on_empty_selected(pos : Vector2, mouse : int):
	play_button.disabled = true
