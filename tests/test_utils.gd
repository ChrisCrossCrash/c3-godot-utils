extends GutTest


class TestFormatTime:
	extends GutTest

	func test_format_time_positive() -> void:
		assert_eq(C3Utils.format_time(3.01), "00:03.010")
		assert_eq(C3Utils.format_time(65.432), "01:05.432")
		assert_eq(C3Utils.format_time(3661.789), "01:01:01.789")
		assert_eq(C3Utils.format_time(37234.567), "10:20:34.567")
		assert_eq(C3Utils.format_time(0.0), "00:00.000")

	func test_format_time_negative() -> void:
		assert_eq(C3Utils.format_time(-3.01), "-00:03.010")
		assert_eq(C3Utils.format_time(-3.01, true), "-00:03.010")  # sign_positive has no effect on negatives
		assert_eq(C3Utils.format_time(-65.432), "-01:05.432")
		assert_eq(C3Utils.format_time(-3661.789), "-01:01:01.789")
		assert_eq(C3Utils.format_time(-37234.567), "-10:20:34.567")

	func test_format_time_sign_positive() -> void:
		assert_eq(C3Utils.format_time(3.01, true), "+00:03.010")
		assert_eq(C3Utils.format_time(65.432, true), "+01:05.432")
		assert_eq(C3Utils.format_time(3661.789, true), "+01:01:01.789")
		assert_eq(C3Utils.format_time(37234.567, true), "+10:20:34.567")
		assert_eq(C3Utils.format_time(0.0, true), "00:00.000")


class TestCubeVectorToSphere:
	extends GutTest

	const EPS := 0.0001

	func test_one_full_axis() -> void:
		var v := Vector3(0.0, 0.0, 1.0)
		var result := C3Utils.clamp_cube_vector_to_unit_sphere(v)
		assert_eq(result, v)

	func test_one_partial_axis() -> void:
		var v := Vector3(0.0, 0.0, 0.5)
		var result := C3Utils.clamp_cube_vector_to_unit_sphere(v)
		assert_eq(result, v)

	func test_two_full_axes() -> void:
		var v := Vector3(1.0, 1.0, 0.0)
		var expected := v.normalized()
		var result := C3Utils.clamp_cube_vector_to_unit_sphere(v)
		assert_eq(result, expected)

	func test_zero_returns_zero() -> void:
		var v := Vector3.ZERO
		var result := C3Utils.clamp_cube_vector_to_unit_sphere(v)
		assert_eq(result, Vector3.ZERO)

	func test_below_deadzone_returns_zero() -> void:
		var v := Vector3(0.0, 0.0, 0.05)
		var result := C3Utils.clamp_cube_vector_to_unit_sphere(v, 0.1)
		assert_eq(result, Vector3.ZERO)

	func test_at_deadzone_returns_zero() -> void:
		# Matches the documented "less than or equal" behavior.
		var deadzone := 0.2
		var v := Vector3(0.0, 0.0, deadzone)
		var result := C3Utils.clamp_cube_vector_to_unit_sphere(v, deadzone)
		assert_almost_eq(result.x, 0.0, EPS)
		assert_almost_eq(result.y, 0.0, EPS)
		assert_almost_eq(result.z, 0.0, EPS)

	func test_just_above_deadzone_is_small_and_preserves_direction() -> void:
		var deadzone := 0.2
		var v := Vector3(0.0, 0.0, 0.2001)
		var result := C3Utils.clamp_cube_vector_to_unit_sphere(v, deadzone)

		assert_gt(result.length(), 0.0)
		# Direction preserved: should still point purely +Z.
		assert_almost_eq(result.x, 0.0, EPS)
		assert_almost_eq(result.y, 0.0, EPS)
		assert_gt(result.z, 0.0)

	func test_rescale_mid_range_single_axis() -> void:
		# For axis-aligned vectors, the function should behave like:
		# output_len = inverse_lerp(deadzone, 1, input_len)
		var deadzone := 0.2
		var v := Vector3(0.0, 0.0, 0.6)  # len=0.6
		var result := C3Utils.clamp_cube_vector_to_unit_sphere(v, deadzone)

		var expected_len := inverse_lerp(deadzone, 1.0, 0.6)
		assert_almost_eq(result.length(), expected_len, EPS)
		assert_almost_eq(result.normalized().dot(v.normalized()), 1.0, EPS)

	func test_three_full_axes_clamps_to_unit_sphere() -> void:
		var v := Vector3(1.0, 1.0, 1.0)
		var result := C3Utils.clamp_cube_vector_to_unit_sphere(v)

		assert_almost_eq(result.length(), 1.0, EPS)
		assert_almost_eq(result.normalized().dot(v.normalized()), 1.0, EPS)

	func test_outside_unit_sphere_is_normalized_even_with_deadzone() -> void:
		# Once length > 1, deadzone shouldn't matter.
		var v := Vector3(0.0, 0.0, 2.0)
		var result := C3Utils.clamp_cube_vector_to_unit_sphere(v, 0.9)
		assert_eq(result, Vector3(0.0, 0.0, 1.0))

	func test_negative_components_preserved() -> void:
		var v := Vector3(-1.0, 0.0, 0.0)
		var result := C3Utils.clamp_cube_vector_to_unit_sphere(v)
		assert_eq(result, v)

	func test_diagonal_inside_unit_sphere_is_rescaled_not_normalized() -> void:
		# Pick a diagonal that is inside the unit sphere so we hit the rescale path.
		# (0.4, 0.4, 0.0) has len ~ 0.5657
		var deadzone := 0.2
		var v := Vector3(0.4, 0.4, 0.0)
		var v_len := v.length()

		var result := C3Utils.clamp_cube_vector_to_unit_sphere(v, deadzone)

		var expected_len := inverse_lerp(deadzone, 1.0, v_len)
		assert_almost_eq(result.length(), expected_len, EPS)

		# Direction preserved (parallel vectors => normalized dot ~ 1)
		assert_almost_eq(result.normalized().dot(v.normalized()), 1.0, EPS)


class TestIsAnyKey:
	extends GutTest

	# --- Helpers ---

	func _make_key_event(
		keycode: int, pressed := true, echo := false
	) -> InputEventKey:
		var event := InputEventKey.new()
		event.keycode = keycode as Key
		event.pressed = pressed
		event.echo = echo
		return event

	func _make_joypad_button_event(pressed := true) -> InputEventJoypadButton:
		var event := InputEventJoypadButton.new()
		event.button_index = JOY_BUTTON_A
		event.pressed = pressed
		return event

	func _make_mouse_button_event(pressed := true) -> InputEventMouseButton:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		return event

	func _make_mouse_wheel_event(button_index: int) -> InputEventMouseButton:
		var event := InputEventMouseButton.new()
		event.button_index = button_index as MouseButton
		event.pressed = true
		return event

	# --- Regular keys: should always count ---

	func test_letter_key_counts() -> void:
		var event := _make_key_event(KEY_A)
		assert_true(C3Utils.is_any_key(event))

	func test_space_counts() -> void:
		var event := _make_key_event(KEY_SPACE)
		assert_true(C3Utils.is_any_key(event))

	func test_enter_counts() -> void:
		var event := _make_key_event(KEY_ENTER)
		assert_true(C3Utils.is_any_key(event))

	func test_escape_counts() -> void:
		var event := _make_key_event(KEY_ESCAPE)
		assert_true(C3Utils.is_any_key(event))

	# --- Key release and echo: should not count ---

	func test_key_release_does_not_count() -> void:
		var event := _make_key_event(KEY_A, false)
		assert_false(C3Utils.is_any_key(event))

	func test_key_echo_does_not_count() -> void:
		var event := _make_key_event(KEY_A, true, true)
		assert_false(C3Utils.is_any_key(event))

	# --- Media keys: never count, regardless of include_modifiers ---

	func test_volume_up_does_not_count() -> void:
		var event := _make_key_event(KEY_VOLUMEUP)
		assert_false(C3Utils.is_any_key(event))

	func test_volume_down_does_not_count() -> void:
		var event := _make_key_event(KEY_VOLUMEDOWN)
		assert_false(C3Utils.is_any_key(event))

	func test_volume_mute_does_not_count() -> void:
		var event := _make_key_event(KEY_VOLUMEMUTE)
		assert_false(C3Utils.is_any_key(event))

	func test_media_play_does_not_count() -> void:
		var event := _make_key_event(KEY_MEDIAPLAY)
		assert_false(C3Utils.is_any_key(event))

	func test_media_keys_excluded_even_with_include_modifiers() -> void:
		# Media keys should remain excluded regardless of the modifier flag.
		for keycode in [
			KEY_VOLUMEDOWN,
			KEY_VOLUMEMUTE,
			KEY_VOLUMEUP,
			KEY_MEDIAPLAY,
			KEY_MEDIASTOP,
			KEY_MEDIAPREVIOUS,
			KEY_MEDIANEXT,
			KEY_MEDIARECORD,
		]:
			var event := _make_key_event(keycode)
			assert_false(
				C3Utils.is_any_key(event, true),
				(
					"Media key %d should not count even with include_modifiers=true"
					% keycode
				)
			)

	# --- Modifier keys: excluded by default, included when requested ---

	func test_shift_excluded_by_default() -> void:
		var event := _make_key_event(KEY_SHIFT)
		assert_false(C3Utils.is_any_key(event))

	func test_ctrl_excluded_by_default() -> void:
		var event := _make_key_event(KEY_CTRL)
		assert_false(C3Utils.is_any_key(event))

	func test_alt_excluded_by_default() -> void:
		var event := _make_key_event(KEY_ALT)
		assert_false(C3Utils.is_any_key(event))

	func test_capslock_excluded_by_default() -> void:
		var event := _make_key_event(KEY_CAPSLOCK)
		assert_false(C3Utils.is_any_key(event))

	func test_all_modifiers_excluded_by_default() -> void:
		for keycode in [
			KEY_SHIFT,
			KEY_CTRL,
			KEY_ALT,
			KEY_META,
			KEY_CAPSLOCK,
			KEY_NUMLOCK,
			KEY_SCROLLLOCK,
		]:
			var event := _make_key_event(keycode)
			assert_false(
				C3Utils.is_any_key(event),
				"Modifier key %d should be excluded by default" % keycode
			)

	func test_all_modifiers_count_when_included() -> void:
		for keycode in [
			KEY_SHIFT,
			KEY_CTRL,
			KEY_ALT,
			KEY_META,
			KEY_CAPSLOCK,
			KEY_NUMLOCK,
			KEY_SCROLLLOCK,
		]:
			var event := _make_key_event(keycode)
			assert_true(
				C3Utils.is_any_key(event, true),
				(
					"Modifier key %d should count when include_modifiers=true"
					% keycode
				)
			)

	func test_regular_key_counts_with_include_modifiers_true() -> void:
		# Sanity: include_modifiers=true should not break regular keys.
		var event := _make_key_event(KEY_A)
		assert_true(C3Utils.is_any_key(event, true))

	# --- Joypad buttons ---

	func test_joypad_button_press_counts() -> void:
		var event := _make_joypad_button_event(true)
		assert_true(C3Utils.is_any_key(event))

	func test_joypad_button_release_does_not_count() -> void:
		var event := _make_joypad_button_event(false)
		assert_false(C3Utils.is_any_key(event))

	# --- Mouse buttons ---

	func test_mouse_button_press_counts() -> void:
		var event := _make_mouse_button_event(true)
		assert_true(C3Utils.is_any_key(event))

	func test_mouse_button_release_does_not_count() -> void:
		var event := _make_mouse_button_event(false)
		assert_false(C3Utils.is_any_key(event))

	# --- Mouse wheel: never count ---

	func test_mouse_wheel_up_does_not_count() -> void:
		var event := _make_mouse_wheel_event(MOUSE_BUTTON_WHEEL_UP)
		assert_false(C3Utils.is_any_key(event))

	func test_mouse_wheel_down_does_not_count() -> void:
		var event := _make_mouse_wheel_event(MOUSE_BUTTON_WHEEL_DOWN)
		assert_false(C3Utils.is_any_key(event))

	func test_mouse_wheel_left_does_not_count() -> void:
		var event := _make_mouse_wheel_event(MOUSE_BUTTON_WHEEL_LEFT)
		assert_false(C3Utils.is_any_key(event))

	func test_mouse_wheel_right_does_not_count() -> void:
		var event := _make_mouse_wheel_event(MOUSE_BUTTON_WHEEL_RIGHT)
		assert_false(C3Utils.is_any_key(event))

	func test_all_mouse_wheel_directions_excluded() -> void:
		for button_index in [
			MOUSE_BUTTON_WHEEL_UP,
			MOUSE_BUTTON_WHEEL_DOWN,
			MOUSE_BUTTON_WHEEL_LEFT,
			MOUSE_BUTTON_WHEEL_RIGHT,
		]:
			var event := _make_mouse_wheel_event(button_index)
			assert_false(
				C3Utils.is_any_key(event),
				"Mouse wheel button %d should not count" % button_index
			)

	# --- Unrelated event types: should not count ---

	func test_mouse_motion_does_not_count() -> void:
		var event := InputEventMouseMotion.new()
		assert_false(C3Utils.is_any_key(event))

	func test_joypad_motion_does_not_count() -> void:
		var event := InputEventJoypadMotion.new()
		event.axis = JOY_AXIS_LEFT_X
		event.axis_value = 0.8
		assert_false(C3Utils.is_any_key(event))


class TestGetImageLoader:
	extends GutTest

	var _image: Image

	func before_each() -> void:
		_image = Image.new()

	func _loader(
		body: PackedByteArray,
		headers: PackedStringArray = PackedStringArray(),
		url: String = "",
	) -> Callable:
		return C3Utils._get_image_loader(body, headers, url, _image)

	# Pads `magic` with zero bytes so the body is long enough for all slice checks.
	func _pad(magic: PackedByteArray) -> PackedByteArray:
		var buf := magic.duplicate()
		buf.resize(20)
		return buf

	func test_png_magic_returns_png_loader() -> void:
		var body := _pad(PackedByteArray([0x89, 0x50, 0x4E, 0x47]))
		assert_eq(_loader(body).get_method(), "load_png_from_buffer")

	func test_jpg_magic_returns_jpg_loader() -> void:
		var body := _pad(PackedByteArray([0xFF, 0xD8, 0xFF]))
		assert_eq(_loader(body).get_method(), "load_jpg_from_buffer")

	func test_webp_magic_returns_webp_loader() -> void:
		# RIFF at bytes 0-3, file size at 4-7 (arbitrary), WEBP at bytes 8-11.
		var body := PackedByteArray([
			0x52, 0x49, 0x46, 0x46,
			0x00, 0x00, 0x00, 0x00,
			0x57, 0x45, 0x42, 0x50,
		])
		body.resize(20)
		assert_eq(_loader(body).get_method(), "load_webp_from_buffer")

	func test_riff_without_webp_marker_returns_null_loader() -> void:
		# RIFF header for a WAV file — should not be detected as WebP.
		var body := PackedByteArray([
			0x52, 0x49, 0x46, 0x46,
			0x00, 0x00, 0x00, 0x00,
			0x57, 0x41, 0x56, 0x45,
		])
		body.resize(20)
		assert_true(_loader(body).is_null())

	func test_bmp_magic_returns_bmp_loader() -> void:
		var body := _pad(PackedByteArray([0x42, 0x4D]))
		assert_eq(_loader(body).get_method(), "load_bmp_from_buffer")

	func test_dds_magic_returns_dds_loader() -> void:
		var body := _pad(PackedByteArray([0x44, 0x44, 0x53, 0x20]))
		assert_eq(_loader(body).get_method(), "load_dds_from_buffer")

	func test_exr_magic_returns_exr_loader() -> void:
		var body := _pad(PackedByteArray([0x76, 0x2F, 0x31, 0x01]))
		assert_eq(_loader(body).get_method(), "load_exr_from_buffer")

	func test_svg_content_type_returns_svg_loader() -> void:
		var body := _pad(PackedByteArray([0x3C]))
		var headers := PackedStringArray(["Content-Type: image/svg+xml"])
		assert_eq(_loader(body, headers).get_method(), "load_svg_from_buffer")

	func test_svg_content_type_case_insensitive() -> void:
		var body := _pad(PackedByteArray([0x3C]))
		var headers := PackedStringArray(["CONTENT-TYPE: IMAGE/SVG+XML"])
		assert_eq(_loader(body, headers).get_method(), "load_svg_from_buffer")

	func test_svg_content_type_with_charset_param() -> void:
		var body := _pad(PackedByteArray([0x3C]))
		var headers := PackedStringArray(["Content-Type: image/svg+xml; charset=utf-8"])
		assert_eq(_loader(body, headers).get_method(), "load_svg_from_buffer")

	func test_svg_url_extension_returns_svg_loader() -> void:
		var body := _pad(PackedByteArray([0x3C]))
		assert_eq(_loader(body, PackedStringArray(), "https://example.com/image.svg").get_method(), "load_svg_from_buffer")

	func test_svg_url_extension_case_insensitive() -> void:
		var body := _pad(PackedByteArray([0x3C]))
		assert_eq(_loader(body, PackedStringArray(), "https://example.com/image.SVG").get_method(), "load_svg_from_buffer")

	func test_non_svg_content_type_returns_null_loader() -> void:
		var body := _pad(PackedByteArray([0x3C]))
		var headers := PackedStringArray(["Content-Type: text/html"])
		assert_true(_loader(body, headers).is_null())

	func test_unknown_bytes_no_headers_no_url_returns_null_loader() -> void:
		var body := _pad(PackedByteArray([0x00, 0x01, 0x02, 0x03]))
		assert_true(_loader(body).is_null())

	func test_empty_body_returns_null_loader() -> void:
		assert_true(_loader(PackedByteArray()).is_null())

	func test_magic_takes_priority_over_svg_content_type() -> void:
		# A PNG body should be detected as PNG even if the server sent a wrong
		# Content-Type header claiming SVG.
		var body := _pad(PackedByteArray([0x89, 0x50, 0x4E, 0x47]))
		var headers := PackedStringArray(["Content-Type: image/svg+xml"])
		assert_eq(_loader(body, headers).get_method(), "load_png_from_buffer")
