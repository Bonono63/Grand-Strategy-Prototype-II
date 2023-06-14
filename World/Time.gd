extends Node

var day : int
var month : int
var year : int

# 5 speed == 0.25 seconds a day
# 4 speed == 0.5 seconds a day
# 3 speed == 1 second a day
# 2 speed == 2 seconds a day
# 1 speed == 4 seconds a day

enum speeds { QUARTER, HALF, ONE, TWO, FOUR }

var speed : int = 2

func _ready():
	await Map.map_loaded
	reset()
	while(get_tree().paused == false):
		await get_tree().create_timer(check_speed(), false, false, true).timeout
		count_up()

func _process(_delta):
	while ():
		pass
	pass

# counts up game time
func count_up():
	print("count up")
	if day != 30:
		day +=1
	else: 
		if month != 12:
			month +=1
		else:
			year +=1

func reset():
	year = 0
	month = 0
	day = 0

func check_speed() -> float:
	if speed == speeds.QUARTER:
		return 0.25
	if speed == speeds.HALF:
		return 0.5
	if speed == speeds.ONE:
		return 1.0
	if speed == speeds.TWO:
		return 2.0
	if speed == speeds.FOUR:
		return 4.0
	else:
		return 0.0
