class_name division

var attack : float #decreases as strength decreases
var defense : float #decreases as strength decreases
var speed : float
var max_strength : float #based on manpower and supply
var actual_strength : float
var morale : float #based on unit supply, damage being taken, and terrain modifiers
var supply : int
var manpower : int
var defense_mod: float #based on terrain

var unit : Array = [attack, defense, speed, max_strength, actual_strength, morale, supply, manpower, defense_mod]



#larger units move slower through difficult terrain (at least until modern era)
#
static func combat(unitA: Array, unitB : Array):
	while (unitA[5] > .85 && unitB[5] > .85):
		print("balls")
