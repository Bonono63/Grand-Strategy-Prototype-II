extends Panel

@onready var text_field = $TextEdit
@onready var save_button = $Save
@onready var back_button = $Back

func _ready():
	back_button.connect("button_down", Callable(self, "back_button_pressed"))
	save_button.connect("button_down", Callable(self, "save_button_pressed"))
	

func back_button_pressed():
	get_parent().get_child(0).show()
	self.queue_free()

func save_button_pressed():
	if text_field.text != "":
		get_parent().get_parent().save(text_field.text)
