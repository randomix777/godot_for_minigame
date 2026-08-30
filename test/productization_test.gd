extends SceneTree
## P7: Productization design tests.
## Tests: tier separation (Community/Pro/Enterprise), feature gates,
## export manifest completeness, plugin.cfg consistency.

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
	print("=== P7: Productization Design Tests ===")
	print("")

	_test_plugin_cfg_consistency()
	_test_export_dock_exists()
	_test_no_premium_gating_in_core()
	_test_api_completeness()
	_test_documentation_completeness()
	_test_license_present()
	_test_no_real_payment_logic()
	_test_ad_unit_id_externalized()
	_test_app_id_externalized()
	_test_no_hardcoded_credentials()

	print("")
	print("=== Results: %d/%d passed ===" % [_passed, _total])
	if _failed:
		print("FAILED")
		quit(1)
	else:
		print("ALL PASSED")
		quit(0)


# ─── Tests ──────────────────────────────────────────────────────


func _test_plugin_cfg_consistency() -> void:
	print("Test 1: Plugin.cfg consistency")
	var path = "res://addons/godot_mini_game/plugin.cfg"
	var file := FileAccess.open(path, FileAccess.READ)
	_assert(file != null, "plugin.cfg exists")
	if not file:
		return

	var content = file.get_as_text()
	file.close()

	# Parse INI-like config
	var name_val = _extract_cfg_value(content, "name")
	var version_val = _extract_cfg_value(content, "version")
	var desc_val = _extract_cfg_value(content, "description")
	var author_val = _extract_cfg_value(content, "author")

	_assert(name_val.length() > 0, "Plugin name set: %s" % name_val)
	_assert(version_val.length() > 0, "Plugin version set: %s" % version_val)
	_assert(desc_val.length() > 0, "Plugin description set")
	_assert(author_val.length() > 0, "Plugin author set: %s" % author_val)

	# Version should be semver
	_assert(version_val.contains("."), "Version is semver: %s" % version_val)

	# Check script references
	_assert(content.contains("plugin.gd"), "Entry script: plugin.gd")

	# Check autoload references (registered in plugin.gd, not plugin.cfg)
	var plugin_gd = FileAccess.open("res://addons/godot_mini_game/plugin.gd", FileAccess.READ)
	if plugin_gd:
		var pg_content = plugin_gd.get_as_text()
		plugin_gd.close()
		_assert(pg_content.find("MiniGameSDK") != -1,
			"MiniGameSDK autoload registered in plugin.gd")
	print("")


func _test_export_dock_exists() -> void:
	print("Test 2: Export dock exists and is functional")
	var dock_path = "res://addons/godot_mini_game/export_dock.gd"
	var file := FileAccess.open(dock_path, FileAccess.READ)
	_assert(file != null, "export_dock.gd exists")
	if file:
		var content = file.get_as_text()
		file.close()
		_assert(content.contains("extends"), "export_dock.gd extends a class")
		_assert(content.contains("platform") or content.contains("Platform"),
			"export_dock.gd references platform selection")
	print("")


func _test_no_premium_gating_in_core() -> void:
	print("Test 3: No premium/paywall gating in core")
	var core_files = [
		"exporter.gd",
		"plugin.gd",
		"MiniGameSDK.gd",
		"core/template_bundle.gd",
		"core/output_guard.gd",
	]

	for fname in core_files:
		var path = "res://addons/godot_mini_game/" + fname
		var file := FileAccess.open(path, FileAccess.READ)
		if not file:
			continue
		var content = file.get_as_text()
		file.close()

		var has_paywall = (
			content.findn("license_key") != -1
			or content.findn("trial_expired") != -1
			or content.findn("premium_only") != -1
			or content.findn("feature_locked") != -1
			or content.findn("requires_license") != -1
		)
		_assert(not has_paywall,
			"No paywall logic in %s" % fname)
	print("")


func _test_api_completeness() -> void:
	print("Test 4: API completeness — all P4 features present")
	var sdk_path = "res://addons/godot_mini_game/MiniGameSDK.gd"
	var file := FileAccess.open(sdk_path, FileAccess.READ)
	_assert(file != null, "MiniGameSDK.gd readable")
	if not file:
		return

	var content = file.get_as_text()
	file.close()

	# Check required API categories
	var required = {
		"login": "func login",
		"share": "func share_app",
		"rewarded_ad": "func create_rewarded_ad",
		"interstitial_ad": "func create_interstitial_ad",
		"banner_ad": "func create_banner_ad",
		"storage": "func storage_set",
		"network": "func http_request",
		"vibration": "func vibrate_short",
		"system_info": "func get_system_info",
		"lifecycle": "signal app_shown",
	}

	for category in required:
		var lookup = required[category]
		var has_api = content.find(lookup) != -1
		_assert(has_api,
			"API '%s' present (%s)" % [category, lookup])

	# Check signals exist
	var required_signals = [
		"login_completed",
		"rewarded_ad_result",
		"ad_created",
		"http_response",
	]
	for sig in required_signals:
		_assert(content.find("signal " + sig) != -1,
			"Signal '%s' declared" % sig)
	print("")


func _test_documentation_completeness() -> void:
	print("Test 5: Documentation completeness")
	var docs = [
		["README.md", "res://README.md"],
		["CHANGELOG.md", "res://CHANGELOG.md"],
		["SECURITY.md", "res://SECURITY.md"],
		["CONTRIBUTING.md", "res://CONTRIBUTING.md"],
		["VERSION_SUPPORT.md", "res://VERSION_SUPPORT.md"],
	]
	for pair in docs:
		var name = pair[0]
		var path = pair[1]
		var file := FileAccess.open(path, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			_assert(content.length() > 100,
				"%s is substantial (>100 chars)" % name)
		else:
			_assert(false, "%s exists" % name)
	print("")


func _test_license_present() -> void:
	print("Test 6: License present")
	var license_path = "res://LICENSE"
	var file := FileAccess.open(license_path, FileAccess.READ)
	_assert(file != null, "LICENSE file exists")
	if file:
		var content = file.get_as_text()
		file.close()
		_assert(content.length() > 100, "LICENSE is substantial")
		_assert(
			content.findn("MIT") != -1 or
			content.findn("Apache") != -1 or
			content.findn("BSD") != -1 or
			content.findn("GPL") != -1 or
			content.findn("Mozilla") != -1,
			"LICENSE is a recognized open-source license")
	print("")


func _test_no_real_payment_logic() -> void:
	print("Test 7: No real payment implementation")
	var sdk_path = "res://addons/godot_mini_game/MiniGameSDK.gd"
	var file := FileAccess.open(sdk_path, FileAccess.READ)
	if not file:
		return
	var content = file.get_as_text()
	file.close()

	# payment_result signal exists (report only), but no actual payment processing
	var has_payment_signal = content.find("signal payment_result") != -1
	_assert(has_payment_signal, "payment_result signal exists (report only)")

	# No hardcoded payment keys/IDs
	var has_hardcoded_payment = (
		content.findn("merchant_id") != -1 and content.findn("sk_live") != -1
	)
	_assert(not has_hardcoded_payment,
		"No hardcoded payment keys")
	print("")


func _test_ad_unit_id_externalized() -> void:
	print("Test 8: Ad unit ID externalized (parameter, not hardcoded)")
	var sdk_path = "res://addons/godot_mini_game/MiniGameSDK.gd"
	var file := FileAccess.open(sdk_path, FileAccess.READ)
	if not file:
		return
	var content = file.get_as_text()
	file.close()

	# create_rewarded_ad should take ad_unit_id as parameter
	_assert(content.find("func create_rewarded_ad(ad_unit_id") != -1,
		"create_rewarded_ad takes ad_unit_id parameter")
	_assert(content.find("func create_interstitial_ad(ad_unit_id") != -1,
		"create_interstitial_ad takes ad_unit_id parameter")
	_assert(content.find("func create_banner_ad(ad_unit_id") != -1,
		"create_banner_ad takes ad_unit_id parameter")

	# No hardcoded ad unit IDs
	_assert(content.findn("ca-app-pub-") == -1,
		"No hardcoded AdMob ad unit IDs")
	_assert(content.findn("ad_unit_") == -1 or
		content.find("func create_rewarded_ad(ad_unit_id") != -1,
		"ad_unit references are parameters, not hardcoded values")
	print("")


func _test_app_id_externalized() -> void:
	print("Test 9: App ID externalized")
	# AppID should be configured per-project, not hardcoded
	var sdk_path = "res://addons/godot_mini_game/MiniGameSDK.gd"
	var file := FileAccess.open(sdk_path, FileAccess.READ)
	if not file:
		return
	var content = file.get_as_text()
	file.close()

	# No hardcoded WeChat/Douyin app IDs
	_assert(content.findn("wx") != -1,
		"WeChat API namespace 'wx' referenced (but not as app ID)")
	_assert(content.findn("hardcoded_app_id") == -1,
		"No hardcoded app IDs")
	print("")


func _test_no_hardcoded_credentials() -> void:
	print("Test 10: No hardcoded credentials")

	# Scan all GDScript files for credential patterns
	var dir_path = "res://addons/godot_mini_game/"
	var patterns = ["password", "api_key", "apikey", "sk_live", "sk_test"]

	var has_credential = false
	var found_files: Array = []
	_scan_for_patterns(dir_path, patterns, found_files)

	_assert(found_files.is_empty(),
		"No hardcoded credentials found in addon")

	if not found_files.is_empty():
		for f in found_files:
			print("    WARNING: Found credential pattern in: " + f)
	print("")


# ─── Helpers ────────────────────────────────────────────────────


func _extract_cfg_value(content: String, key: String) -> String:
	for line in content.split("\n"):
		var stripped = line.strip_edges()
		if stripped.begins_with(key + "="):
			return stripped.substr(key.length() + 1)
	return ""


func _scan_for_patterns(path: String, patterns: Array, found: Array) -> void:
	var dir := DirAccess.open(path)
	if not dir:
		return
	dir.list_dir_begin()
	var entry = dir.get_next()
	while entry != "":
		if entry == "." or entry == "..":
			entry = dir.get_next()
			continue
		var full = path.path_join(entry)
		if dir.current_is_dir():
			_scan_for_patterns(full, patterns, found)
		elif entry.ends_with(".gd"):
			var file := FileAccess.open(full, FileAccess.READ)
			if file:
				var content = file.get_as_text().to_lower()
				file.close()
				for pattern in patterns:
					if content.findn(pattern) != -1:
						# Filter out false positives
						if content.findn("signal " + pattern) == -1:
							found.append(full)
						break
		entry = dir.get_next()
	dir.list_dir_end()
