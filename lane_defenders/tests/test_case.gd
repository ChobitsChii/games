class_name TestCase
extends RefCounted
## Minimale Basisklasse für Tests (ohne externes Framework).
## Testmethoden heißen test_* und werden von run_tests.gd aufgerufen.

var failures: PackedStringArray = []


func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		failures.append(message if message != "" else "Bedingung ist nicht wahr")


func assert_false(condition: bool, message: String = "") -> void:
	if condition:
		failures.append(message if message != "" else "Bedingung ist nicht falsch")


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual != expected:
		failures.append("%s erwartet %s, erhalten %s" % [message, str(expected), str(actual)])


func assert_almost(actual: float, expected: float, message: String = "", epsilon: float = 0.001) -> void:
	if absf(actual - expected) > epsilon:
		failures.append("%s erwartet %f, erhalten %f" % [message, expected, actual])


## Alle Dateien mit einer Endung unterhalb eines Verzeichnisses (rekursiv).
func list_files(dir_path: String, extension: String) -> PackedStringArray:
	var result := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return result
	for sub in dir.get_directories():
		if not sub.begins_with("."):
			result.append_array(list_files(dir_path.path_join(sub), extension))
	for file in dir.get_files():
		if file.ends_with(extension):
			result.append(dir_path.path_join(file))
	return result
