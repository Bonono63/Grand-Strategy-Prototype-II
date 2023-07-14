extends Control

signal building_selected

@onready var building_list = $TabContainer/Construction/Building_selection

var building_queue : Array

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
	

func update_building_queue():
	for _building in building_queue:
		pass

func on_tabs_toggled():
	if $TabContainer.visible:
		$TabContainer.hide()
	else:
		$TabContainer.show()

class queued_building:
	
	pass
