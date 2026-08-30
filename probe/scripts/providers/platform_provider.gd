extends RefCounted
## Base class for platform capability detection.
## Subclasses override methods to provide platform-specific behavior.
## Desktop uses MockProvider; WeChat/Douyin/TikTok use real providers.

var platform_name: String = "unknown"
var capabilities: Dictionary = {}

const STATUS_PASS = "PASS"
const STATUS_FAIL = "FAIL"
const STATUS_UNSUPPORTED = "UNSUPPORTED"
const STATUS_ERROR = "ERROR"


func probe_display() -> Dictionary:
	return _result("display", "portrait", STATUS_UNSUPPORTED, "Not implemented")


func probe_input() -> Dictionary:
	return _result("input", "touch", STATUS_UNSUPPORTED, "Not implemented")


func probe_render() -> Dictionary:
	return _result("render", "webgl", STATUS_UNSUPPORTED, "Not implemented")


func probe_audio() -> Dictionary:
	return _result("audio", "playback", STATUS_UNSUPPORTED, "Not implemented")


func probe_storage() -> Dictionary:
	return _result("storage", "local", STATUS_UNSUPPORTED, "Not implemented")


func probe_network() -> Dictionary:
	return _result("network", "http", STATUS_UNSUPPORTED, "Not implemented")


func probe_lifecycle() -> Dictionary:
	return _result("lifecycle", "foreground", STATUS_UNSUPPORTED, "Not implemented")


func probe_vibration() -> Dictionary:
	return _result("vibration", "vibrate", STATUS_UNSUPPORTED, "Not implemented")


func probe_safe_area() -> Dictionary:
	return _result("safe_area", "inset", STATUS_UNSUPPORTED, "Not implemented")


func probe_memory() -> Dictionary:
	return _result("memory", "warning", STATUS_UNSUPPORTED, "Not implemented")


func probe_capabilty_detection() -> Dictionary:
	return _result("capability_detection", "query", STATUS_UNSUPPORTED, "Not implemented")


func probe_structured_logging() -> Dictionary:
	return _result("structured_logging", "log", STATUS_UNSUPPORTED, "Not implemented")


func probe_font_rendering() -> Dictionary:
	return _result("font_rendering", "chinese", STATUS_UNSUPPORTED, "Not implemented")


func probe_image_loading() -> Dictionary:
	return _result("image_loading", "png", STATUS_UNSUPPORTED, "Not implemented")


func get_all_probes() -> Array:
	return [
		probe_display(),
		probe_input(),
		probe_render(),
		probe_audio(),
		probe_storage(),
		probe_network(),
		probe_lifecycle(),
		probe_vibration(),
		probe_safe_area(),
		probe_memory(),
		probe_capabilty_detection(),
		probe_structured_logging(),
		probe_font_rendering(),
		probe_image_loading(),
	]


func _result(category: String, test_name: String, status: String, detail: String, data: Dictionary = {}) -> Dictionary:
	return {
		"platform": platform_name,
		"category": category,
		"test": test_name,
		"status": status,
		"detail": detail,
		"data": data,
	}
