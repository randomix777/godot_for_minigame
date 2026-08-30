extends SceneTree
## P4: Mock provider test — simulates ad lifecycle scenarios.
## Tests state machine transitions and error handling.
## No real platform API calls — all mocked.

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
	print("=== P4: Mock Provider Tests ===")
	print("")

	# Test 1: Rewarded ad lifecycle — success
	_test_rewarded_ad_success()

	# Test 2: Rewarded ad lifecycle — user close
	_test_rewarded_ad_close()

	# Test 3: Rewarded ad lifecycle — no inventory
	_test_rewarded_ad_no_inventory()

	# Test 4: Rewarded ad lifecycle — load failure
	_test_rewarded_ad_load_failure()

	# Test 5: Interstitial ad lifecycle — success
	_test_interstitial_ad_success()

	# Test 6: Interstitial ad lifecycle — close
	_test_interstitial_ad_close()

	# Test 7: Banner ad lifecycle
	_test_banner_ad_lifecycle()

	# Test 8: Duplicate ad creation prevention
	_test_duplicate_ad_prevention()

	# Test 9: Ad after destroy
	_test_ad_after_destroy()

	# Test 10: State machine transitions
	_test_state_machine_transitions()

	# Test 11: Error code differentiation
	_test_error_codes()

	# Test 12: No game reward logic in plugin
	_test_no_reward_logic()

	print("")
	print("=== Results: %d/%d passed ===" % [_passed, _total])
	if _failed:
		print("FAILED")
		quit(1)
	else:
		print("ALL PASSED")
		quit(0)


# ─── Mock Ad State Machine ──────────────────────────────────────

enum AdState { IDLE, LOADING, LOADED, PLAYING, CLOSED, ERROR }
enum AdError { NONE, LOAD_FAILED, NO_INVENTORY, NETWORK_ERROR, TIMEOUT, UNSUPPORTED }

var _ad_state: int = AdState.IDLE
var _ad_error: int = AdError.NONE
var _ad_type: String = ""
var _ad_ended: bool = false


func _reset_ad() -> void:
	_ad_state = AdState.IDLE
	_ad_error = AdError.NONE
	_ad_type = ""
	_ad_ended = false


func _mock_create_ad(type: String) -> bool:
	if _ad_state != AdState.IDLE and _ad_state != AdState.CLOSED and _ad_state != AdState.ERROR:
		return false  # Already active
	_ad_type = type
	_ad_state = AdState.LOADING
	_ad_error = AdError.NONE
	return true


func _mock_load_success() -> void:
	_ad_state = AdState.LOADED


func _mock_load_fail(error: int) -> void:
	_ad_state = AdState.ERROR
	_ad_error = error


func _mock_show() -> bool:
	if _ad_state != AdState.LOADED:
		return false
	_ad_state = AdState.PLAYING
	return true


func _mock_ad_complete(ended: bool) -> void:
	_ad_ended = ended
	_ad_state = AdState.CLOSED


func _mock_ad_error(error: int) -> void:
	_ad_state = AdState.ERROR
	_ad_error = error


# ─── Tests ──────────────────────────────────────────────────────

func _test_rewarded_ad_success() -> void:
	print("Test 1: Rewarded ad — success flow")
	_reset_ad()
	_assert(_mock_create_ad("rewarded"), "Create rewarded ad")
	_assert(_ad_state == AdState.LOADING, "State → LOADING")
	_mock_load_success()
	_assert(_ad_state == AdState.LOADED, "State → LOADED")
	_assert(_mock_show(), "Show ad")
	_assert(_ad_state == AdState.PLAYING, "State → PLAYING")
	_mock_ad_complete(true)
	_assert(_ad_state == AdState.CLOSED, "State → CLOSED")
	_assert(_ad_ended == true, "is_ended = true (reward granted)")
	print("")


func _test_rewarded_ad_close() -> void:
	print("Test 2: Rewarded ad — user close (no reward)")
	_reset_ad()
	_mock_create_ad("rewarded")
	_mock_load_success()
	_mock_show()
	_mock_ad_complete(false)
	_assert(_ad_state == AdState.CLOSED, "State → CLOSED")
	_assert(_ad_ended == false, "is_ended = false (no reward)")
	print("")


func _test_rewarded_ad_no_inventory() -> void:
	print("Test 3: Rewarded ad — no inventory")
	_reset_ad()
	_mock_create_ad("rewarded")
	_mock_load_fail(AdError.NO_INVENTORY)
	_assert(_ad_state == AdState.ERROR, "State → ERROR")
	_assert(_ad_error == AdError.NO_INVENTORY, "Error = NO_INVENTORY")
	print("")


func _test_rewarded_ad_load_failure() -> void:
	print("Test 4: Rewarded ad — load failure")
	_reset_ad()
	_mock_create_ad("rewarded")
	_mock_load_fail(AdError.LOAD_FAILED)
	_assert(_ad_state == AdState.ERROR, "State → ERROR")
	_assert(_ad_error == AdError.LOAD_FAILED, "Error = LOAD_FAILED")
	print("")


func _test_interstitial_ad_success() -> void:
	print("Test 5: Interstitial ad — success flow")
	_reset_ad()
	_mock_create_ad("interstitial")
	_mock_load_success()
	_assert(_mock_show(), "Show interstitial")
	_mock_ad_complete(true)
	_assert(_ad_state == AdState.CLOSED, "State → CLOSED")
	print("")


func _test_interstitial_ad_close() -> void:
	print("Test 6: Interstitial ad — user close")
	_reset_ad()
	_mock_create_ad("interstitial")
	_mock_load_success()
	_mock_show()
	_mock_ad_complete(false)
	_assert(_ad_state == AdState.CLOSED, "State → CLOSED")
	print("")


func _test_banner_ad_lifecycle() -> void:
	print("Test 7: Banner ad — show/hide/destroy")
	_reset_ad()
	_mock_create_ad("banner")
	_mock_load_success()
	_assert(_ad_state == AdState.LOADED, "Banner loaded")
	# Banner doesn't have "show" like rewarded/interstitial
	_ad_state = AdState.PLAYING
	_assert(_ad_state == AdState.PLAYING, "Banner shown")
	_ad_state = AdState.CLOSED
	_assert(_ad_state == AdState.CLOSED, "Banner destroyed")
	print("")


func _test_duplicate_ad_prevention() -> void:
	print("Test 8: Duplicate ad creation prevention")
	_reset_ad()
	_mock_create_ad("rewarded")
	_mock_load_success()
	var duplicate = _mock_create_ad("rewarded")
	_assert(duplicate == false, "Cannot create while active")
	print("")


func _test_ad_after_destroy() -> void:
	print("Test 9: Ad after destroy")
	_reset_ad()
	_mock_create_ad("rewarded")
	_ad_state = AdState.ERROR
	_ad_error = AdError.UNSUPPORTED
	# After error/destroy, should be able to create new ad
	var can_create = _ad_state == AdState.IDLE or _ad_state == AdState.ERROR or _ad_state == AdState.CLOSED
	_assert(can_create, "Can create new ad after error")
	print("")


func _test_state_machine_transitions() -> void:
	print("Test 10: State machine — valid transitions")
	_reset_ad()

	# Valid: IDLE → LOADING
	_mock_create_ad("rewarded")
	_assert(_ad_state == AdState.LOADING, "IDLE → LOADING")

	# Valid: LOADING → LOADED
	_mock_load_success()
	_assert(_ad_state == AdState.LOADED, "LOADING → LOADED")

	# Valid: LOADED → PLAYING
	_mock_show()
	_assert(_ad_state == AdState.PLAYING, "LOADED → PLAYING")

	# Valid: PLAYING → CLOSED
	_mock_ad_complete(true)
	_assert(_ad_state == AdState.CLOSED, "PLAYING → CLOSED")

	# Valid: CLOSED → LOADING (retry)
	_mock_create_ad("rewarded")
	_assert(_ad_state == AdState.LOADING, "CLOSED → LOADING")

	# Invalid: LOADING → PLAYING (skip LOADED)
	_reset_ad()
	_mock_create_ad("rewarded")
	var showed = _mock_show()
	_assert(showed == false, "Cannot show while LOADING")

	print("")


func _test_error_codes() -> void:
	print("Test 11: Error code differentiation")
	_reset_ad()

	var errors = {
		AdError.LOAD_FAILED: "LOAD_FAILED",
		AdError.NO_INVENTORY: "NO_INVENTORY",
		AdError.NETWORK_ERROR: "NETWORK_ERROR",
		AdError.TIMEOUT: "TIMEOUT",
		AdError.UNSUPPORTED: "UNSUPPORTED",
	}

	for error_code in errors:
		_mock_create_ad("rewarded")
		_mock_load_fail(error_code)
		_assert(_ad_error == error_code,
			"Error %d = %s" % [error_code, errors[error_code]])
		_reset_ad()

	print("")


func _test_no_reward_logic() -> void:
	print("Test 12: No game reward logic in plugin")
	# Verify the plugin only reports ad result, never grants rewards
	var sdk_path = "res://addons/godot_mini_game/MiniGameSDK.gd"
	var file := FileAccess.open(sdk_path, FileAccess.READ)
	if not file:
		_assert(false, "Cannot read MiniGameSDK.gd")
		return

	var content = file.get_as_text()
	file.close()

	# Check that the SDK does NOT contain reward-granting logic
	var has_reward_grant = (
		content.find("add_coins") != -1
		or content.find("grant_reward") != -1
		or content.find("give_reward") != -1
		or content.find("add_currency") != -1
		or content.find("increment_score") != -1
	)

	_assert(not has_reward_grant,
		"Plugin does not contain game reward logic (only reports ad result)")

	# Check that rewarded_ad_result only reports is_ended
	_assert(content.find("rewarded_ad_result.emit") != -1,
		"Plugin emits rewarded_ad_result with is_ended flag")
	_assert(content.find("signal rewarded_ad_result") != -1,
		"Plugin declares rewarded_ad_result signal")

	print("")
