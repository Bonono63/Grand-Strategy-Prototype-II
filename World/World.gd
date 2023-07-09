extends Node3D

### Stores and operates all World data and functions
### Essentially the main loop of the game

@onready var minimap = $GUI/Minimap
@onready var camera = $Camera
@onready var inspector = $"GUI/location Inspector"

@export_range(0,1) var sea_level = .4
@export_range(0,1) var coast_height = .475
@export_range(0,1) var shore_height = .5
@export_range(0,1) var mountain_height = .8

@export_range(0,1) var cold_cutoff = .35
@export_range(0,1) var warm_cutoff = .65

@export_range(0,1) var dry_cutoff = .55
@export_range(0,1) var moist_cutoff = .8

@export_range(0,1) var river_moisture_cutoff = .875
@export_range(0,1) var river_cutoff = .955
@export_range(0,1) var river_moisture_addition = 0.25

const HEXAGON_WIDTH = sqrt(3)/2

var terrain_texture : ImageTexture

var minimap_drag = false
var drag : Vector2
var minimap_size : Vector2

var pause : bool

signal tile_selected
signal starting_city_selection
signal setup_finished
signal country_selected
signal toggle_minimap
signal toggle_debug
signal toggle_command_prompt

# initialize the world settings etc. (basically decide whether to load or generate a world)
func init(size : Vector2i, _save : String):
	Queue.clear_queue()
	Map.clear(size)
	Map.load_map_resources("res://World/")
	#await Map.resources_loaded
	print("fortnite")
	if _save.is_empty():
		generate_world(size,randi())
	else:
		open(_save)

func _unhandled_input(event):
	if event is InputEventKey:
		# open settings menu or close it
		if event.is_action_pressed("ui_cancel"):
			if !pause:
				var pause_menu = preload("res://Menus/pause_menu.tscn").instantiate()
				add_child(pause_menu)
				pause_menu.exit_button.connect("button_down", Callable(self, "return_to_main_menu"))
				pause = true
			else:
				pause = false
				remove_child(get_child(-1))
		if event.is_action_pressed("tab"):
			emit_signal("toggle_minimap")
		if event.is_action_pressed("open_prompt"):
			emit_signal("toggle_command_prompt")
		if event.is_action_pressed("debug_toggle"):
			emit_signal("toggle_debug")

# can be called anywhere to return to the main menu
func return_to_main_menu():
	get_tree().change_scene_to_file("res://Menus/main_menu.tscn")
	self.queue_free()

#func unitFightingEqual(unit : Array): #simulates combat between 2 units with the same stats
#	var combat_cycles : int
#	
#	unit[2] = unit[4] / unit[3] #morale is equal to the ratio of actual_strength and max_strength
#	
#	while(unit[2] >= .85): #when a unit loses more than 15% morale it retreats (designed for medieval combat)
#		var damage : float = unit [0] - unit [1] #damage = enemy attack - unit defense
#		unit[4] = unit[4] - damage #new unit strength after damage is applied
#		unit[2] = unit[4] / unit[3]
#		combat_cycles+=1
#		print(unit[2], " morale")
#	
#	print(combat_cycles , " combat cycles")
#	print(unit[4], " unit's remaining strength") 

func _ready():
	#Engine.max_fps = 60
	Map.connect("map_loaded", Callable(self, "on_map_loaded"))

func on_map_loaded():
	print("map loaded")
	setup_multimesh_mesh()
	generate_terrain_map()
	world_collision_setup()
	
	Map.connect("terrain_map_change", Callable(self, "on_terrain_map_update"))
	Map.connect("building_map_change", Callable(self, "on_building_map_update"))
	Map.connect("territory_map_change", Callable(self, "on_territory_map_update"))
	
	connect("setup_finished", Callable(self, "on_set_up_finished"))
	$"Map Input Events".connect("input_event", world_input_event)
	
	### decide whether to ask for a new country or to select a country
	
	Map.create_country(Color("473300"), "Imperial Germany")
	Map.create_country(Color("080084"), "Great Britain")
	
	if !Map.countries.is_empty():
		open_lobby_prompt()
	else:
		pick_starting_city_prompt()
	
	for x in 6:
		for y in 6:
			Queue.add_command(Queue.types.set_territory, {"x":x, "y":y, "controller_id":1})
	
	for x in 6:
		for y in 6:
			Queue.add_command(Queue.types.set_territory, {"x":x+6, "y":y+6, "controller_id":2})
	
	# Center the camera in the world
	set_camera_position(Vector2((Map.size.x*HEXAGON_WIDTH)/2, (Map.size.y*0.75)/2))

func on_terrain_map_update(coordinates : Vector2i):
	set_color(coordinates, get_tile_color(coordinates))

func on_building_map_update(pos : Vector2i):
	
	var building_type = Map.tile_map[pos.x][pos.y].building_type
	
	var instance = preload("res://World/Buildings/Building.tscn").instantiate()
	
	var _name = str(pos.y+(pos.x*Map.size.x))
	
	for child in $"Building Layer".get_child_count():
		var node = $"Building Layer".get_child(child)
		if node.name == _name:
			node.queue_free()
	
	var path = "res://World/map_resources/building/"+Map.building_types[building_type].model
	
	#print(path)
	var model = load(path)
	if model == null:
		printerr("Unable to find the specified model ", path)
	else:
		instance.mesh = model
	
	instance.name = _name
	var world_space = get_tile_world_pos(pos)
	instance.position = Vector3(world_space.x, 0, world_space.y)
	$"Building Layer".add_child(instance)

func on_territory_map_update(coordinates : Vector2i):
	set_color(coordinates, get_tile_color(coordinates))

func _process(_delta):
	update_minimap()
	update_camera_outline()

### World creation, saving and generation

#open a previous world
func open(open_path : String) -> void:
	print("opening ", open_path)
	var image : Image
	image = Image.load_from_file(open_path)
	
	Map.size.x = image.get_width()
	Map.size.y = image.get_height()
	
	var tile_map : Array = []
	utils.initate_2d_array(tile_map, Map.size.x, Map.size.y)
	
	for x in Map.size.x:
		for y in Map.size.y:
			var color : Color = image.get_pixel(x,y)
			var _tile = tile.new()
			_tile.terrain_type = color.r8
			#_tile.building.type = color.g8
			_tile.controller = color.b8
			
			tile_map[x][y] = _tile
	
	Map.tile_map = tile_map
	
	#PAIN
	await ready
	
	Map.emit_signal("map_loaded")

#save the current world
func save(save_path : String) -> void:
	var image : Image
	image = Image.create(Map.size.x, Map.size.y, false, Image.FORMAT_RGBA8)
	
	for x in Map.size.x:
		for y in Map.size.y:
			var color : Color = Color()
			#tile type
			color.r8 = Map.tile_map[x][y].terrain_type
			#building type
			#color.g8 = Map.tile_map[x][y].building.type
			#controller type
			color.b8 = Map.tile_map[x][y].controller
			image.set_pixel(x,y,color)
	
	image.save_png("user://"+save_path+".png")
	print("game saved to: ", "user://", save_path)

enum moisture { DRY, MOIST, WET }
enum temperature { COLD, WARM, HOT }

func generate_world(size : Vector2i , _seed : int):
	print("generating world")
	Map.size.x = int(size.x)
	Map.size.y = int(size.y)
	#print(map.length)
	#print(map.width)
	
	var height_map_noise = FastNoiseLite.new()
	var moisture_map_noise = FastNoiseLite.new()
	var temperature_map_noise = FastNoiseLite.new()
	var river_map_noise = FastNoiseLite.new()
	
	moisture_map_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	height_map_noise.seed = _seed
	height_map_noise.frequency = 0.0075
	height_map_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	
	moisture_map_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	moisture_map_noise.seed = _seed+1
	moisture_map_noise.frequency = 0.0075
	
	temperature_map_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	temperature_map_noise.seed = _seed+2
	temperature_map_noise.frequency = 0.0075
	
	river_map_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	river_map_noise.seed = _seed+3
	river_map_noise.frequency = 0.01
	river_map_noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	river_map_noise.fractal_lacunarity = 0
	river_map_noise.fractal_weighted_strength = 1
	
	var height_map : NoiseTexture2D = NoiseTexture2D.new()
	var moisture_map : NoiseTexture2D = NoiseTexture2D.new()
	var temperature_map : NoiseTexture2D = NoiseTexture2D.new()
	var river_map : NoiseTexture2D = NoiseTexture2D.new()
	
	height_map.width = size.x
	height_map.height = size.y
	height_map.noise = height_map_noise
	
	moisture_map.width = size.x
	moisture_map.height = size.y
	moisture_map.noise = moisture_map_noise
	
	temperature_map.width = size.x
	temperature_map.height = size.y
	temperature_map.noise = temperature_map_noise
	
	river_map.width = size.x
	river_map.height = size.y
	river_map.noise = river_map_noise
	
	await height_map.changed
	await moisture_map.changed
	await temperature_map.changed
	await river_map.changed
	
	var height_image : Image = height_map.get_image()
	var moisture_image : Image = moisture_map.get_image()
	var temperature_image : Image = temperature_map.get_image()
	var river_image : Image = river_map.get_image()
	
	for x in size.x:
		for y in size.y:
			if river_image.get_pixel(x,y).r >= river_moisture_cutoff:
				moisture_image.set_pixel(x,y, Color(moisture_image.get_pixel(x,y).r+river_moisture_addition, moisture_image.get_pixel(x,y).g+river_moisture_addition, moisture_image.get_pixel(x,y).b+river_moisture_addition))
	
	var tile_map : Array = []
	utils.initate_2d_array(tile_map, size.x, size.y)
	
	for x in size.x:
		for y in size.y:
			var _tile = tile.new()
			#ocean
			if height_image.get_pixel(x,y).r <= sea_level:
				_tile.terrain_type = "ocean"
			
			#coast
			else :if height_image.get_pixel(x,y).r <= coast_height:
				_tile.terrain_type = "shallow_water"
			
			#river gen
			else :if river_image.get_pixel(x,y).r >= river_cutoff:
				_tile.terrain_type = "shallow_water"
			
			#shore
			else: if height_image.get_pixel(x,y).r <= shore_height:
				_tile.terrain_type = "shore"
			
			#moutains
			else: if height_image.get_pixel(x,y).r >= mountain_height:
				_tile.terrain_type = "mountain"
			
			else: 
				var moist
				var temp
				
				if moisture_image.get_pixel(x,y).r <= dry_cutoff:
					moist = moisture.DRY
				else: if moisture_image.get_pixel(x,y).r <= moist_cutoff:
					moist = moisture.MOIST
				else:
					moist = moisture.WET
				
				if temperature_image.get_pixel(x,y).r <= warm_cutoff:
					temp = temperature.WARM
				else: 
					temp = temperature.HOT
				
				match moist:
					moisture.DRY:
						match temp:
							temperature.HOT:
								_tile.terrain_type = "desert" # desert
							temperature.WARM:
								_tile.terrain_type = "plain" # plains
					moisture.MOIST:
						match temp:
							temperature.HOT:
								_tile.terrain_type = "plain" # plains
							temperature.WARM:
								_tile.terrain_type = "forest" # forest
					moisture.WET:
						match temp:
							temperature.HOT:
								_tile.terrain_type = "jungle" # jungle
							temperature.WARM:
								_tile.terrain_type = "swamp" # swamp
			tile_map[x][y] = _tile
	
	Map.tile_map = tile_map
	
	Map.emit_signal("map_loaded")

func setup_multimesh_mesh():
	var mesh_data = []
	mesh_data.resize(ArrayMesh.ARRAY_MAX)
	mesh_data[ArrayMesh.ARRAY_VERTEX] = PackedVector3Array(
		[
			Vector3(0,0,0), # center
			Vector3(0,0,0.5), # upper point
			Vector3(sqrt(3)/4,0,0.25), # top right
			Vector3(sqrt(3)/4,0,-0.25), # lower right
			Vector3(0,0,-0.5), # lower point
			Vector3(-sqrt(3)/4,0,-0.25), # lower left
			Vector3(-sqrt(3)/4,0,0.25), # top left
		]
	)
	
	mesh_data[ArrayMesh.ARRAY_INDEX] = PackedInt32Array(
		[
			0,1,2, # top right
			
			0,2,3, # center right
			
			0,3,4, # bottom right
			
			0,4,5, # bottom left
			
			0,5,6, # center left
			
			0,6,1, # top left
		]
	)
	
	# I don't even entirely know why this number works, but it does
	var edge_offset = 0.5-HEXAGON_WIDTH/2
	
	# This took me far too long to get just right, but it is the perfect UV for the hexagon tiles!
	mesh_data[ArrayMesh.ARRAY_TEX_UV] = PackedVector2Array(
		[
			Vector2(0.5,0.5), # 0.0 , 0.0
			Vector2(0.5,0.0), # 0.0 , 0.5
			Vector2(1.0-edge_offset,0.25), # sqrt(3)/4 , 0.25
			Vector2(1.0-edge_offset,0.75), # sqrt(3)/4 , -0.25
			Vector2(0.5,1.0), # 0.0 , -0.5
			Vector2(0.0+edge_offset,0.75), # -sqrt(3)/4 , -0.25
			Vector2(0.0+edge_offset,0.25), # -sqrt(3)/4 , 0.25
		]
	)
	
	$"Terrain MultiMesh".multimesh.mesh = ArrayMesh.new()
	$"Terrain MultiMesh".multimesh.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data)
	
	#ResourceSaver.save($"Terrain MultiMesh".multimesh.mesh, "res://hexagon.tres", ResourceSaver.FLAG_COMPRESS)

func generate_terrain_map() -> void:
	$"Terrain MultiMesh".multimesh.instance_count = Map.size.x * Map.size.y
	
	var id : int = 0
	for x in Map.size.x:
		for z in Map.size.y:
			
			var x_offset : float = 0
			if (z % 2) == 1:
				x_offset = HEXAGON_WIDTH/2
			
			var instance_transform : Vector3 = Vector3(x*HEXAGON_WIDTH-(x_offset)+HEXAGON_WIDTH,0,-z*(3.0/4.0)-0.5)
			
			$"Terrain MultiMesh".multimesh.set_instance_transform(id, Transform3D(Basis(), Vector3(instance_transform)))
			$"Terrain MultiMesh".multimesh.set_instance_color(id, get_tile_color(Vector2i(x,z)))
			id+=1
	
	var image : Image = Image.create(Map.size.x, Map.size.y, false, Image.FORMAT_RGBA8)
	
	for x in Map.size.x:
		for y in Map.size.y:
			image.set_pixel(x,y,get_tile_color(Vector2i(x,y)))
	
	var texture : ImageTexture = ImageTexture.create_from_image(image)
	texture.update(image)
	
	terrain_texture = texture

func set_color(coordinates : Vector2i, color : Color):
	var id = coordinates.y+(coordinates.x*Map.size.y)
	$"Terrain MultiMesh".multimesh.set_instance_color(id, color)

func get_color(coordinates : Vector2i) -> Color:
	var id = coordinates.y+(coordinates.x*Map.size.x)
	return $"Terrain MultiMesh".multimesh.get_instance_color(id)

func get_tile_color(pos : Vector2i) -> Color:
	var color : Color
	var terrain_type = Map.tile_map[pos.x][pos.y].terrain_type
	if terrain_type != null:
		color = Color(Map.terrain_types[terrain_type].color)
	else:
		printerr("no terrain type at location: ", pos)
		color = Color(0.0,0.0,0.0,0.0)
	
	### Transparency formula to apply controller hue to tiles
	
	var opacity = 0.35;
	var controller = Map.tile_map[pos.x][pos.y].controller
	
	if controller > 0:
		
		var controller_color = Map.countries[controller-1].color
		
		color = Color(((1-opacity)*color.r) + opacity*controller_color.r, ((1-opacity)*color.g) + opacity*controller_color.g, ((1-opacity)*color.b) + opacity*controller_color.b) 
	return color

### Interaction with the world

func world_collision_setup():
	var collision_shape : Vector3 = Vector3(Map.size.x*HEXAGON_WIDTH+HEXAGON_WIDTH/2, 0, (Map.size.y*0.75)+0.25)
	var collision_position : Vector3 = Vector3((collision_shape.x/2), 0, (collision_shape.z/2))
	
	$"Map Input Events/MeshInstance3D".position = collision_position
	$"Map Input Events/CollisionShape3D".position = collision_position
	
	$"Map Input Events/CollisionShape3D".shape.size = collision_shape
	$"Map Input Events/MeshInstance3D".mesh.size = collision_shape

var prev_input_pos : Vector2i

func world_input_event(_a, event, _position, _d, _e):
	if event is InputEventMouseButton:
		if event.is_action_released("left_click"):
			var transformed = transform_input_position(_position)
			if transformed.x >= 0 and transformed.x <= Map.size.x-1 and transformed.y >= 0 and transformed.y <= Map.size.y-1:
				if prev_input_pos != null:
					set_color(prev_input_pos, get_tile_color(prev_input_pos))
				set_color(Vector2i(transformed.x, transformed.y), "ed2e21")
				prev_input_pos = Vector2i(transformed.x, transformed.y)
				emit_signal("tile_selected", transformed)

func transform_input_position(pos : Vector3) -> Vector2:
	
	var finalPos : Vector2
	
	var translated_pos : Vector2 = Vector2(pos.x, pos.z)
	
	translated_pos.x-=HEXAGON_WIDTH
	translated_pos.x/=HEXAGON_WIDTH
	translated_pos.x+=0.5
	
	translated_pos.y/=0.75
	
	var oddRow : bool = false
	if int(translated_pos.y) % 2 == 1:
		oddRow = true
		translated_pos.x += 0.5
	
	var roughY = int(translated_pos.y)
	var roughX = int(translated_pos.x)
	
	var roughPos = Vector2(roughX, roughY)
	
	var rough_world_pos = get_tile_world_pos(Vector2i(roughX, roughY))
	
	finalPos = roughPos
	
	# solve upper triangle cases
	
	#upper most point on the upper triangle in relation to the center of the hexagon
	var A = Vector2(rough_world_pos.x,rough_world_pos.y-0.5)
	#left most point on the upper triangle in relation to the center of the hexagon
	var B = Vector2(rough_world_pos.x-HEXAGON_WIDTH/2,rough_world_pos.y-0.25)
	#right most point on the upper triangle in relation to the center of the hexagon
	var C = Vector2(rough_world_pos.x+HEXAGON_WIDTH/2,rough_world_pos.y-0.25)
	
	if pos.z < B.y:
		if !point_in_triangle(A,B,C,Vector2(pos.x,pos.z)):
			if pos.x < rough_world_pos.x:
				if oddRow:
					finalPos = Vector2(roughPos+Vector2(-1,-1))
				else:
					finalPos = Vector2(roughPos+Vector2(0,-1))
			else:
				if oddRow:
					finalPos = Vector2(roughPos+Vector2(0,-1))
				else:
					finalPos = Vector2(roughPos+Vector2(1,-1))
	
	return finalPos

func point_in_triangle(A : Vector2, B : Vector2, C : Vector2, P : Vector2) -> bool:
	#
	# Massive credit to this video youtu.be/HYAgJN3x4GA?list=PLFt_AvWsXl0cD2LPxcjxVjWTQLxJqKpgZ
	#
	
	var s1 : float = C.y - A.y
	var s2 : float = C.x - A.x
	var s3 : float = B.y - A.y
	var s4 : float = P.y - A.y
	
	var w1 : float = (A.x * s1 + s4 * s2 - P.x * s1) / (s3 * s2 - (B.x-A.x) * s1)
	var w2 : float = (s4- w1 * s3) / s1
	
	return w1 >= 0 and w2 >= 0 and (w1 + w2) <= 1

func get_tile_world_pos(pos : Vector2) -> Vector2:
	
	var x_offset : float = 0
	if (int(pos.y) % 2) == 1:
		x_offset = HEXAGON_WIDTH/2
	
	return Vector2((pos.x*sqrt(3)/2)-(x_offset)+(sqrt(3)/2), pos.y*(3.0/4.0)+0.5)

func inspector_update(_position : Vector2i):
	var info = $"GUI/location Inspector/info"
	var coords = $"GUI/location Inspector/coords"
	
	var x = _position.x
	var y = _position.y
	
	inspector.show()
	
	coords.text = str("Coordinates: ", x, ", ", y)
	
	var controller : String
	
	if Map.tile_map[x][y].controller > 0:
		controller = Map.countries[Map.tile_map[x][y].controller-1].display_name
	else:
		controller = "None"
	
	var building_details = ""
	
	if !Map.tile_map[x][y].building_type.is_empty():
		building_details = str("\nBuilding Details: ", Map.buildings[str(y+(x*Map.size.x))].values)
	
	info.text = str("Terrain: ", Map.tile_map[x][y].terrain_type,
	"\nBuilding: ", Map.tile_map[x][y].building_type,
	building_details,
	"\nController: ", controller)

func pick_starting_city_prompt():
	var starting_city_prompt = preload("res://UI/starting_city_prompt.tscn").instantiate()
	$GUI.add_child(starting_city_prompt)

func open_lobby_prompt():
	var lobby_prompt = preload("res://UI/lobby_prompt.tscn").instantiate()
	$GUI.add_child(lobby_prompt)

func on_set_up_finished():
	print("world setup finished")
	connect("tile_selected", Callable(self, "inspector_update"))
	connect("toggle_minimap", Callable(self, "on_toggle_minimap"))
	connect("toggle_debug", Callable(self, "on_toggle_debug"))
	connect("toggle_command_prompt", Callable(self, "on_toggle_command_prompt"))
	$GUI/Minimap/Area2D.connect("collision", minimap_input_event)

### Minimap

func on_toggle_minimap():
	#print("minimap toggled")
	if minimap.visible:
		minimap.hide()
	else:
		minimap.show()

func minimap_input_event(_a, event, _c):
	#print("minimap_input_event")
	drag = event.position
	if event is InputEventMouseButton:
		if event.is_action_pressed("left_click"):
			minimap_drag = true
		if event.is_action_released("left_click"):
			minimap_drag = false

func update_minimap() -> void:
	minimap_size = Vector2((Map.size.x*HEXAGON_WIDTH*2)+4, (Map.size.y*0.75*2)+4)
	minimap.size = minimap_size
	var screen_size : Vector2 = get_viewport().size
	var minimap_position = Vector2((screen_size.x-minimap_size.x)/2, (screen_size.y-minimap_size.y)/2)
	minimap.position = minimap_position
	$GUI/Minimap/TextureRect.texture = terrain_texture
	$GUI/Minimap/TextureRect.scale = Vector2(HEXAGON_WIDTH*2, 0.75*2)
	$GUI/Minimap/TextureRect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	var collision_position = Vector2(minimap_position.x-2, minimap_position.y-2)
	$GUI/Minimap/Area2D/CollisionShape2D.position = collision_position
	$GUI/Minimap/Area2D/CollisionShape2D.shape.size = minimap_size

func update_camera_outline() -> void:
	var camera_outline_size : Vector2
	var camera_position : Vector2
	var _aspect_ratio : Vector2 = Vector2(get_viewport().size.x, get_viewport().size.y).normalized()
	
	camera_outline_size = Vector2(20,20)
	camera_position = Vector2(camera.position.x*2,camera.position.z*2)
	$GUI/Minimap/camera_outline.size = camera_outline_size
	$GUI/Minimap/camera_outline.position = camera_position
	
	if (minimap_drag):
		print(drag)
		camera.position = Vector3((drag.x-Map.size.x)*HEXAGON_WIDTH, camera.position.y, drag.y*0.75)

func set_camera_position(pos : Vector2):
	camera.position = Vector3(pos.x, camera.position.y, pos.y)

### DEBUG

func on_toggle_debug():
	var debug = $GUI/Debug
	if debug.visible:
		debug.hide()
	else:
		debug.show()

func on_toggle_command_prompt():
	var command_prompt = $GUI/command_prompt
	if command_prompt.visible:
		command_prompt.hide()
	else:
		command_prompt.show()
