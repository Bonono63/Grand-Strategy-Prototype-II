extends Control

#func _ready():
#	Map.countries[Player.country_id].connect("building_queue_changed", Callable(self, "on_building_queue_changed"))
#	pass
#
#func on_building_queue_changed():
#	print("building queue changed")
#	
#	var index = 0
#	while (index < Map.countries[Player.country_id].building_queue.size()):
#		var _building = Map.countries[Player.country_id].building_queue[index]._building
#		var item = preload("res://UI/Construction/queued_building.tscn").instantiate()
#		
#		item.init(_building, index)
#		item.position = Vector2(0,32*get_child_count())
#		add_child(item)
#		
#		index +=1
