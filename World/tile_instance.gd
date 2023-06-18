extends MeshInstance3D

signal input_event

var pos : Vector2i

func init(_pos : Vector2i):
	pos = _pos

func _ready():
	$Area3D.connect("input_event", Callable(self, "on_input_event"))

func on_input_event(a, b, c, d, e):
	print(pos)
	emit_signal("input_event", a, b, c, d, e)
