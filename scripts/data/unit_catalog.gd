class_name UnitCatalog
extends Resource

@export var units: Array[UnitDefinition] = []

func roll(rng: RandomNumberGenerator) -> UnitDefinition:
	var total: float = 0.0
	for unit in units:
		total += maxf(unit.weight, 0.0)
	if total <= 0.0:
		return null
	var value: float = rng.randf() * total
	for unit in units:
		value -= maxf(unit.weight, 0.0)
		if value < 0.0:
			return unit
	return units.back()
