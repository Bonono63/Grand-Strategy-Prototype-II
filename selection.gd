extends Camera2D

var mouse_position = Vector2()
var mouse_position_global = Vector2()
var start = Vector2()
var end = Vector2()
var start_vector = Vector2()
var end_vector = Vector2()
var is_dragging = false

signal area_selected
signal start_moving_selection

@onready var box = get_node("selection_box")

func _ready():
	connect("area_selected", Callable(get_parent(), "_on_area_selected"))

func _process(delta):
	if Input.is_action_just_pressed("left_click"): #when the user clicks left mouse the vector begins
		start = mouse_position_global
		start_vector = mouse_position
		is_dragging = true
	
	if is_dragging:
		end = mouse_position_global
		end_vector = mouse_position
		draw_area()

	if Input.is_action_just_released("left_click"): #when the user releases left click the vector ends
		if start_vector.distance_to(mouse_position) > 20:
			end = mouse_position_global
			end_vector = mouse_position
			is_dragging = false
			draw_area(false)
			emit_signal("area_selected", self)
		else:
			end = start
			is_dragging = false
			draw_area(false)

func _input(event):
		if event is InputEventMouse:
			mouse_position = event.position
			mouse_position_global = get_global_mouse_position()

func draw_area(draw=true): #draws a rectangle based on the vector the user drags
	get_node("selection_box").size = Vector2(abs(start_vector.x - end_vector.x), abs(start_vector.y - end_vector.y))
	var _position = Vector2()
	_position.x = min(start_vector.x, end_vector.x)
	_position.y = min(start_vector.y, end_vector.y)
	get_node("selection_box").position = _position
	get_node("selection_box").size *= int(draw)
	var position = Vector2()
	position.x = min(start_vector.x, end_vector.x)
	position.y = min(start_vector.y, end_vector.y)
	box.position = position
	box.size *= int(draw)
