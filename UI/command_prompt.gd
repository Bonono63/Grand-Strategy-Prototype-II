extends Panel

@onready var output = $Label
func _ready():
	$LineEdit.connect("text_submitted", Callable(self, "input_parser"))

func input_parser(command : String) -> int:
	var parameters = argument_parser(command)
	match parameters[0]:
		"clear":
			clear()
		"set_terrain":
			Queue.add_command(Queue.types.set_terrain, {"x":int(parameters[1]),"y":int(parameters[2]),"terrain_type":int(parameters[3])})
			out(str("terrain set to ", parameters[3], " at ", parameters[1], ", ", parameters[2],"\n"))
		"set_territory":
			Queue.add_command(Queue.types.set_territory, {"x":int(parameters[1]),"y":int(parameters[2]),"controller_id":int(parameters[3])})
			out(str("controller of ", parameters[1], ", ", parameters[2], " set to ", parameters[3],"\n"))
		"set_building":
			Queue.add_command(Queue.types.construct_building, {"x":int(parameters[1]),"y":int(parameters[2]),"building_type":parameters[3]})
			out(str("building set to ", parameters[3], " at ", parameters[1], ", ", parameters[2],"\n"))
		"close":
			hide()
		"hide":
			hide()
		"exit":
			hide()
		"":
			pass
		_:
			out("That command doesn't exist.\n")
	input_clear()
	return 0

func argument_parser(input : String) -> Array:
	var _out : Array
	for x in 10:
		_out.append("")
	
	var argumant_index : int = 0
	for x in input:
		if x != " ":
			_out[argumant_index]+=x
		else:
			argumant_index +=1
	return _out

func error(_error : String):
	output.text += _error

func out(_out : String):
	output.text += _out

func clear() -> void:
	output.text = ""

func input_clear() -> void:
	$LineEdit.text = ""
