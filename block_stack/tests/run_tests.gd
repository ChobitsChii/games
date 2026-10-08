extends SceneTree
## Führt alle tests/test_*.gd aus.
## Aufruf: godot --headless --path block_stack -s res://tests/run_tests.gd


func _initialize() -> void:
	var total := 0
	var failed := 0
	var paths := _collect_tests("res://tests")
	paths.sort()
	for path in paths:
		var script: GDScript = load(path)
		var instance: TestCase = script.new()
		for info in script.get_script_method_list():
			var test_name: String = info["name"]
			if not test_name.begins_with("test_"):
				continue
			total += 1
			instance.failures.clear()
			instance.call(test_name)
			if instance.failures.is_empty():
				print("  ok    %s::%s" % [path.get_file(), test_name])
			else:
				failed += 1
				print("  FAIL  %s::%s" % [path.get_file(), test_name])
				for failure in instance.failures:
					print("          - " + failure)
	print("%d Tests, %d fehlgeschlagen" % [total, failed])
	quit(1 if failed > 0 else 0)


func _collect_tests(dir_path: String) -> PackedStringArray:
	var result := PackedStringArray()
	for file in DirAccess.get_files_at(dir_path):
		if file.begins_with("test_") and file.ends_with(".gd") and file != "test_case.gd":
			result.append(dir_path.path_join(file))
	return result
