extends CanvasLayer

#export(Texture) var default_cursor = null
#export(Vector2) var base_window_size = Vector2.ZERO
#export(Vector2) var base_cursor_size = Vector2.ZERO


func _ready():
	update_cursor()
	
	Input.set_custom_mouse_cursor(empty_cursor, input.CURSOR_ARROW)
	get_tree().connect("screen_resized", self, "update_cursor")

func _process(delta):
	$Sprite.global_position = $sprite.get_global_mouse_position()

func update_cursor():
	var current_window_size = OS.window_size
	var scale_multiple = min(floor(current_window_size.x / base_window_size.x), floor(current_window_size.y / base_window_size.y)
	#var texture = ImageTexture.new()
	#var image = default_cursor.get_data()
	
	#image.resize(base_cursor_size.x * scale_multiple, base_cursor_size.y * scale_multiple, Image.INTERPOLATE_NEAREST)
	#texture.create_from_image(image)
	
	#Input.set_custom_mouse_cursor(texture, Input.CURSOR_ARROW)
