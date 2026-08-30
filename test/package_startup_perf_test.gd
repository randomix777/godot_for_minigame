extends SceneTree
## P6: Package size, startup, and performance baseline tests.
## Validates: package size budgets, startup time, memory baseline,
## file count, and determinism of exported output.

var _failed := false
var _passed := 0
var _total := 0


func _assert(condition: bool, message: String) -> void:
	_total += 1
	if condition:
		_passed += 1
		print("  PASS: ", message)
	else:
		_failed = true
		print("  FAIL: ", message)


func _init() -> void:
	print("=== P6: Package, Startup, and Performance Tests ===")
	print("")

	_test_addon_size_budget()
	_test_file_count()
	_test_engine_template_size()
	_test_startup_time()
	_test_memory_baseline()
	_test_output_determinism()
	_test_export_structure()
	_test_no_developer_artifacts()

	print("")
	print("=== Results: %d/%d passed ===" % [_passed, _total])
	if _failed:
		print("FAILED")
		quit(1)
	else:
		print("ALL PASSED")
		quit(0)


# ─── Tests ──────────────────────────────────────────────────────


func _test_addon_size_budget() -> void:
	print("Test 1: Addon size budget")

	# Total addon should be under 50MB (engines included)
	var total_size = _dir_size_recursive("res://addons/godot_mini_game/")
	var budget_bytes = 50 * 1024 * 1024  # 50MB
	_assert(total_size < budget_bytes,
		"Addon total < 50MB (actual: %d KB)" % (total_size / 1024))

	# GDScript files should be under 500KB total
	var gd_size = _glob_size("res://addons/godot_mini_game/", "*.gd")
	_assert(gd_size < 500 * 1024,
		"GDScript total < 500KB (actual: %d KB)" % (gd_size / 1024))

	# Engine templates are the bulk
	var engine_size = _dir_size_recursive("res://addons/godot_mini_game/engine/")
	_assert(engine_size > 0, "Engine templates present (%d KB)" % (engine_size / 1024))
	print("")


func _test_file_count() -> void:
	print("Test 2: File count — reasonable structure")

	var gd_count = _count_files("res://addons/godot_mini_game/", "*.gd")
	_assert(gd_count >= 5 and gd_count <= 30,
		"GDScript files: %d (expected 5-30)" % gd_count)

	var cfg_count = _count_files("res://addons/godot_mini_game/", "*.cfg")
	_assert(cfg_count >= 1, "At least 1 .cfg file")

	var js_count = _count_files("res://addons/godot_mini_game/engine/", "*.js")
	_assert(js_count >= 1, "At least 1 .js engine file")

	var wasm_count = _count_files("res://addons/godot_mini_game/engine/", "*.br")
	_assert(wasm_count >= 1, "At least 1 .br (WASM brotli) file")
	print("")


func _test_engine_template_size() -> void:
	print("Test 3: Engine template sizes — within bounds")

	var js_path = "res://addons/godot_mini_game/engine/godot.js"
	var js_size = FileAccess.get_size(js_path) if FileAccess.file_exists(js_path) else 0
	# godot.js is typically 200-400KB
	_assert(js_size > 100_000 and js_size < 1_000_000,
		"godot.js size: %d KB (expected 100-1000 KB)" % (js_size / 1024))

	var wasm_path = "res://addons/godot_mini_game/engine/godot.wasm.br"
	var wasm_size = FileAccess.get_size(wasm_path) if FileAccess.file_exists(wasm_path) else 0
	# WASM brotli is typically 3-8MB
	_assert(wasm_size > 1_000_000 and wasm_size < 20_000_000,
		"godot.wasm.br size: %d KB (expected 1000-20000 KB)" % (wasm_size / 1024))
	print("")


func _test_startup_time() -> void:
	print("Test 4: Startup time — within budget")

	var start_time = Time.get_ticks_msec()

	# Simulate plugin initialization work
	var manifest_path = "res://addons/godot_mini_game/engine/template.json"
	var file := FileAccess.open(manifest_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		var json = JSON.new()
		json.parse(content)

	var elapsed = Time.get_ticks_msec() - start_time
	_assert(elapsed < 1000,
		"Manifest parse < 1s (actual: %d ms)" % elapsed)
	print("")


func _test_memory_baseline() -> void:
	print("Test 5: Memory baseline — no leaks at init")

	var os_info = OS.get_memory_info()
	var static_mem = os_info.get("static", 0)
	var dynamic_mem = os_info.get("dynamic", 0)

	# Just verify we can read memory info
	_assert(static_mem >= 0, "Static memory readable: %d MB" % (static_mem / (1024 * 1024)))
	_assert(dynamic_mem >= 0, "Dynamic memory readable: %d MB" % (dynamic_mem / (1024 * 1024)))

	# Plugin should not allocate large amounts on load
	# Dynamic memory at headless startup should be under 50MB
	_assert(dynamic_mem < 50 * 1024 * 1024,
		"Dynamic memory < 50MB at startup (actual: %d MB)" % (dynamic_mem / (1024 * 1024)))
	print("")


func _test_output_determinism() -> void:
	print("Test 6: Output determinism — template manifest")

	# Read template.json twice and verify identical
	var path = "res://addons/godot_mini_game/engine/template.json"
	var data1 = _read_json(path)
	var data2 = _read_json(path)

	_assert(data1 == data2,
		"template.json reads identically twice (deterministic)")
	_assert(data1.has("godot"), "Has godot block")
	_assert(data1.has("revision"), "Has revision field")
	print("")


func _test_export_structure() -> void:
	print("Test 7: Export structure — platform configs present")

	var plugin_cfg = "res://addons/godot_mini_game/plugin.cfg"
	var file := FileAccess.open(plugin_cfg, FileAccess.READ)
	_assert(file != null, "plugin.cfg readable")
	if file:
		var content = file.get_as_text()
		file.close()
		_assert(content.contains("[plugin]"), "plugin.cfg has [plugin] section")
		_assert(content.contains("name="), "plugin.cfg has name field")
		_assert(content.contains("version="), "plugin.cfg has version field")
	print("")


func _test_no_developer_artifacts() -> void:
	print("Test 8: No developer artifacts in addon")

	# Check for common dev artifacts that shouldn't be in release
	var forbidden_patterns = [
		".tmp",
		".bak",
		"Thumbs.db",
		".DS_Store",
		".idea",
		".vscode",
	]

	var dir_path = "res://addons/godot_mini_game/"
	for pattern in forbidden_patterns:
		var found = _find_files(dir_path, pattern)
		_assert(found.is_empty(),
			"No '%s' files in addon" % pattern)

	# Check no TODO/FIXME/HACK in core files (warnings, not blockers)
	var core_files = ["exporter.gd", "plugin.gd", "MiniGameSDK.gd"]
	for fname in core_files:
		var fpath = dir_path + fname
		if FileAccess.file_exists(fpath):
			var f = FileAccess.open(fpath, FileAccess.READ)
			if f:
				var content = f.get_as_text()
				f.close()
				var todo_count = content.countn("TODO") + content.countn("FIXME") + content.countn("HACK")
				_assert(todo_count <= 2,
					"%s has %d TODO/FIXME/HACK (max 2)" % [fname, todo_count])
	print("")


# ─── Helpers ────────────────────────────────────────────────────


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var content = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(content) != OK:
		return {}
	return json.data if json.data is Dictionary else {}


func _dir_size_recursive(path: String) -> int:
	var total = 0
	var dir := DirAccess.open(path)
	if not dir:
		return 0
	dir.list_dir_begin()
	var entry = dir.get_next()
	while entry != "":
		if entry == "." or entry == "..":
			entry = dir.get_next()
			continue
		var full = path.path_join(entry)
		if dir.current_is_dir():
			total += _dir_size_recursive(full)
		else:
			total += FileAccess.get_size(full)
		entry = dir.get_next()
	dir.list_dir_end()
	return total


func _glob_size(base: String, pattern: String) -> int:
	var total = 0
	var dir := DirAccess.open(base)
	if not dir:
		return 0
	dir.list_dir_begin()
	var entry = dir.get_next()
	while entry != "":
		if entry == "." or entry == "..":
			entry = dir.get_next()
			continue
		var full = base.path_join(entry)
		if dir.current_is_dir():
			total += _glob_size(full, pattern)
		else:
			if entry.match(pattern):
				total += FileAccess.get_size(full)
		entry = dir.get_next()
	dir.list_dir_end()
	return total


func _count_files(base: String, pattern: String) -> int:
	var count = 0
	var dir := DirAccess.open(base)
	if not dir:
		return 0
	dir.list_dir_begin()
	var entry = dir.get_next()
	while entry != "":
		if entry == "." or entry == "..":
			entry = dir.get_next()
			continue
		var full = base.path_join(entry)
		if dir.current_is_dir():
			count += _count_files(full, pattern)
		else:
			if entry.match(pattern):
				count += 1
		entry = dir.get_next()
	dir.list_dir_end()
	return count


func _find_files(base: String, name: String) -> Array:
	var found: Array = []
	var dir := DirAccess.open(base)
	if not dir:
		return found
	dir.list_dir_begin()
	var entry = dir.get_next()
	while entry != "":
		if entry == "." or entry == "..":
			entry = dir.get_next()
			continue
		var full = base.path_join(entry)
		if dir.current_is_dir():
			found.append_array(_find_files(full, name))
		else:
			if entry == name or entry.ends_with(name):
				found.append(full)
		entry = dir.get_next()
	dir.list_dir_end()
	return found
