extends SceneTree

const N: int = 1000000
var failures: int = 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var catalog: UnitCatalog = load("res://data/unit_catalog.tres")
	var grades: GradeCatalog = load("res://data/grade_catalog.tres")
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261120
	var type_counts: Dictionary = {}
	var grade_counts: Dictionary = {}
	var joint: Dictionary = {}
	var boundary_counts: Dictionary = {}
	var type_total: float = 0.0
	for data in catalog.units:
		type_counts[data.id] = 0
		type_total += data.weight
		joint[data.id] = {}
		for grade in grades.grades:
			joint[data.id][grade.id] = 0
	for grade in grades.grades:
		grade_counts[grade.id] = 0
		boundary_counts[grade.id] = 0
	for ticket in grades.total_weight():
		boundary_counts[grades.at_ticket(ticket).id] += 1
	for grade in grades.grades:
		check(boundary_counts[grade.id] == grade.weight, "Exact ticket interval " + grade.id)
	check(grades.at_ticket(-1) == null and grades.at_ticket(grades.total_weight()) == null, "Out-of-range tickets rejected")
	for index in N:
		var data: UnitDefinition = catalog.roll(rng)
		var grade: UnitGrade = grades.roll(rng)
		type_counts[data.id] += 1
		grade_counts[grade.id] += 1
		joint[data.id][grade.id] += 1
	for grade in grades.grades:
		var probability: float = grade.weight / float(grades.total_weight())
		var expected: float = N * probability
		check(absf(grade_counts[grade.id] - expected) <= 7 * sqrt(N * probability * (1 - probability)) + 2, "Grade distribution " + grade.id)
		print(grade.id, " = ", grade_counts[grade.id], " / ", N, " (", grade_counts[grade.id] * 100.0 / N, "%)")
	for data in catalog.units:
		var pt: float = data.weight / type_total
		check(absf(type_counts[data.id] - N * pt) <= 7 * sqrt(N * pt * (1 - pt)) + 2, "Type distribution " + data.id)
		for grade in grades.grades:
			var p: float = pt * grade.weight / grades.total_weight()
			check(absf(joint[data.id][grade.id] - N * p) <= 7 * sqrt(N * p * (1 - p)) + 2, "Independent joint distribution " + data.id + "/" + grade.id)
	var result: Dictionary = {"draws": N, "seed": 20261120, "grade_counts": grade_counts, "type_counts": type_counts, "joint_counts": joint, "exact_ticket_counts": boundary_counts, "failures": failures}
	var file := FileAccess.open("res://docs/phase4-probabilities.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("PROBABILITY TEST: ", failures, " failures")
	quit(0 if failures == 0 else 1)
