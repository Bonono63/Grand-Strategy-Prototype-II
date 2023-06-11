#class_name division

var attack : float #decreases as strength decreases
var defense : float #decreases as strength decreases
var speed : float
var max_strength : float #based on manpower and supply
var actual_strength : float
var morale : float #based on unit supply, damage being taken, and terrain modifiers
var supply : int
var manpower : int
var position : int 
var defense_mod: float #based on terrain
var morale_break: bool = false

var unit : Array = [attack, defense, speed, max_strength, actual_strength, morale, supply, manpower, defense_mod, morale_break, position]



#larger units move slower through difficult terrain (at least until modern era)

func combat(unitA: Array, unitB : Array):
	print("balls")

#func movement(unit: Array):
#	if(unit[10] = )

func overrun(unitA: Array):
	print("diego")
