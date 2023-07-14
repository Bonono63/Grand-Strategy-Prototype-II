extends Panel

@onready var confirm_button = $Confirm

var selected_tile

var display_name : String

func _ready():
	$Label.text = "Select Your Starting location "
	get_parent().get_parent().connect("tile_selected", Callable(self, "on_tile_select"))
	confirm_button.connect("button_down", Callable(self, "confirmed"))

func on_tile_select(_pos : Vector2i):
	if Map.tile_map[_pos.x][_pos.y].terrain_type != "ocean" and Map.tile_map[_pos.x][_pos.y].terrain_type != "swamp" and Map.tile_map[_pos.x][_pos.y].terrain_type != "shallow_water":
		selected_tile = _pos
		confirm_button.disabled = false
		$Label.text = str("Select Your Starting location ", selected_tile)
	else:
		invalid_selection()
		

func invalid_selection():
	selected_tile = null
	$Label.text = "Invalid Selection"
	confirm_button.disabled = true

func confirmed():
	Queue.add_command(Queue.types.set_territory, {"x":selected_tile.x, "y":selected_tile.y, "controller_id":Player.country_id})
	Queue.add_command(Queue.types.set_territory, {"x":selected_tile.x-1, "y":selected_tile.y, "controller_id":Player.country_id})
	Queue.add_command(Queue.types.set_territory, {"x":selected_tile.x+1, "y":selected_tile.y, "controller_id":Player.country_id})
	if selected_tile.y % 2 == 0:
		Queue.add_command(Queue.types.set_territory, {"x":selected_tile.x, "y":selected_tile.y+1, "controller_id":Player.country_id})
		Queue.add_command(Queue.types.set_territory, {"x":selected_tile.x+1, "y":selected_tile.y+1, "controller_id":Player.country_id})
		Queue.add_command(Queue.types.set_territory, {"x":selected_tile.x, "y":selected_tile.y-1, "controller_id":Player.country_id})
		Queue.add_command(Queue.types.set_territory, {"x":selected_tile.x+1, "y":selected_tile.y-1, "controller_id":Player.country_id})
	else:
		Queue.add_command(Queue.types.set_territory, {"x":selected_tile.x-1, "y":selected_tile.y+1, "controller_id":Player.country_id})
		Queue.add_command(Queue.types.set_territory, {"x":selected_tile.x, "y":selected_tile.y+1, "controller_id":Player.country_id})
		Queue.add_command(Queue.types.set_territory, {"x":selected_tile.x-1, "y":selected_tile.y-1, "controller_id":Player.country_id})
		Queue.add_command(Queue.types.set_territory, {"x":selected_tile.x, "y":selected_tile.y-1, "controller_id":Player.country_id})
	Queue.add_command(Queue.types.set_building, { "x" : selected_tile.x, "y" : selected_tile.y, "building_type" : "city_center", "values": {"pop":{Map.countries[Player.country_id].native_pop:3}}})
	get_parent().get_parent().emit_signal("setup_finished")
	self.queue_free()
