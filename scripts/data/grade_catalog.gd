class_name GradeCatalog
extends Resource

@export var grades: Array[UnitGrade] = []

func total_weight() -> int:
	var total: int = 0
	for grade in grades:
		total += maxi(grade.weight, 0)
	return total

func at_ticket(ticket: int) -> UnitGrade:
	if ticket < 0:
		return null
	for grade in grades:
		ticket -= maxi(grade.weight, 0)
		if ticket < 0:
			return grade
	return null

func roll(rng: RandomNumberGenerator) -> UnitGrade:
	var total: int = total_weight()
	return at_ticket(rng.randi_range(0, total - 1)) if total > 0 else null
