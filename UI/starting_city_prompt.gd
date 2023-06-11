extends Panel

var cooldown = 0
const cooldown_reset = 300

func invalid_selection():
	$Label.text = "Invalid Selection"
	cooldown = cooldown_reset

func _process(_delta):
	if cooldown != 0:
		cooldown -= 1
	if cooldown == 0:
		$Label.text = "Select Your Starting location"
