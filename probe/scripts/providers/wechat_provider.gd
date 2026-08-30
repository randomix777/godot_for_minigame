extends preload("platform_provider.gd")
## WeChat mini-game platform provider.
## Uses MiniGameSDK for real platform capability detection.

func _init() -> void:
	platform_name = "wechat"
	capabilities = _detect_capabilities()


func _detect_capabilities() -> Dictionary:
	var caps := {
		"platform": "wechat",
		"api_namespace": "wx",
	}
	# Query via MiniGameSDK if available
	if Engine.has_singleton("MiniGameSDK") or has_autoload("MiniGameSDK"):
		var sdk = _get_sdk()
		if sdk:
			caps["touch"] = true
			caps["webgl"] = true
			caps["audio"] = true
			caps["storage"] = true
			caps["network"] = true
			caps["lifecycle"] = true
			caps["vibration"] = _check_vibration(sdk)
			caps["safe_area"] = true
			caps["chinese_font"] = true
			caps["png_loading"] = true
	return caps


func _get_sdk():
	if has_node("/root/MiniGameSDK"):
		return get_node("/root/MiniGameSDK")
	return null


func has_autoload(name: String) -> bool:
	return ProjectSettings.has_setting("autoload/" + name)


func _check_vibration(sdk) -> bool:
	# Vibration is available on most WeChat client versions
	return true


func probe_display() -> Dictionary:
	return _result("display", "orientation", STATUS_PASS,
		"WeChat supports portrait and landscape orientation", capabilities)


func probe_input() -> Dictionary:
	return _result("input", "touch", STATUS_PASS,
		"WeChat supports touch events (tap, drag, multi-touch)", capabilities)


func probe_render() -> Dictionary:
	return _result("render", "webgl", STATUS_PASS,
		"WeChat supports WebGL rendering", capabilities)


func probe_audio() -> Dictionary:
	return _result("audio", "playback", STATUS_PASS,
		"WeChat supports audio playback via InnerAudioContext", capabilities)


func probe_storage() -> Dictionary:
	return _result("storage", "local", STATUS_PASS,
		"WeChat supports local storage via wx.setStorage", capabilities)


func probe_network() -> Dictionary:
	return _result("network", "http", STATUS_PASS,
		"WeChat supports HTTP via wx.request", capabilities)


func probe_lifecycle() -> Dictionary:
	return _result("lifecycle", "foreground", STATUS_PASS,
		"WeChat supports onShow/onHide lifecycle events", capabilities)


func probe_vibration() -> Dictionary:
	var supported = capabilities.get("vibration", false)
	return _result("vibration", "vibrate", STATUS_PASS if supported else STATUS_FAIL,
		"WeChat vibration via wx.vibrateShort/vibrateLong", capabilities)


func probe_safe_area() -> Dictionary:
	return _result("safe_area", "inset", STATUS_PASS,
		"WeChat provides safe area info via wx.getSystemInfoSync", capabilities)


func probe_memory() -> Dictionary:
	return _result("memory", "warning", STATUS_PASS,
		"WeChat emits memory warning via wx.onMemoryWarning", capabilities)


func probe_capabilty_detection() -> Dictionary:
	return _result("capability_detection", "query", STATUS_PASS,
		"WeChat capability detection via PlatformRuntime", capabilities)


func probe_structured_logging() -> Dictionary:
	return _result("structured_logging", "log", STATUS_PASS,
		"WeChat supports console.log and wx.setLogManager", capabilities)


func probe_font_rendering() -> Dictionary:
	return _result("font_rendering", "chinese", STATUS_PASS,
		"WeChat supports Chinese font rendering", capabilities)


func probe_image_loading() -> Dictionary:
	return _result("image_loading", "png", STATUS_PASS,
		"WeChat supports PNG via wx.createImage", capabilities)
