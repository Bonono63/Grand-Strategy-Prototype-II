extends Panel

@onready var confirm_button = $Confirm

var selected_tile : Vector2

var cooldown = 0
const cooldown_reset = 300

func _ready():
	get_parent().get_parent().connect("tile_selection_changed", Callable(self, "tile_selected"))
	confirm_button.connect("button_down", Callable(self, "confirmed"))

func tile_selected(_position):
	if Map.tile_map[_position.x][_position.y].terrain_type != Map.terrain_types.ocean and Map.tile_map[_position.x][_position.y].terrain_type != Map.terrain_types.swamp and Map.tile_map[_position.x][_position.y].terrain_type != Map.terrain_types.shallow_water:
		selected_tile = _position
	else:
		invalid_selection()

func invalid_selection():
	$Label.text = "Invalid Selection"
	cooldown = cooldown_reset

func _process(_delta):
	if cooldown != 0:
		cooldown -= 1
	if cooldown == 0:
		$Label.text = "Select Your Starting location"
	

func confirmed():
	Queue.add_command(Queue.types.construct_building, [selected_tile.x, selected_tile.y, Map.building_types.city_center])
	self.queue_free()
