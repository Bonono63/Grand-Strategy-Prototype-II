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
var minimap_size : Vector2 #= Vector2(map.length+4, map.width+4)

func _init():
	seed = randi()
	
	var speed : float
	var attack : float = 100
	var defense : float = 50
	var equipment : float = 5000
	var manpower : float = 5000
	var max_strength : float = (equipment + manpower) / 2
	var actual_strength : float = max_strength 
	var morale : float
	var defense_mod : float
	var unit : Array = [attack, defense, speed, max_strength, actual_strength, morale, equipment, manpower, defense_mod] #simple mock division with all necessary stats
	unitFightingEqual(unit)	
   
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
	$GUI/Minimap/Area2D.connect("collision", minimap_input_event)
	$"World Collision".connect("collision", world_input_event)
	open("res://zero.png")
	generate_terrain_map()
	update_terrain_map()
	world_collision_setup()
	#inspector_update(0,0)
	#save("user://save__01.png")

func _process(_delta):
	update_minimap()
	update_camera_outline()
	#inspector_update(0,0)

#open a previous world
func open(open_path : String) -> void:
	var image : Image
	image = Image.load_from_file(open_path)
	
	map.length = image.get_width()
	map.width = image.get_height()
	
	var terrain : Array
	var building : Array
	var territory : Array
	
	utils.initate_2d_array(terrain, map.length, map.width)
	utils.initate_2d_array(building, map.length, map.width)
	utils.initate_2d_array(territory, map.length, map.width)
	
	for x in map.length:
		for y in map.width:
			var color = image.get_pixel(x,y)
			terrain[x][y] = color.r8
			building[x][y] = color.g8
			territory[x][y] = color.b8
	
	map.terrain = terrain
	map.building = building
	map.territory = territory
	
	print("success loading the world.")
	#print(terrain)

#save the current world
func save(save_path : String) -> void:
	var image : Image
	image = Image.create(map.length, map.width, false, Image.FORMAT_RGB8)
	
	for x in map.length:
		for y in map.width:
			var color : Color
			color.r8 = map.topography[x][y]
			color.g8 = map.building[x][y]
			color.b8 = map.territory[x][y]
			image.set_pixel(x,y,color)
	
	image.save_png(save_path)

#generate a world
func generate_world():
	pass

func generate_terrain_map() -> void:
	var image : Image
	image = Image.create(map.length, map.width, false, Image.FORMAT_RGBA8)
	
	for x in map.length:
		for y in map.width:
			match (map.terrain[x][y]):
				map.terrain_types.plains:
					image.set_pixel(x,y,Color.PALE_GREEN)
				map.terrain_types.forest:
					image.set_pixel(x,y,Color.SEA_GREEN)
				map.terrain_types.desert:
					image.set_pixel(x,y,Color.TAN)
				map.terrain_types.moutains:
					image.set_pixel(x,y,Color.DIM_GRAY)
				map.terrain_types.river:
					image.set_pixel(x,y,Color.ROYAL_BLUE)
				map.terrain_types.shore:
					image.set_pixel(x,y,Color.ROYAL_BLUE)
				map.terrain_types.ocean:
					image.set_pixel(x,y,Color.MEDIUM_BLUE)
				_:
					image.set_pixel(x,y,Color.MEDIUM_BLUE)
	
	var texture : ImageTexture
	texture = ImageTexture.create_from_image(image)
	
	terrain_texture = texture

func update_terrain_map() -> void:
	terrain_renderer.texture = terrain_texture

func update_minimap() -> void:
	minimap_size = Vector2(map.length+4, map.width+4)
	minimap.set_size(minimap_size, false)
	var screen_size : Vector2 = get_viewport().size
	var minimap_position = Vector2(screen_size.x-(minimap_size.x/2), screen_size.y-(minimap_size.y/2))
	minimap.position = Vector2(screen_size.x-minimap_size.x, screen_size.y-minimap_size.y)
	$GUI/Minimap/TextureRect.texture = terrain_texture
	
	var collision_position = Vector2((minimap_size.x/2),(minimap_size.y/2))
	#$GUI/Minimap/Area2D.position = collision_position
	$GUI/Minimap/Area2D/CollisionShape2D.position = collision_position
	#print($GUI/Minimap/Area2D/CollisionShape2D.position)
	$GUI/Minimap/Area2D/CollisionShape2D/ColorRect.position = collision_position
	#print($GUI/Minimap/Area2D/CollisionShape2D/ColorRect.position)
	$GUI/Minimap/Area2D/CollisionShape2D.shape.size = minimap_size
	$GUI/Minimap/Area2D/CollisionShape2D/ColorRect.size = minimap_size

func update_camera_outline() -> void:
	var camera_outline_size : Vector2
	var camera_position : Vector2
	var aspect_ratio : Vector2 = Vector2(get_viewport().size.x, get_viewport().size.y).normalized()
	
	camera_outline_size = Vector2(camera.position.y*aspect_ratio.x,camera.position.y*aspect_ratio.y)
	#camera_inner_size = Vector2(camera.position.y*0.8,camera.position.y*0.8)
	camera_position = Vector2((camera.position.x)-camera_outline_size.x/2,camera.position.z+map.width-camera_outline_size.y/2)
	$GUI/Minimap/camera_outline.size = camera_outline_size
	$GUI/Minimap/camera_outline.position = camera_position
	
	if (minimap_drag):
		var minimap_x = map.length-(get_viewport().size.x-drag.x)
		#print(drag.x)
		#print(minimap_x)
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

func world_input_event(a, event, _position, d, e):
	if event is InputEventMouseButton:
		if event.is_action_pressed("left_click"):
			print("left click, postion: ", _position)
			print("left click, postion (int): (", int(_position.x), ", ", int(_position.y), ", ", int(_position.z), ")")
			inspector_update(int(_position.x),int(_position.z))

func inspector_update(x: int,y : int):
	var info = $"GUI/location Inspector/info"
	var coords = $"GUI/location Inspector/coords"
	
	inspector.show()
	
	var aspect_ratio : Vector2 = Vector2(get_viewport().size.x, get_viewport().size.y).normalized()
	var inspector_size : Vector2 = Vector2(aspect_ratio.x*400, aspect_ratio.y*400)
	inspector.size = inspector_size
	
	var inspector_position : Vector2 = Vector2(0, get_viewport().size.y-inspector_size.y) 
	inspector.position = inspector_position
	
	coords.text = str("Coordinates: ", x, ", ", y)
	#print($"GUI/location Inspector/info".position.x)
	var info_position : Vector2 = Vector2(0, info.position.x+coords.size.y)
	info.position = info_position
	if (map.terrain[x][y] <= map.terrain_types.size()):
		info.text = str("Terrain: ", map.terrain_types.keys()[map.terrain[x][y]])
	else:
		info.text = str("Terrain: none")
