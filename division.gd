var attack : float #decreases as strength decreases
var defense : float #decreases as strength decreases
var speed : float
var morale : float #based on unit supply, damage being taken, and terrain modifiers
var max_strength : float #based on manpower and supply
var actual_strength : float
var supply : int
var manpower : int
var position : int 
var defense_mod: float #based on terrain
var morale_break: bool = false
var exists: bool = false

var unit : Array = [exists, position, attack, defense, speed, max_strength, actual_strength, morale, supply, manpower, defense_mod]

func create(unit: Array): #creates a unit and assigns it stats
	var starting_position = null 
	unit = [true, starting_position, null, null, null, null, null, null, null, null, null]

func selected():
	pass

func move(): 
	pass

func combat(unitA: Array, unitB : Array):
	pass
