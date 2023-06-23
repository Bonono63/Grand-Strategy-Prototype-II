extends Panel

@onready var confirm_button = $Confirm

var selected_tile : Vector2

func _ready():
	$Label.text = "Select Your Starting location "
	get_parent().get_parent().connect("tile_selected", Callable(self, "on_tile_select"))
	confirm_button.connect("button_down", Callable(self, "confirmed"))

func on_tile_select(_pos):
	if Map.tile_map[_pos.x][_pos.y].terrain_type != Map.terrain_types.ocean and Map.tile_map[_pos.x][_pos.y].terrain_type != Map.terrain_types.swamp and Map.tile_map[_pos.x][_pos.y].terrain_type != Map.terrain_types.shallow_water:
		selected_tile = _pos
		$Label.text = str("Select Your Starting location ", selected_tile)
	else:
		invalid_selection()
		

func invalid_selection():
	$Label.text = "Invalid Selection"

func confirmed():
	Queue.add_command(Queue.types.construct_building, [selected_tile.x, selected_tile.y, Map.building_types.city_center])
	self.queue_free()
