extends preload("platform_provider.gd")
## Mock/no-op provider for desktop testing.
## All probes return UNSUPPORTED or simulated PASS where safe.

func _init() -> void:
	platform_name = "desktop_mock"
	capabilities = {
		"platform": "desktop_mock",
		"touch": false,
		"webgl": true,
		"audio": true,
		"storage": true,
		"network": true,
		"lifecycle": false,
		"vibration": false,
		"safe_area": false,
		"chinese_font": true,
		"png_loading": true,
	}


func probe_display() -> Dictionary:
	return _result("display", "orientation", STATUS_UNSUPPORTED,
		"Desktop does not support orientation control")


func probe_input() -> Dictionary:
	# Desktop has mouse/keyboard but not touch
	return _result("input", "touch", STATUS_UNSUPPORTED,
		"Desktop uses mouse/keyboard, not touch")


func probe_render() -> Dictionary:
	return _result("render", "webgl", STATUS_PASS,
		"Desktop uses OpenGL/Vulkan (WebGL simulated)")


func probe_audio() -> Dictionary:
	return _result("audio", "playback", STATUS_PASS,
		"Desktop audio playback available")


func probe_storage() -> Dictionary:
	return _result("storage", "local", STATUS_PASS,
		"Desktop file system storage available")


func probe_network() -> Dictionary:
	return _result("network", "http", STATUS_PASS,
		"Desktop network available")


func probe_lifecycle() -> Dictionary:
	return _result("lifecycle", "foreground", STATUS_UNSUPPORTED,
		"Desktop does not have mini-game lifecycle events")


func probe_vibration() -> Dictionary:
	return _result("vibration", "vibrate", STATUS_UNSUPPORTED,
		"Desktop does not support vibration")


func probe_safe_area() -> Dictionary:
	return _result("safe_area", "inset", STATUS_UNSUPPORTED,
		"Desktop does not have safe area insets")


func probe_memory() -> Dictionary:
	return _result("memory", "warning", STATUS_UNSUPPORTED,
		"Desktop does not emit mini-game memory warnings")


func probe_capabilty_detection() -> Dictionary:
	return _result("capability_detection", "query", STATUS_PASS,
		"Capability detection available via MiniGameSDK")


func probe_structured_logging() -> Dictionary:
	return _result("structured_logging", "log", STATUS_PASS,
		"Structured logging via print()")


func probe_font_rendering() -> Dictionary:
	return _result("font_rendering", "chinese", STATUS_PASS,
		"Desktop supports Chinese font rendering")


func probe_image_loading() -> Dictionary:
	return _result("image_loading", "png", STATUS_PASS,
		"Desktop supports PNG image loading")
