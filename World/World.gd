extends Node3D

var seed
var map = _map.new()
@onready var terrain_renderer = $Terrain
@onready var minimap = $GUI/Minimap
@onready var camera = $Camera
@onready var inspector = $"GUI/location Inspector"
var terrain_texture : ImageTexture
var minimap_drag = false
var drag : Vector2
var minimap_size : Vector2

@export_range(0,1) var sea_level = .4
@export_range(0,1) var coast_height = .475
@export_range(0,1) var shore_height = .5
@export_range(0,1) var mountain_height = .8

@export_range(0,1) var cold_cutoff = .35
@export_range(0,1) var warm_cutoff = .65

@export_range(0,1) var dry_cutoff = .65
@export_range(0,1) var moist_cutoff = .8

@export_range(0,1) var river_moisture_cutoff = .875
@export_range(0,1) var river_cutoff = .955
@export_range(0,1) var river_moisture_addition = 0.25

var pause : bool

# initialize the world settings etc. (basically decide whether to load or generate a world)
func init(_save : String):
	if _save.is_empty():
		generate_world(Vector2(512,512),seed)
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
	map.connect("map_loaded", Callable(self, "on_map_loaded"))

func on_minimap_toggle():
	if minimap.visible:
		minimap.hide()
	else:
		minimap.show()

func on_map_loaded():
	print("map loaded")
	$GUI/Minimap/Area2D.connect("collision", minimap_input_event)
	$GUI/minimap_toggle.connect("button_down", on_minimap_toggle)
	$"World Collision".connect("collision", world_input_event)
	generate_terrain_map()
	update_terrain_map()
	world_collision_setup()

func on_generate_map_texture():
	terrain_renderer.texture = terrain_texture

func _process(_delta):
	update_minimap()
	update_camera_outline()

#open a previous world
func open(open_path : String) -> void:
	print("opening ", open_path)
	var image : Image
	image = Image.load_from_file(open_path)
	
	map.length = image.get_width()
	map.width = image.get_height()
	
	var terrain : Array
	#var building : Array
	#var territory : Array
	
	utils.initate_2d_array(terrain, map.length, map.width)
	#utils.initate_2d_array(building, map.length, map.width)
	#utils.initate_2d_array(territory, map.length, map.width)
	
	for x in map.length:
		for y in map.width:
			var color : Color = image.get_pixel(x,y)
			terrain[x][y] = color.r8
			#building[x][y] = color.g8
			#territory[x][y] = color.b8
	
	map.terrain = terrain
	
	#PAIN
	await ready
	
	map.emit_signal("map_loaded")

#save the current world
func save(save_path : String) -> void:
	var image : Image
	image = Image.create(map.length, map.width, false, Image.FORMAT_RGBA8)
	
	for x in map.length:
		for y in map.width:
			var color : Color
			color.r8 = map.terrain[x][y]
			
			# TODO Save buildings and territory to the save file
			#color.g8 = map.building[x][y]
			#color.b8 = map.territory[x][y]
			image.set_pixel(x,y,color)
	
	image.save_png("user://"+save_path+".png")
	print("game saved to: ", "user://", save_path)

enum moisture { DRY, MOIST, WET }
enum temperature { COLD, WARM, HOT }

#generate a world
func generate_world(size : Vector2i , _seed : int):
	print("generating world")
	map.length = int(size.x)
	map.width = int(size.y)
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
	
	var terrain : Array
	utils.initate_2d_array(terrain, size.x, size.y)
	
	for x in size.x:
		for y in size.y:
			
			#ocean
			if height_image.get_pixel(x,y).r <= sea_level:
				terrain[x][y] = map.terrain_types.ocean
			
			#coast
			else :if height_image.get_pixel(x,y).r <= coast_height:
				terrain[x][y] = map.terrain_types.shallow_water
			
			#river gen
			else :if river_image.get_pixel(x,y).r >= river_cutoff:
				terrain[x][y] = map.terrain_types.shallow_water
			
			#shore
			else: if height_image.get_pixel(x,y).r <= shore_height:
				terrain[x][y] = map.terrain_types.shore
			
			#moutains
			else: if height_image.get_pixel(x,y).r >= mountain_height:
				terrain[x][y] = map.terrain_types.mountain
			
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
								terrain[x][y] = map.terrain_types.desert # desert
							temperature.WARM:
								terrain[x][y] = map.terrain_types.plains # plains
					moisture.MOIST:
						match temp:
							temperature.HOT:
								terrain[x][y] = map.terrain_types.plains # plains
							temperature.WARM:
								terrain[x][y] = map.terrain_types.forest # forest
					moisture.WET:
						match temp:
							temperature.HOT:
								terrain[x][y] = map.terrain_types.jungle # jungle
							temperature.WARM:
								terrain[x][y] = map.terrain_types.swamp # swamp
	
	map.terrain = terrain
	
	map.emit_signal("map_loaded")

func generate_terrain_map() -> void:
	var image : Image = Image.create(map.length, map.width, false, Image.FORMAT_RGBA8)
	
	for x in map.length:
		for y in map.width:
			match (map.terrain[x][y]):
				map.terrain_types.ocean:
					image.set_pixel(x,y,Color.DARK_BLUE) # ocean
				map.terrain_types.shallow_water:
					image.set_pixel(x,y,Color(0.1, 0.5, 0.6, 1)) # coast
				map.terrain_types.shore:
					image.set_pixel(x,y,Color("eddfa8")) # shore
				map.terrain_types.mountain:
					image.set_pixel(x,y,Color.DIM_GRAY) # mountain
				map.terrain_types.plains:
					image.set_pixel(x,y,Color.LAWN_GREEN) # plains
				map.terrain_types.forest:
					image.set_pixel(x,y,Color.DARK_GREEN) # forest
				map.terrain_types.swamp:
					image.set_pixel(x,y,Color("6d490f")) # swamp
				map.terrain_types.desert:
					image.set_pixel(x,y,Color(1, 0.870588, 0.501961, 1)) # desert
				map.terrain_types.jungle:
					image.set_pixel(x,y,Color("008264")) # jungle
				_:
					image.set_pixel(x,y,Color.TRANSPARENT)
	
	var texture : ImageTexture = ImageTexture.create_from_image(image)
	texture.update(image)
	
	terrain_texture = texture

func update_terrain_map() -> void:
	terrain_renderer.texture = terrain_texture

func update_minimap() -> void:
	minimap_size = Vector2(map.length+4, map.width+4)
	minimap.set_size(minimap_size, false)
	var screen_size : Vector2 = get_viewport().size
	minimap.position = Vector2(screen_size.x-minimap_size.x, screen_size.y-minimap_size.y)
	$GUI/Minimap/TextureRect.texture = terrain_texture
	
	var collision_position = Vector2((minimap_size.x/2),(minimap_size.y/2))
	$GUI/Minimap/Area2D/CollisionShape2D.position = collision_position
	$GUI/Minimap/Area2D/CollisionShape2D.shape.size = minimap_size

func update_camera_outline() -> void:
	var camera_outline_size : Vector2
	var camera_position : Vector2
	var aspect_ratio : Vector2 = Vector2(get_viewport().size.x, get_viewport().size.y).normalized()
	
	camera_outline_size = Vector2(camera.position.y*aspect_ratio.x,camera.position.y*aspect_ratio.y)
	camera_position = Vector2((camera.position.x)-camera_outline_size.x/2,camera.position.z+map.width-camera_outline_size.y/2)
	$GUI/Minimap/camera_outline.size = camera_outline_size
	$GUI/Minimap/camera_outline.position = camera_position
	
	if (minimap_drag):
		var minimap_x = map.length-(get_viewport().size.x-drag.x)
		camera.position = Vector3(minimap_x, camera.position.y, drag.y-get_viewport().size.y)

func minimap_input_event(_a, event, _c):
	drag = event.position
	if event is InputEventMouseButton:
		if event.is_action_pressed("left_click"):
			minimap_drag = true
		if event.is_action_released("left_click"):
			minimap_drag = false

func world_collision_setup():
	#print("length: ", map.length, " width: ", map.width)
	var collision_shape : Vector3 = Vector3(map.length, 0, map.width)
	$"World Collision/CollisionShape3D".shape.size = collision_shape
	
	$"World Collision/CollisionShape3D".position.x = map.length/2
	$"World Collision/CollisionShape3D".position.y = map.width/2

func world_input_event(_a, event, _position, _d, _e):
	if event is InputEventMouseButton:
		if event.is_action_released("left_click"):
			inspector_update(int(_position.x),int(_position.z))

func inspector_update(x: int,y : int):
	var info = $"GUI/location Inspector/info"
	var coords = $"GUI/location Inspector/coords"
	
	y-=1
	
	inspector.show()
	
	var aspect_ratio : Vector2 = Vector2(get_viewport().size.x, get_viewport().size.y).normalized()
	var inspector_size : Vector2 = Vector2(aspect_ratio.x*400, aspect_ratio.y*400)
	inspector.size = inspector_size
	
	var inspector_position : Vector2 = Vector2(0, get_viewport().size.y-inspector_size.y) 
	inspector.position = inspector_position
	
	coords.text = str("Coordinates: ", x+1, ", ", abs(y))
	var info_position : Vector2 = Vector2(0, info.position.x+coords.size.y)
	info.position = info_position
	if (map.terrain[x][y] <= map.terrain_types.size()):
		info.text = str("Terrain: ", map.terrain_types.keys()[map.terrain[x][y]])
	else:
		info.text = str("Terrain: none")
