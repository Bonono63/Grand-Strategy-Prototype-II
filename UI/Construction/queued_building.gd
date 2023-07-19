extends Control

var index : int
var progress_percentage : int
var progress_texture : ImageTexture

func init(_building : String, _index : int, progress : int):
	index = _index
	$building_name.text = _building
	
	progress_percentage = progress / Map.building_types[_building].production_cost
	
	var image_portion = progress_percentage / 30
	progress_texture = ImageTexture.create_from_image(Image.load_from_file(str("res://UI/Button Resources/progress_bar_",str(image_portion))))

func _ready():
	$remove.connect("button_down", Callable(self, "on_remove"))

func on_remove():
	Map.countries[Player.country_id].building_queue.remove_at(index)
	queue_free()
