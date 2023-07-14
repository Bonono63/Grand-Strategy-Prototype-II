extends TextureButton

signal building_selected

var _building : String
func _ready():
	connect("button_down", Callable(self, "_button_down"))

func _button_down():
	emit_signal("building_selected", _building)
