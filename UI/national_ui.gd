extends Control

func _ready():
	$Panel.size.y = get_viewport_rect().size.y-250
