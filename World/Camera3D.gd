extends Node3D

const zoom_increment = 10
const max_zoom = 90
@export var min_zoom = 1
const default_zoom = 50

const rotation_control_enabled = false

@export var zoom_speed = 0.09
@export var mouse_sensitivity = 0.05

var zoom : float = default_zoom

var x = 0 
var y = 0

var position_control = false
var rotation_control = false

var forward : bool
var backward : bool
var left : bool
var right : bool
const keyboard_sensitivity = 0.5
var shift = 1

func _unhandled_input(event):
	if event.is_action_pressed("zoom_in"):
		if zoom > min_zoom : zoom-=zoom_increment
	if event.is_action_pressed("zoom_out"):
		if zoom < max_zoom : zoom+=zoom_increment
	if event is InputEventMouse:
		if event is InputEventMouseMotion:
			if event.relative.x != 0:
				x = event.relative.x
			if event.relative.y != 0:
				y = event.relative.y
		if event is InputEventMouseButton:
			if event.is_action_pressed("middle_click"):
				position_control = true
			if event.is_action_released("middle_click"):
				position_control = false
			if event.is_action_pressed("right_click"):
				position_control = true
			if event.is_action_released("right_click"):
				position_control = false
	if event is InputEventKey:
		if event.is_action_pressed("w"):
			forward = true
		if event.is_action_pressed("s"):
			backward = true
		if event.is_action_pressed("a"):
			left = true
		if event.is_action_pressed("d"):
			right = true
		if event.is_action_released("w"):
			forward = false
		if event.is_action_released("s"):
			backward = false
		if event.is_action_released("a"):
			left = false
		if event.is_action_released("d"):
			right = false
		if event.is_action_pressed("shift"):
			shift = 2
		if event.is_action_released("shift"):
			shift = 1

var _rotation_y : float
var prev_zoom = 0.5

var old_pos : Vector3
var old_rotation : Vector3

var x_offset = 0

func _process(_delta):
	if position_control:
		position -= Vector3(x*mouse_sensitivity*(position.y/45),0,y*mouse_sensitivity*(position.y/45))
	
	# when rotation control is enabled, this allows for it
	if rotation_control && shift > 1 && rotation_control_enabled:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_rotation_y = (x*mouse_sensitivity)
		rotate_y(_rotation_y)
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# keyboard control of the camera
	if (forward):
		translate_object_local(Vector3(0, keyboard_sensitivity*shift*(position.y/45), 0))
	if (backward):
		translate_object_local(Vector3(0, -keyboard_sensitivity*shift*(position.y/45), 0))
	if (left):
		translate_object_local(Vector3(-keyboard_sensitivity*shift*(position.y/45), 0, 0))
	if (right):
		translate_object_local(Vector3(keyboard_sensitivity*shift*(position.y/45), 0, 0))
	
	# smoothen zoom and clamp it
	position.y = lerp(prev_zoom, zoom, zoom_speed)
	position.y = clamp(position.y, min_zoom, max_zoom)
	
	# Stop the camera from going out of bounds
	position.x = clamp(position.x, 0, Map.size.x*sqrt(3)/2+(sqrt(3)/4))
	position.z = clamp(position.z, 0, Map.size.y*0.75+0.5)
	
	x = 0
	y = 0
	
	_rotation_y = 0
	prev_zoom = zoom
