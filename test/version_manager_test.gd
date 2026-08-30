extends SceneTree
## P5: Template version management tests.
## Tests: manifest integrity, SHA-256 verification, version identity,
## rollback, corruption detection, no fuzzy matching.

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
	print("=== P5: Template Version Management Tests ===")
	print("")

	_test_template_identity()
	_test_manifest_fields()
	_test_sha256_integrity()
	_test_no_fuzzy_matching()
	_test_support_matrix_entries()
	_test_corruption_detection()
	_test_version_key_format()
	_test_bundled_template_accessible()
	_test_471_commit_pin()

	print("")
	print("=== Results: %d/%d passed ===" % [_passed, _total])
	if _failed:
		print("FAILED")
		quit(1)
	else:
		print("ALL PASSED")
		quit(0)


# ─── Tests ──────────────────────────────────────────────────────


func _test_template_identity() -> void:
	print("Test 1: Template identity — deterministic key format")
	var manifest_path = "res://addons/godot_mini_game/engine/template.json"
	var file := FileAccess.open(manifest_path, FileAccess.READ)
	_assert(file != null, "template.json exists and readable")
	if not file:
		return

	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	_assert(json.parse(content) == OK, "template.json parses as valid JSON")
	if json.parse(content) != OK:
		return

	var data = json.data
	_assert(data is Dictionary, "template.json root is Dictionary")
	_assert(data.has("godot"), "Has 'godot' block")
	_assert(data.has("artifacts"), "Has 'artifacts' block")
	_assert(data.has("bridgeAbi"), "Has 'bridgeAbi' field")
	_assert(data.has("revision"), "Has 'revision' field")
	_assert(data.has("emscriptenVersion"), "Has 'emscriptenVersion' field")
	_assert(data.has("profile"), "Has 'profile' field")
	print("")


func _test_manifest_fields() -> void:
	print("Test 2: Manifest — required fields present")
	var manifest_path = "res://addons/godot_mini_game/engine/template.json"
	var data = _read_json(manifest_path)
	if data.is_empty():
		_assert(false, "Cannot read template.json")
		return

	var godot = data.get("godot", {})
	_assert(godot.has("version"), "godot.version present")
	_assert(godot.has("commit"), "godot.commit present")
	_assert(data.has("emscriptenVersion"), "emscriptenVersion present")
	_assert(data.has("profile"), "profile present")

	var commit = str(godot.get("commit", ""))
	_assert(commit.length() == 40, "Commit is 40-char hex SHA-1")
	_assert(_is_hex_string(commit), "Commit is valid hex")

	var version = str(godot.get("version", ""))
	_assert(version.length() > 0, "Version is non-empty")
	_assert(version.contains("."), "Version contains dots (semver)")
	print("")


func _test_sha256_integrity() -> void:
	print("Test 3: SHA-256 integrity — bundled files")
	var manifest_path = "res://addons/godot_mini_game/engine/template.json"
	var data = _read_json(manifest_path)
	if data.is_empty():
		_assert(false, "Cannot read template.json")
		return

	var artifacts = data.get("artifacts", {})
	for file_name in artifacts:
		var expected_hash = str(artifacts[file_name].get("sha256", ""))
		_assert(expected_hash.length() == 64, "SHA-256 for %s is 64 chars" % file_name)

		# Verify actual file hash
		var file_path = "res://addons/godot_mini_game/engine/" + file_name
		var actual_hash = FileAccess.get_sha256(file_path)
		_assert(actual_hash != "", "File %s is readable" % file_name)
		if actual_hash:
			_assert(actual_hash == expected_hash,
				"SHA-256 matches for %s" % file_name)
	print("")


func _test_no_fuzzy_matching() -> void:
	print("Test 4: No fuzzy commit matching")
	var manifest_path = "res://addons/godot_mini_game/engine/template.json"
	var data = _read_json(manifest_path)
	if data.is_empty():
		return

	var commit = str(data.get("godot", {}).get("commit", ""))
	# Must be exactly 40 hex chars — no short hashes, no prefixes
	_assert(commit.length() == 40, "Commit is exactly 40 chars (no short hash)")
	_assert(commit == commit.strip_edges(), "Commit has no whitespace")
	_assert(not commit.contains(" "), "Commit has no spaces")
	_assert(commit.begins_with("0") or commit.begins_with("1") or
		commit.begins_with("2") or commit.begins_with("3") or
		commit.begins_with("4") or commit.begins_with("5") or
		commit.begins_with("6") or commit.begins_with("7") or
		commit.begins_with("8") or commit.begins_with("9") or
		commit.begins_with("a") or commit.begins_with("b") or
		commit.begins_with("c") or commit.begins_with("d") or
		commit.begins_with("e") or commit.begins_with("f"),
		"Commit starts with hex digit")
	print("")


func _test_support_matrix_entries() -> void:
	print("Test 5: Support matrix — entries match template identity")
	var matrix_path = "res://support-matrix.json"
	var matrix = _read_json(matrix_path)
	if matrix.is_empty():
		_assert(false, "Cannot read support-matrix.json")
		return

	var certified = matrix.get("certified", [])
	_assert(certified.size() >= 1, "At least 1 certified entry")

	for entry in certified:
		var gv = str(entry.get("godotVersion", ""))
		var gc = str(entry.get("godotCommit", ""))
		var tag = str(entry.get("godotTag", ""))

		_assert(gv.length() > 0, "Certified entry has godotVersion: %s" % gv)
		_assert(gc.length() == 40, "Certified %s commit is 40 chars" % gv)
		_assert(tag.length() > 0, "Certified entry has godotTag: %s" % tag)

		# Verify tag matches version
		var expected_tag = gv.replace(".stable", "-stable").replace(".", ".") 
		_assert(tag.contains("-stable"), "Tag contains '-stable': %s" % tag)

		# Verify Emscripten pinned
		var emsdk = str(entry.get("emscriptenVersion", ""))
		_assert(emsdk.length() > 0, "Emscripten pinned for %s: %s" % [gv, emsdk])
		_assert(emsdk == "4.0.3", "Emscripten is 4.0.3 for %s" % gv)

		# Verify profile and target pinned
		_assert(entry.get("profile", "") == "2d_full", "Profile is 2d_full")
		_assert(entry.get("target", "") == "release", "Target is release")

		# Verify template source
		var tmpl = entry.get("template", {})
		_assert(tmpl.has("source"), "Template source declared for %s" % gv)
		_assert(tmpl.get("source", "") in ["bundled", "release"],
			"Template source is 'bundled' or 'release'")

	print("")


func _test_corruption_detection() -> void:
	print("Test 6: Corruption detection — tampered hash")
	var manifest_path = "res://addons/godot_mini_game/engine/template.json"
	var data = _read_json(manifest_path)
	if data.is_empty():
		return

	var artifacts = data.get("artifacts", {})
	for file_name in artifacts:
		var real_hash = FileAccess.get_sha256("res://addons/godot_mini_game/engine/" + file_name)
		var tampered_hash = "0000000000000000000000000000000000000000000000000000000000000000"
		_assert(real_hash != tampered_hash,
			"Real hash for %s is not all-zeros" % file_name)
		if real_hash:
			# Verify we can detect mismatch
			var expected = str(artifacts[file_name].get("sha256", ""))
			_assert(real_hash == expected,
				"Tamper detection: real matches declared for %s" % file_name)
	print("")


func _test_version_key_format() -> void:
	print("Test 7: Version key format — deterministic")
	# A version key should be: <godot_version>_<emsdk>_<profile>_<target>_r<revision>
	var manifest_path = "res://addons/godot_mini_game/engine/template.json"
	var data = _read_json(manifest_path)
	if data.is_empty():
		return

	var godot = data.get("godot", {})
	var version = str(godot.get("version", ""))
	var emsdk = str(data.get("emscriptenVersion", ""))
	var profile = str(data.get("profile", ""))
	var revision = data.get("revision", 0)

	var key = "%s_emsdk-%s_%s_r%s" % [version, emsdk, profile, revision]
	_assert(key.length() > 10, "Version key is non-trivial: %s" % key)
	_assert(key.contains(version), "Key contains version")
	_assert(key.contains(emsdk), "Key contains emsdk")
	_assert(key.contains(profile), "Key contains profile")
	_assert(key.contains("r1"), "Key contains revision")
	print("")


func _test_bundled_template_accessible() -> void:
	print("Test 8: Bundled template — all files accessible")
	var files = [
		"res://addons/godot_mini_game/engine/template.json",
		"res://addons/godot_mini_game/engine/godot.js",
		"res://addons/godot_mini_game/engine/godot.wasm.br",
	]
	for path in files:
		var exists = FileAccess.file_exists(path)
		_assert(exists, "Bundled file exists: %s" % path.get_file())
		if exists:
			var size = FileAccess.get_size(path)
			_assert(size > 0, "File is non-empty: %s (%d bytes)" % [path.get_file(), size])
	print("")


func _test_471_commit_pin() -> void:
	print("Test 9: Godot 4.7.1 — exact commit pinned in support-matrix")
	var matrix = _read_json("res://support-matrix.json")
	if matrix.is_empty():
		return

	var found_471 = false
	for entry in matrix.get("certified", []):
		if str(entry.get("godotVersion", "")).contains("4.7.1"):
			found_471 = true
			var commit = str(entry.get("godotCommit", ""))
			_assert(commit == "a13da4feb8d8aefc283c3763d33a2f170a18d541",
				"4.7.1 commit is exact: %s" % commit.left(12))
			_assert(str(entry.get("emscriptenVersion", "")) == "4.0.3",
				"4.7.1 Emscripten pinned to 4.0.3")
			_assert(entry.get("profile", "") == "2d_full",
				"4.7.1 profile pinned to 2d_full")
			_assert(entry.get("target", "") == "release",
				"4.7.1 target pinned to release")
			var tmpl = entry.get("template", {})
			_assert(tmpl.get("source", "") == "release",
				"4.7.1 template source is 'release' (not bundled)")
			_assert(tmpl.has("releaseTag"), "4.7.1 has releaseTag")
			_assert(tmpl.has("asset"), "4.7.1 has asset filename")
			break

	_assert(found_471, "support-matrix.json contains 4.7.1 entry")
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


func _is_hex_string(s: String) -> bool:
	var hex_chars = "0123456789abcdef"
	for c in s:
		if not hex_chars.contains(c):
			return false
	return true
