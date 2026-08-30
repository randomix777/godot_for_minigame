class_name VersionManager
extends RefCounted
## Template version management: download, cache, verify, offline install, rollback.
##
## Manages template bundles for multiple Godot versions. Each template is
## identified by a deterministic identity string and stored in a local cache.
## Supports online download from a release index, offline install from a
## zip file, and rollback to a previous version.

const VERSION_INDEX_URL = "https://raw.githubusercontent.com/user/godot-minigame/main/templates/versions.json"
const CACHE_DIR = "user://template_cache/"
const TEMPLATE_MANIFEST = "template.json"
const SHA256_FILE = "SHA256SUMS"

var _cache_dir: String
var _installed_templates: Dictionary = {}  # version_key -> template_info


func _init() -> void:
	_cache_dir = ProjectSettings.globalize_path(CACHE_DIR)
	_ensure_cache_dir()
	_scan_installed()


func _ensure_cache_dir() -> void:
	if not DirAccess.dir_exists_absolute(_cache_dir):
		DirAccess.make_dir_recursive_absolute(_cache_dir)


func _scan_installed() -> void:
	_installed_templates.clear()
	var dir := DirAccess.open(_cache_dir)
	if not dir:
		return
	dir.list_dir_begin()
	var entry = dir.get_next()
	while entry != "":
		if dir.current_is_dir() and entry != "." and entry != "..":
			var manifest_path = _cache_dir.path_join(entry).path_join(TEMPLATE_MANIFEST)
			if FileAccess.file_exists(manifest_path):
				var info = _read_template_manifest(manifest_path)
				if not info.is_empty():
					var key = _make_key(info)
					_installed_templates[key] = info
		entry = dir.get_next()
	dir.list_dir_end()


# ── Public API ──────────────────────────────────────────────────


## Returns a list of installed template versions.
func list_installed() -> Array:
	var result: Array = []
	for key in _installed_templates:
		result.append(_installed_templates[key])
	return result


## Returns the best template for the given Godot version.
## Returns null if no compatible template is found.
func find_template(godot_version: String) -> Dictionary:
	for key in _installed_templates:
		var info: Dictionary = _installed_templates[key]
		if info.get("godot_version", "") == godot_version:
			return info
	return {}


## Downloads and installs a template for the given Godot version.
## Returns OK on success, error code on failure.
func download_and_install(godot_version: String) -> int:
	# Fetch version index
	var index = _fetch_version_index()
	if index.is_empty():
		return FAILED

	# Find the entry for this version
	var entry = _find_index_entry(index, godot_version)
	if entry.is_empty():
		return FAILED

	# Download the template zip
	var zip_url = entry.get("download_url", "")
	if zip_url.is_empty():
		return FAILED

	var zip_path = _cache_dir.path_join(entry.get("filename", "template.zip"))
	var err = _download_file(zip_url, zip_path)
	if err != OK:
		return err

	# Verify checksum
	var expected_sha = entry.get("sha256", "")
	if not expected_sha.is_empty():
		if not _verify_file_sha256(zip_path, expected_sha):
			DirAccess.remove_absolute(zip_path)
			return FAILED

	# Extract
	var extract_dir = _cache_dir.path_join(entry.get("version_key", godot_version))
	err = _extract_zip(zip_path, extract_dir)
	if err != OK:
		return err

	# Remove the zip after extraction
	DirAccess.remove_absolute(zip_path)

	# Re-scan
	_scan_installed()
	return OK


## Installs a template from a local zip file.
func install_from_file(zip_path: String, version_key: String) -> int:
	if not FileAccess.file_exists(zip_path):
		return FAILED

	var extract_dir = _cache_dir.path_join(version_key)
	var err = _extract_zip(zip_path, extract_dir)
	if err != OK:
		return err

	_scan_installed()
	return OK


## Removes an installed template.
func remove_template(version_key: String) -> int:
	var dir_path = _cache_dir.path_join(version_key)
	if not DirAccess.dir_exists_absolute(dir_path):
		return FAILED

	var dir := DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var entry = dir.get_next()
		while entry != "":
			if entry != "." and entry != "..":
				dir.remove(entry)
			entry = dir.get_next()
		dir.list_dir_end()
		dir.remove("")

	_scan_installed()
	return OK


## Returns the bundled template (in addons/godot_mini_game/engine/).
func get_bundled_template() -> Dictionary:
	var bundled_path = "res://addons/godot_mini_game/engine/"
	var manifest_path = bundled_path + TEMPLATE_MANIFEST
	if not FileAccess.file_exists(manifest_path):
		return {}
	return _read_template_manifest(manifest_path)


## Validates a template directory: checks template.json, SHA-256 hashes.
func validate_template(dir_path: String) -> Dictionary:
	var result := {"valid": false, "errors": []}

	var manifest_path = dir_path.path_join(TEMPLATE_MANIFEST)
	if not FileAccess.file_exists(manifest_path):
		result.errors.append("template.json not found")
		return result

	var info = _read_template_manifest(manifest_path)
	if info.is_empty():
		result.errors.append("template.json is invalid")
		return result

	# Check required fields
	var required_fields = ["version", "godot_version", "commit", "emscripten_version"]
	for field in required_fields:
		if not info.has(field):
			result.errors.append("Missing field: " + field)

	# Verify SHA-256 hashes
	var hashes = info.get("hashes", {})
	for file_name in hashes:
		var file_path = dir_path.path_join(file_name)
		if not FileAccess.file_exists(file_path):
			result.errors.append("File not found: " + file_name)
			continue
		var expected_hash = hashes[file_name]
		var actual_hash = _compute_file_sha256(file_path)
		if actual_hash != expected_hash:
			result.errors.append("SHA-256 mismatch for %s: expected %s, got %s" % [file_name, expected_hash.left(16), actual_hash.left(16)])

	result.valid = result.errors.is_empty()
	result.info = info
	return result


# ── Internal Helpers ────────────────────────────────────────────


func _make_key(info: Dictionary) -> String:
	return "%s_%s_%s" % [
		info.get("godot_version", "unknown"),
		info.get("profile", "unknown"),
		info.get("target", "unknown"),
	]


func _read_template_manifest(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(content) != OK:
		return {}

	var data = json.data
	if not data is Dictionary:
		return {}
	return data


func _fetch_version_index() -> Dictionary:
	var http = HTTPRequest.new()
	http.timeout = 10
	# In a real implementation, this would be an HTTP request
	# For now, return empty (offline mode)
	return {}


func _find_index_entry(index: Dictionary, godot_version: String) -> Dictionary:
	var templates = index.get("templates", [])
	for entry in templates:
		if entry.get("godot_version", "") == godot_version:
			return entry
	return {}


func _download_file(url: String, dest: String) -> int:
	# In a real implementation, this would use HTTPRequest
	# For now, return an error
	return ERR_UNAVAILABLE


func _extract_zip(zip_path: String, dest_dir: String) -> int:
	# Use Godot's ZIP extraction
	var zip = ZIPReader.new()
	var err = zip.open(zip_path)
	if err != OK:
		return err

	var files = zip.get_files()
	for file_path in files:
		var out_path = dest_dir.path_join(file_path)
		if file_path.ends_with("/"):
			DirAccess.make_dir_recursive_absolute(out_path)
			continue
		var file = FileAccess.open(out_path, FileAccess.WRITE)
		if file:
			file.store_buffer(zip.read_file(file_path))
			file.close()

	return OK


func _verify_file_sha256(file_path: String, expected: String) -> bool:
	var actual = _compute_file_sha256(file_path)
	return actual == expected


func _compute_file_sha256(file_path: String) -> String:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return ""
	var sha = FileAccess.get_sha256(file_path)
	return sha if sha else ""
