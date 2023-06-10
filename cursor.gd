extends CanvasLayer

@export var default_cursor : Texture = null
@export var base_window_size : Vector2 = Vector2.ZERO
@export var base_cursor_size : Vector2 = Vector2.ZERO

func _ready():
	update_cursor()
	
	var empty_cursor : ImageTexture
	
	Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
	get_tree().connect("screen_resized", Callable(self, "update_cursor"))

func _process(_delta):
	$Sprite.global_position = $sprite.get_global_mouse_position()

func update_cursor():
	var current_window_size : Vector2 = get_viewport().size
	var scale_multiple = min(floor(current_window_size.x / base_window_size.x), floor(current_window_size.y / base_window_size.y))
	var texture = ImageTexture.new()
	var image = default_cursor.get_data()
	
	image.resize(base_cursor_size.x * scale_multiple+1, base_cursor_size.y * scale_multiple+1, Image.INTERPOLATE_NEAREST)
	texture.create_from_image(image)
	
	Input.set_custom_mouse_cursor(texture, Input.CURSOR_ARROW)
