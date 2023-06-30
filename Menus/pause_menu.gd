extends CanvasLayer

@onready var save_button = $"Pause Menu"/Save
@onready var settings_button = $"Pause Menu"/Settings
@onready var exit_button = $"Pause Menu"/"Exit to Main"
@onready var return_button = $"Pause Menu/Return"

func _ready():
	save_button.connect("button_down", Callable(self, "save_button_pressed"))
	settings_button.connect("button_down", Callable(self, "settings_button_pressed"))
	return_button.connect("button_down", Callable(self, "return_button_pressed"))

func save_button_pressed():
	var save_menu = preload("res://Menus/save_menu.tscn").instantiate()
	$"Pause Menu".hide()
	add_child(save_menu)

func settings_button_pressed():
	pass

func return_button_pressed():
	get_parent().pause = false
	self.queue_free()
