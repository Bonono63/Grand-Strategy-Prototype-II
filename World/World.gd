extends Node3D

var seed
#@onready var terrain_renderer = $Terrain
@onready var minimap = $GUI/Minimap
@onready var camera = $Camera
@onready var inspector = $"GUI/location Inspector"
var minimap_drag = false
var drag : Vector2
var minimap_size : Vector2

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

var terrain_texture : ImageTexture

const hexagon_width = sqrt(3)
const hexagon_half_width = sqrt(3)/2

var sand_color = Color(1, 0.870588, 0.501961, 1)

var pause : bool

signal tile_selected
signal starting_city_selection

signal finish_setup

# initialize the world settings etc. (basically decide whether to load or generate a world)
func init(size : Vector2i, _save : String):
	Queue.clear_queue()
	Map.clear(size)
	if _save.is_empty():
		generate_world(size,seed)
	else:
		open(_save)

func _init():
	seed = randi()
	
	#var speed : float
	#var attack : float = 100
	#var defense : float = 50
	#var equipment : float = 5000
	#var manpower : float = 5000
	#var max_strength : float = (equipment + manpower) / 2
	#var actual_strength : float = max_strength 
	#var morale : float
	#var defense_mod : float
	#var unit : Array = [attack, defense, speed, max_strength, actual_strength, morale, equipment, manpower, defense_mod] #simple mock division with all necessary stats
	#unitFightingEqual(unit)
	#var unitA = [100, 50, 10, 1, 1, 1, 5000, 5000, null]
	#var unitB = [50, 25, 20, 1, 1, 1, 2500, 2500, null]
	#division.combat(unitA, unitB

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

# can be called anywhere to return to the main menu
func return_to_main_menu():
	get_tree().change_scene_to_file("res://Menus/main_menu.tscn")
	self.queue_free()

func unitFightingEqual(unit : Array): #simulates combat between 2 units with the same stats
	var combat_cycles : int
	
	unit[2] = unit[4] / unit[3] #morale is equal to the ratio of actual_strength and max_strength
	
	while(unit[2] >= .85): #when a unit loses more than 15% morale it retreats (designed for medieval combat)
		var damage : float = unit [0] - unit [1] #damage = enemy attack - unit defense
		unit[4] = unit[4] - damage #new unit strength after damage is applied
		unit[2] = unit[4] / unit[3]
		combat_cycles+=1
		print(unit[2], " morale")
	
	print(combat_cycles , " combat cycles")
	print(unit[4], " unit's remaining strength") 

func _ready():
	Map.connect("map_loaded", Callable(self, "on_map_loaded"))

func on_minimap_toggle():
	if minimap.visible:
		minimap.hide()
	else:
		minimap.show()

func on_map_loaded():
	print("map loaded")
	$GUI/Minimap/Area2D.connect("collision", minimap_input_event)
	$GUI/minimap_toggle.connect("button_down", on_minimap_toggle)
	$"Map Input Events".connect("input_event", world_input_event)
	setup_multimesh_mesh()
	generate_terrain_map()
	world_collision_setup()
	
	Map.connect("tile_map_change", Callable(self, "on_tile_map_update"))
	
	connect("tile_selected", Callable(self, "inspector_update"))
	pick_starting_city_prompt()
	get_tile_world_pos(Vector2(0,0))

func on_tile_map_update(coordinates : Vector2i):
	#generate_terrain_map()
	#update_terrain_map()
	pass

#func on_generate_map_texture():
	#terrain_renderer.texture = terrain_texture

func _process(_delta):
	update_minimap()
	update_camera_outline()

#open a previous world
func open(open_path : String) -> void:
	print("opening ", open_path)
	var image : Image
	image = Image.load_from_file(open_path)
	
	Map.length = image.get_width()
	Map.width = image.get_height()
	
	var tile_map : Array
	utils.initate_2d_array(tile_map, Map.length, Map.width)
	
	for x in Map.length:
		for y in Map.width:
			var color : Color = image.get_pixel(x,y)
			var _tile = tile.new()
			_tile.terrain_type = color.r8
			_tile.building.type = color.g8
			_tile.controller = color.b8
			
			tile_map[x][y] = _tile
	
	Map.tile_map = tile_map
	
	#PAIN
	await ready
	
	Map.emit_signal("map_loaded")

#save the current world
func save(save_path : String) -> void:
	var image : Image
	image = Image.create(Map.length, Map.width, false, Image.FORMAT_RGBA8)
	
	for x in Map.length:
		for y in Map.width:
			var color : Color
			#tile type
			color.r8 = Map.tile_map[x][y].terrain_type
			#building type
			color.g8 = Map.tile_map[x][y].building.type
			#controller type
			color.b8 = Map.tile_map[x][y].controller
			image.set_pixel(x,y,color)
	
	image.save_png("user://"+save_path+".png")
	print("game saved to: ", "user://", save_path)

enum moisture { DRY, MOIST, WET }
enum temperature { COLD, WARM, HOT }

#generate a world
func generate_world(size : Vector2i , _seed : int):
	print("generating world")
	Map.length = int(size.x)
	Map.width = int(size.y)
	#print(map.length)
	#print(map.width)
	
	var height_map_noise = FastNoiseLite.new()
	var moisture_map_noise = FastNoiseLite.new()
	var temperature_map_noise = FastNoiseLite.new()
	var river_map_noise = FastNoiseLite.new()
	
	moisture_map_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	height_map_noise.seed = randi()
	height_map_noise.frequency = 0.0075
	height_map_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	
	moisture_map_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	moisture_map_noise.seed = randi()
	moisture_map_noise.frequency = 0.0075
	
	temperature_map_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	temperature_map_noise.seed = randi()
	temperature_map_noise.frequency = 0.0075
	
	river_map_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	river_map_noise.seed = randi()
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
	
	var tile_map : Array
	utils.initate_2d_array(tile_map, size.x, size.y)
	
	for x in size.x:
		for y in size.y:
			var _tile = tile.new()
			#ocean
			if height_image.get_pixel(x,y).r <= sea_level:
				_tile.terrain_type = Map.terrain_types.ocean
			
			#coast
			else :if height_image.get_pixel(x,y).r <= coast_height:
				_tile.terrain_type = Map.terrain_types.shallow_water
			
			#river gen
			else :if river_image.get_pixel(x,y).r >= river_cutoff:
				_tile.terrain_type = Map.terrain_types.shallow_water
			
			#shore
			else: if height_image.get_pixel(x,y).r <= shore_height:
				_tile.terrain_type = Map.terrain_types.shore
			
			#moutains
			else: if height_image.get_pixel(x,y).r >= mountain_height:
				_tile.terrain_type = Map.terrain_types.mountain
			
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
								_tile.terrain_type = Map.terrain_types.desert # desert
							temperature.WARM:
								_tile.terrain_type = Map.terrain_types.plains # plains
					moisture.MOIST:
						match temp:
							temperature.HOT:
								_tile.terrain_type = Map.terrain_types.plains # plains
							temperature.WARM:
								_tile.terrain_type = Map.terrain_types.forest # forest
					moisture.WET:
						match temp:
							temperature.HOT:
								_tile.terrain_type = Map.terrain_types.jungle # jungle
							temperature.WARM:
								_tile.terrain_type = Map.terrain_types.swamp # swamp
			tile_map[x][y] = _tile
	
	Map.tile_map = tile_map
	
	Map.emit_signal("map_loaded")

func setup_multimesh_mesh():
	var mesh_data = []
	mesh_data.resize(ArrayMesh.ARRAY_MAX)
	mesh_data[ArrayMesh.ARRAY_VERTEX] = PackedVector3Array(
		[
			Vector3(0,0,0),
			Vector3(0,0,0.5),
			Vector3(sqrt(3)/4,0,0.25),
			Vector3(sqrt(3)/4,0,-0.25),
			Vector3(0,0,-0.5),
			Vector3(-sqrt(3)/4,0,-0.25),
			Vector3(-sqrt(3)/4,0,0.25),
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
	
	$"Terrain MultiMesh".multimesh.mesh = ArrayMesh.new()
	$"Terrain MultiMesh".multimesh.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data)

func generate_terrain_map() -> void:
	$"Terrain MultiMesh".multimesh.instance_count = Map.length * Map.width 
	#fcd062 fcbe49
	var sand_color = Color("fcbe49")
	
	var id : int = 0
	for x in Map.length:
		for z in Map.width:
			
			var x_offset : float = 0
			if (z % 2) == 1:
				x_offset = hexagon_half_width/2
			
			var instance_transform : Vector3 = Vector3(x*(sqrt(3)/2)-(x_offset)+(sqrt(3)/2),0,-z*(3.0/4.0)-0.5)
			
			$"Terrain MultiMesh".multimesh.set_instance_transform(id, Transform3D(Basis(), Vector3(instance_transform)))
			#$"Terrain MultiMesh".multimesh.set_instance_color(id, color)
			$"Terrain MultiMesh".multimesh.set_instance_color(id, get_tile_color(Vector2i(x,z)))
			id+=1
	
	var image : Image = Image.create(Map.length, Map.width, false, Image.FORMAT_RGBA8)
	
	#var sand_color = Color(1, 0.870588, 0.501961, 1)
	
	for x in Map.length:
		for y in Map.width:
			image.set_pixel(x,y,get_tile_color(Vector2i(x,y)))
	
	var texture : ImageTexture = ImageTexture.create_from_image(image)
	texture.update(image)
	
	terrain_texture = texture

func set_color(coordinates : Vector2i, color : Color):
	var id = coordinates.y+(coordinates.x*Map.width)
	$"Terrain MultiMesh".multimesh.set_instance_color(id, color)

func get_color(coordinates : Vector2i) -> Color:
	var id = coordinates.y+(coordinates.x*Map.width)
	return $"Terrain MultiMesh".multimesh.get_instance_color(id)

func get_tile_color(pos : Vector2i) -> Color:
	match (Map.tile_map[pos.x][pos.y].terrain_type):
		Map.terrain_types.ocean:
			return Color("020873") # ocean
		Map.terrain_types.shallow_water:
			return Color("449dd1") # coast
		Map.terrain_types.shore:
			return Color(sand_color) # shore
		Map.terrain_types.mountain:
			return Color("585858") # mountain
		Map.terrain_types.plains:
			return Color("4daa13") # plains
		Map.terrain_types.forest:
			return Color("226c00") # forest
		Map.terrain_types.swamp:
			return Color("854d27") # swamp
		Map.terrain_types.desert:
			return Color(sand_color) # desert
		Map.terrain_types.jungle:
			return Color("053225") # jungle
		_:
			return Color.TRANSPARENT # other

func update_minimap() -> void:
	minimap_size = Vector2((Map.length+4)*0.75, (Map.width+4)*(0.866))
	minimap.set_size(minimap_size, false)
	var screen_size : Vector2 = get_viewport().size
	minimap.position = Vector2(screen_size.x-minimap_size.x, screen_size.y-minimap_size.y)
	$GUI/Minimap/TextureRect.texture = terrain_texture
	$GUI/Minimap/TextureRect.size = minimap_size
	
	var collision_position = Vector2((minimap_size.x/2),(minimap_size.y/2))
	$GUI/Minimap/Area2D/CollisionShape2D.position = collision_position
	$GUI/Minimap/Area2D/CollisionShape2D.shape.size = minimap_size

func update_camera_outline() -> void:
	var camera_outline_size : Vector2
	var camera_position : Vector2
	var aspect_ratio : Vector2 = Vector2(get_viewport().size.x, get_viewport().size.y).normalized()
	
	camera_outline_size = Vector2(camera.position.y*aspect_ratio.x,camera.position.y*aspect_ratio.y)
	camera_position = Vector2((camera.position.x)-camera_outline_size.x/2,camera.position.z+Map.width-camera_outline_size.y/2)
	$GUI/Minimap/camera_outline.size = camera_outline_size
	$GUI/Minimap/camera_outline.position = camera_position
	
	if (minimap_drag):
		var minimap_x = Map.length-(get_viewport().size.x-drag.x)
		camera.position = Vector3(minimap_x, camera.position.y, drag.y-get_viewport().size.y)

func minimap_input_event(_a, event, _c):
	drag = event.position
	if event is InputEventMouseButton:
		if event.is_action_pressed("left_click"):
			minimap_drag = true
		if event.is_action_released("left_click"):
			minimap_drag = false

func world_collision_setup():
	#var num = 0
	#for x in Map.length:
	#	for y in Map.width:
	#		
	#		var y_offset : float = 0
	#		if (x % 2) == 0:
	#			y_offset = sqrt(3)/2
	#		
	#		var _tile = preload("res://World/tile.tscn").instantiate()
	#		_tile.position = Vector3((x*(2*(3.0/4.0))),0,-((y*hexagon_width)-(y_offset)))
	#		_tile.init(Vector2i(x,y))
	#		$"World Collision".add_child(_tile)
	#		_tile.connect("input_event", Callable($"World Collision", "on_input_event"))
	#		print(num)
	#		num+=1
	
	#print(Map.terrain_types.keys()[Map.tile_map[0][0].terrain_type])
	
	#print("length: ", map.length, " width: ", map.width)
	var collision_shape : Vector3 = Vector3((Map.length*0.75)+sqrt(3)/7, 0, (Map.width*sqrt(3)/2)+hexagon_half_width/2)
	var collision_position : Vector3 = Vector3((collision_shape.x/2), 0.001, (collision_shape.z/2))
	print(collision_position)
	
	#$"Map Input Events/MeshInstance3D".position = collision_position
	#$"Map Input Events/CollisionShape3D".position = collision_position
	
	$"Map Input Events/CollisionShape3D".shape.size = collision_shape
	$"Map Input Events/MeshInstance3D".mesh.size = collision_shape

var prev_input_pos : Vector2i

func world_input_event(_a, event, _position, _d, _e):
	if event is InputEventMouseButton:
		if event.is_action_released("left_click"):
			print("_position ",_position)
			var transformed = transform_input_position(_position)
			print("transformed ", transformed)
			if _position.x > 0 and _position.z > 0:
				if prev_input_pos != null:
					set_color(prev_input_pos, get_tile_color(prev_input_pos))
				set_color(Vector2i(transformed.x, transformed.z), "ed2e21")
				prev_input_pos = Vector2i(transformed.x, transformed.z)

# Code adapted from https://www.youtube.com/watch?v=0nXmuJuWS8I
func transform_input_position(pos : Vector3) -> Vector3:
	
	var original = pos
	
	pos.x-=sqrt(3)/2
	pos.x/=sqrt(3)/2
	pos.x+=0.5
	
	pos.z/=0.75
	
	var oddRow : bool = false
	if int(pos.z) % 2 == 1:
		oddRow = true
		#print("odd")
		pos.x += 0.5
	
	print("translated pos: ",pos)
	
	var roughZ = int(pos.z)
	var roughX = int(pos.x)
	
	print("Rough x: ",roughX, " z: ", roughZ)
	
	var roughPos = Vector3i(roughX, 0, roughZ)
	
	var neighbors : Array = [
		Vector3i(roughPos+Vector3i(-1,0,+0)),
		Vector3i(roughPos+Vector3i(+1,0,+0)),
		
		Vector3i(roughPos+Vector3i(+0,0,+1)),
		Vector3i(roughPos+Vector3i(+0,0,-1))
	]
	
	if oddRow:
		neighbors.append(Vector3i(roughPos+Vector3i(+1,0,+1)))
		neighbors.append(Vector3i(roughPos+Vector3i(+1,0,-1)))
	else:
		neighbors.append(Vector3i(roughPos+Vector3i(-1,0,+1)))
		neighbors.append(Vector3i(roughPos+Vector3i(-1,0,-1)))
	
	var closestPos : Vector3 = pos
	
	for neighbor in neighbors:
		print("pos: ", pos)
		print(neighbor, " tile location: ",get_tile_world_pos(Vector2i(neighbor.x, neighbor.z)))
		print(pos.distance_to(get_tile_world_pos(Vector2i(neighbor.x, neighbor.z))))
		print(pos.distance_to(get_tile_world_pos(Vector2i(closestPos.x, closestPos.z))))
		if pos.distance_to(get_tile_world_pos(Vector2i(neighbor.x, neighbor.z))) < pos.distance_to(get_tile_world_pos(Vector2i(closestPos.x, closestPos.z))):
			closestPos = neighbor
			print(closestPos)
	
	return closestPos

func get_tile_world_pos(pos : Vector2i) -> Vector3:
	
	var x_offset : float = 0
	if (pos.y % 2) == 1:
		x_offset = hexagon_half_width/2
	
	return Vector3((pos.x*sqrt(3)/2)-(x_offset)+(sqrt(3)/2),0,-pos.y*(3.0/4.0)-0.5)

func inspector_update(_position : Vector2i):
	var info = $"GUI/location Inspector/info"
	var coords = $"GUI/location Inspector/coords"
	
	var x = _position.x
	var y = _position.y
	
	inspector.show()
	
	var aspect_ratio : Vector2 = Vector2(get_viewport().size.x, get_viewport().size.y).normalized()
	var inspector_size : Vector2 = Vector2(aspect_ratio.x*400, aspect_ratio.y*400)
	inspector.size = inspector_size
	
	var inspector_position : Vector2 = Vector2(0, get_viewport().size.y-inspector_size.y) 
	inspector.position = inspector_position
	
	coords.text = str("Coordinates: ", x+1, ", ", abs(y))
	var info_position : Vector2 = Vector2(0, info.position.x+coords.size.y)
	info.position = info_position
	
	info.text = str("Terrain: ", Map.terrain_types.keys()[Map.tile_map[x][y].terrain_type], "\nBuilding: ", Map.building_types.keys()[Map.tile_map[x][y].building.type], "\nController: ", Map.tile_map[x][y].controller)

func pick_starting_city_prompt():
	var starting_city_prompt = preload("res://UI/starting_city_prompt.tscn").instantiate()
	$GUI.add_child(starting_city_prompt)
