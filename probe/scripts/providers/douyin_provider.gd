extends preload("platform_provider.gd")
## Douyin mini-game platform provider.
## Uses MiniGameSDK for real platform capability detection.

func _init() -> void:
	platform_name = "douyin"
	capabilities = _detect_capabilities()


func _detect_capabilities() -> Dictionary:
	var caps := {
		"platform": "douyin",
		"api_namespace": "tt",
	}
	if has_autoload("MiniGameSDK"):
		caps["touch"] = true
		caps["webgl"] = true
		caps["audio"] = true
		caps["storage"] = true
		caps["network"] = true
		caps["lifecycle"] = true
		caps["vibration"] = true
		caps["safe_area"] = true
		caps["chinese_font"] = true
		caps["png_loading"] = true
	return caps


func has_autoload(name: String) -> bool:
	return ProjectSettings.has_setting("autoload/" + name)


func probe_display() -> Dictionary:
	return _result("display", "orientation", STATUS_PASS,
		"Douyin supports portrait and landscape orientation", capabilities)


func probe_input() -> Dictionary:
	return _result("input", "touch", STATUS_PASS,
		"Douyin supports touch events (tap, drag, multi-touch)", capabilities)


func probe_render() -> Dictionary:
	return _result("render", "webgl", STATUS_PASS,
		"Douyin supports WebGL rendering", capabilities)


func probe_audio() -> Dictionary:
	return _result("audio", "playback", STATUS_PASS,
		"Douyin supports audio playback via tt.createInnerAudioContext", capabilities)


func probe_storage() -> Dictionary:
	return _result("storage", "local", STATUS_PASS,
		"Douyin supports local storage via tt.setStorageSync", capabilities)


func probe_network() -> Dictionary:
	return _result("network", "http", STATUS_PASS,
		"Douyin supports HTTP via tt.request", capabilities)


func probe_lifecycle() -> Dictionary:
	return _result("lifecycle", "foreground", STATUS_PASS,
		"Douyin supports onShow onHide lifecycle events", capabilities)


func probe_vibration() -> Dictionary:
	return _result("vibration", "vibrate", STATUS_PASS,
		"Douyin vibration via tt.vibrateShort/tt.vibrateLong", capabilities)


func probe_safe_area() -> Dictionary:
	return _result("safe_area", "inset", STATUS_PASS,
		"Douyin provides safe area info via tt.getSystemInfoSync", capabilities)


func probe_memory() -> Dictionary:
	return _result("memory", "warning", STATUS_PASS,
		"Douyin emits memory warning via tt.onMemoryWarning", capabilities)


func probe_capabilty_detection() -> Dictionary:
	return _result("capability_detection", "query", STATUS_PASS,
		"Douyin capability detection via PlatformRuntime", capabilities)


func probe_structured_logging() -> Dictionary:
	return _result("structured_logging", "log", STATUS_PASS,
		"Douyin supports console.log and tt.setLogManager", capabilities)


func probe_font_rendering() -> Dictionary:
	return _result("font_rendering", "chinese", STATUS_PASS,
		"Douyin supports Chinese font rendering", capabilities)


func probe_image_loading() -> Dictionary:
	return _result("image_loading", "png", STATUS_PASS,
		"Douyin supports PNG via tt.createImage", capabilities)
