extends GutTest


class TestFormatTime:
    extends GutTest

    func test_format_time_positive() -> void:
        assert_eq(Utils.format_time(3.01), "00:03.010")
        assert_eq(Utils.format_time(65.432), "01:05.432")
        assert_eq(Utils.format_time(3661.789), "01:01:01.789")
        assert_eq(Utils.format_time(37234.567), "10:20:34.567")
        assert_eq(Utils.format_time(0.0), "00:00.000")

    func test_format_time_negative() -> void:
        assert_eq(Utils.format_time(-3.01), "-00:03.010")
        assert_eq(Utils.format_time(-3.01, true), "-00:03.010")  # sign_positive has no effect on negatives
        assert_eq(Utils.format_time(-65.432), "-01:05.432")
        assert_eq(Utils.format_time(-3661.789), "-01:01:01.789")
        assert_eq(Utils.format_time(-37234.567), "-10:20:34.567")

    func test_format_time_sign_positive() -> void:
        assert_eq(Utils.format_time(3.01, true), "+00:03.010")
        assert_eq(Utils.format_time(65.432, true), "+01:05.432")
        assert_eq(Utils.format_time(3661.789, true), "+01:01:01.789")
        assert_eq(Utils.format_time(37234.567, true), "+10:20:34.567")
        assert_eq(Utils.format_time(0.0, true), "00:00.000")


class TestCubeVectorToSphere:
    extends GutTest

    const EPS := 0.0001

    func test_one_full_axis() -> void:
        var v := Vector3(0.0, 0.0, 1.0)
        var result := Utils.clamp_cube_vector_to_unit_sphere(v)
        assert_eq(result, v)

    func test_one_partial_axis() -> void:
        var v := Vector3(0.0, 0.0, 0.5)
        var result := Utils.clamp_cube_vector_to_unit_sphere(v)
        assert_eq(result, v)

    func test_two_full_axes() -> void:
        var v := Vector3(1.0, 1.0, 0.0)
        var expected := v.normalized()
        var result := Utils.clamp_cube_vector_to_unit_sphere(v)
        assert_eq(result, expected)

    func test_zero_returns_zero() -> void:
        var v := Vector3.ZERO
        var result := Utils.clamp_cube_vector_to_unit_sphere(v)
        assert_eq(result, Vector3.ZERO)

    func test_below_deadzone_returns_zero() -> void:
        var v := Vector3(0.0, 0.0, 0.05)
        var result := Utils.clamp_cube_vector_to_unit_sphere(v, 0.1)
        assert_eq(result, Vector3.ZERO)

    func test_at_deadzone_returns_zero() -> void:
        # Matches the documented "less than or equal" behavior.
        var deadzone := 0.2
        var v := Vector3(0.0, 0.0, deadzone)
        var result := Utils.clamp_cube_vector_to_unit_sphere(v, deadzone)
        assert_almost_eq(result.x, 0.0, EPS)
        assert_almost_eq(result.y, 0.0, EPS)
        assert_almost_eq(result.z, 0.0, EPS)

    func test_just_above_deadzone_is_small_and_preserves_direction() -> void:
        var deadzone := 0.2
        var v := Vector3(0.0, 0.0, 0.2001)
        var result := Utils.clamp_cube_vector_to_unit_sphere(v, deadzone)

        assert_gt(result.length(), 0.0)
        # Direction preserved: should still point purely +Z.
        assert_almost_eq(result.x, 0.0, EPS)
        assert_almost_eq(result.y, 0.0, EPS)
        assert_gt(result.z, 0.0)

    func test_rescale_mid_range_single_axis() -> void:
        # For axis-aligned vectors, the function should behave like:
        # output_len = inverse_lerp(deadzone, 1, input_len)
        var deadzone := 0.2
        var v := Vector3(0.0, 0.0, 0.6) # len=0.6
        var result := Utils.clamp_cube_vector_to_unit_sphere(v, deadzone)

        var expected_len := inverse_lerp(deadzone, 1.0, 0.6)
        assert_almost_eq(result.length(), expected_len, EPS)
        assert_almost_eq(result.normalized().dot(v.normalized()), 1.0, EPS)

    func test_three_full_axes_clamps_to_unit_sphere() -> void:
        var v := Vector3(1.0, 1.0, 1.0)
        var result := Utils.clamp_cube_vector_to_unit_sphere(v)

        assert_almost_eq(result.length(), 1.0, EPS)
        assert_almost_eq(result.normalized().dot(v.normalized()), 1.0, EPS)

    func test_outside_unit_sphere_is_normalized_even_with_deadzone() -> void:
        # Once length > 1, deadzone shouldn't matter.
        var v := Vector3(0.0, 0.0, 2.0)
        var result := Utils.clamp_cube_vector_to_unit_sphere(v, 0.9)
        assert_eq(result, Vector3(0.0, 0.0, 1.0))

    func test_negative_components_preserved() -> void:
        var v := Vector3(-1.0, 0.0, 0.0)
        var result := Utils.clamp_cube_vector_to_unit_sphere(v)
        assert_eq(result, v)

    func test_diagonal_inside_unit_sphere_is_rescaled_not_normalized() -> void:
        # Pick a diagonal that is inside the unit sphere so we hit the rescale path.
        # (0.4, 0.4, 0.0) has len ~ 0.5657
        var deadzone := 0.2
        var v := Vector3(0.4, 0.4, 0.0)
        var v_len := v.length()

        var result := Utils.clamp_cube_vector_to_unit_sphere(v, deadzone)

        var expected_len := inverse_lerp(deadzone, 1.0, v_len)
        assert_almost_eq(result.length(), expected_len, EPS)

        # Direction preserved (parallel vectors => normalized dot ~ 1)
        assert_almost_eq(result.normalized().dot(v.normalized()), 1.0, EPS)
