extends Control

signal building_selected

@onready var building_list = $TabContainer/Construction/Building_selection
@onready var building_queue = $"TabContainer/Construction/Building Queue"

func add_building_to_construction_tab(_building : String):
	var building_button = preload("res://UI/Construction/building_selection_button.tscn").instantiate()
	building_button.tooltip_text = _building
	building_button._building = _building
	building_button.connect("building_selected", Callable(self, "on_building_selected"))
	building_list.add_child(building_button)

func on_building_selected(_building : String):
	emit_signal("building_selected", _building)

func _ready():
	$toggle_tabs.connect("button_down", Callable(self, "on_tabs_toggled"))
	
	for _building in Map.building_types:
		add_building_to_construction_tab(_building)
	
	Map.countries[Player.country_id].connect("building_queue_changed", Callable(self, "update_building_queue"))

func update_building_queue():
	for child in building_queue.get_children():
		child.queue_free()
	
	var index = 0
	var offset = 0
	while (index < Map.countries[Player.country_id].building_queue.size()):
		var _building = Map.countries[Player.country_id].building_queue[index]
		var item = preload("res://UI/Construction/queued_building.tscn").instantiate()
		
		item.init(_building._building, index, )
		item.position = Vector2(0,(32*index)+(offset*index))
		building_queue.add_child(item)
		
		index+=1

func on_tabs_toggled():
	if $TabContainer.visible:
		$TabContainer.hide()
	else:
		$TabContainer.show()

class queued_building:
	
	pass
