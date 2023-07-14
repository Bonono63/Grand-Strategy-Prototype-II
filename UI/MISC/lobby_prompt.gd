extends Control

@onready var list = $Panel/ItemList
@onready var new_button = $"Panel/New Country"
@onready var play_button = $"Panel/Play as Selected"

func _ready():
	var countries = Map.countries
	for country in countries:
		list.add_item(country, countries[country].flag, true)
	new_button.connect("button_down", Callable(self, "on_new_button_pressed"))
	play_button.connect("button_down", Callable(self, "on_play_button_pressed"))
	$Panel/ItemList.connect("item_clicked", Callable(self, "on_item_clicked"))
	$Panel/ItemList.connect("empty_clicked", Callable(self, "on_empty_selected"))

func on_new_button_pressed():
	var new_country_prompt = preload("res://UI/MISC/new_country_ui.tscn").instantiate()
	get_parent().add_child(new_country_prompt)
	self.queue_free()

func on_play_button_pressed():
	var selected = list.get_selected_items()
	print(list.get_item_text(selected[0]))
	Player.country_id = list.get_item_text(selected[0])
	get_parent().get_parent().emit_signal("setup_finished")
	self.queue_free()

func on_item_clicked(_index : int, _pos : Vector2, _mouse_index : int):
	play_button.disabled = false

func on_empty_selected(_pos : Vector2, _mouse : int):
	play_button.disabled = true
