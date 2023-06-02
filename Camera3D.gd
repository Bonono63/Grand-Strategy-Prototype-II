extends Node3D

const zoom_increment = 2
const max_zoom = 300
const min_zoom = -100

@export var zoom_speed = 0.09
@export var mouse_sensitivity = 0.005
#@export var main : Node3D

var zoom = min_zoom

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
				x = -event.relative.x
			if event.relative.y != 0:
				y = event.relative.y
		if event is InputEventMouseButton:
			if event.is_action_pressed("middle_click"):
				position_control = true
			if event.is_action_released("middle_click"):
				position_control = false
			if event.is_action_pressed("right_click"):
				rotation_control = true
			if event.is_action_released("right_click"):
				rotation_control = false
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

func _process(_delta):
	if position_control:
		translate_object_local(Vector3(x*mouse_sensitivity,y*mouse_sensitivity,0))
	
	if rotation_control && shift > 1:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_rotation_y = (x*mouse_sensitivity)
		rotate_y(_rotation_y)
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if (forward):
		translate_object_local(Vector3(0, keyboard_sensitivity*shift, 0))
	if (backward):
		translate_object_local(Vector3(0, -keyboard_sensitivity*shift, 0))
	if (left):
		translate_object_local(Vector3(-keyboard_sensitivity*shift, 0, 0))
	if (right):
		translate_object_local(Vector3(keyboard_sensitivity*shift, 0, 0))
	
	position.y = zoom
	position.y = clamp(position.y, min_zoom, max_zoom)
	
	x = 0
	y = 0
	_rotation_y = 0
	prev_zoom = zoom
