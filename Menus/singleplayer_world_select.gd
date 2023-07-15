extends Control

@onready var return_button = $Panel/Return
@onready var save_list = $Panel/SaveList
@onready var open_button = $Panel/open
@onready var new_button = $Panel/new

var selected_save : String

func _ready():
	return_button.connect("button_down", Callable(self, "return_button_button_pressed"))
	new_button.connect("button_down", Callable(self, "new_button_pressed"))
	save_list.connect("item_selected", Callable(self, "save_selected"))
	open_button.connect("button_down", Callable(self, "open_button_button_pressed"))
	get_saves()

func _process(_delta):
	if selected_save.is_empty():
		open_button.disabled = true

func new_button_pressed():
	var world = preload("res://World/world.tscn").instantiate()
	world.init(Vector2i(512, 384),"", true)
	get_tree().get_root().add_child(world)
	get_tree().change_scene_to_packed(world)
	self.queue_free()

func return_button_button_pressed():
	get_tree().change_scene_to_file("res://Menus/main_menu.tscn")

func open_button_button_pressed():
	var world = preload("res://World/world.tscn").instantiate()
	world.init(Vector2i(0,0), "user://"+selected_save, true)
	get_tree().get_root().add_child(world)
	get_tree().change_scene_to_packed(world)
	self.queue_free()

func save_selected(index : int):
	open_button.disabled = false
	selected_save = save_list.get_item_text(index)
	#print(selected_save)

func get_saves() -> void:
	var dir = DirAccess.open("user://")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			#print(file_name)
			if file_name.ends_with(".png"):
				save_list.add_item(file_name)
			file_name = dir.get_next()
