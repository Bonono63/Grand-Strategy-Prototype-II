extends Control

@onready var list = $Panel/ItemList

# Called when the node enters the scene tree for the first time.
func _ready():
	list.add_item("", null, true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
