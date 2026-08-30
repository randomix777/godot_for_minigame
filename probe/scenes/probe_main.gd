extends Control
## Main probe scene — runs all probes and displays results.
## This scene is used for editor/visual testing.
## For headless CI, use probe_runner.gd instead.

const PlatformProviderScript = preload("res://scripts/providers/platform_provider.gd")
const MockProviderScript = preload("res://scripts/providers/mock_provider.gd")

@onready var result_label: RichTextLabel = $ResultLabel
@onready var status_label: Label = $StatusLabel

var _provider
var _results: Array = []


func _ready() -> void:
	_provider = _select_provider()
	_run_probes()
	_display_results()


func _select_provider():
	# Desktop fallback
	return MockProviderScript.new()


func _run_probes() -> void:
	_results = _provider.get_all_probes()
	# Add structural probes
	_results.append(_probe_template())


func _probe_template() -> Dictionary:
	var path = "addons/godot_mini_game/engine/template.json"
	if not FileAccess.file_exists(path):
		return {
			"platform": _provider.platform_name,
			"category": "structure",
			"test": "template",
			"status": "FAIL",
			"detail": "template.json missing",
			"data": {},
		}
	return {
		"platform": _provider.platform_name,
		"category": "structure",
		"test": "template",
		"status": "PASS",
		"detail": "template.json present",
		"data": {},
	}


func _display_results() -> void:
	var pass_count = 0
	var fail_count = 0
	var unsup_count = 0

	for r in _results:
		match r.get("status", ""):
			"PASS": pass_count += 1
			"FAIL": fail_count += 1
			"UNSUPPORTED": unsup_count += 1

	status_label.text = "Platform: %s | PASS: %d | FAIL: %d | UNSUPPORTED: %d" % [
		_provider.platform_name, pass_count, fail_count, unsup_count
	]

	var bbcode := ""
	for r in _results:
		var icon = "⬜"
		match r.get("status", ""):
			"PASS": icon = "✅"
			"FAIL": icon = "❌"
			"UNSUPPORTED": icon = "⬜"

		bbcode += "[color=#%s]%s %s/%s: %s[/color]\n" % [
			("4CAF50" if r.get("status") == "PASS" else "F44336" if r.get("status") == "FAIL" else "9E9E9E"),
			icon,
			r.get("category", "?"),
			r.get("test", "?"),
			r.get("detail", ""),
		]

	result_label.text = bbcode
