extends GutTest


class TestParseUrl:
	extends GutTest

	var _sse: C3SSERequest

	func before_each() -> void:
		_sse = C3SSERequest.new()
		add_child_autofree(_sse)

	func test_http_scheme_sets_no_ssl() -> void:
		_sse._parse_url("http://example.com/")
		assert_false(_sse._use_ssl)

	func test_https_scheme_sets_ssl() -> void:
		_sse._parse_url("https://example.com/")
		assert_true(_sse._use_ssl)

	func test_http_default_port_is_80() -> void:
		_sse._parse_url("http://example.com/")
		assert_eq(_sse._port, 80)

	func test_https_default_port_is_443() -> void:
		_sse._parse_url("https://example.com/")
		assert_eq(_sse._port, 443)

	func test_custom_port_parsed() -> void:
		_sse._parse_url("http://127.0.0.1:1234/path")
		assert_eq(_sse._port, 1234)

	func test_host_extracted() -> void:
		_sse._parse_url("http://api.example.com/v1")
		assert_eq(_sse._host, "api.example.com")

	func test_path_extracted() -> void:
		_sse._parse_url("http://example.com/v1/chat/completions")
		assert_eq(_sse._path, "/v1/chat/completions")

	func test_root_path_when_no_slash_after_host() -> void:
		_sse._parse_url("http://example.com")
		assert_eq(_sse._path, "/")

	func test_query_string_preserved_in_path() -> void:
		_sse._parse_url("http://example.com/search?q=hello&n=5")
		assert_eq(_sse._path, "/search?q=hello&n=5")

	func test_returns_true_for_valid_http() -> void:
		assert_true(_sse._parse_url("http://example.com/"))

	func test_returns_true_for_valid_https() -> void:
		assert_true(_sse._parse_url("https://example.com/"))

	func test_returns_false_for_unknown_scheme() -> void:
		assert_false(_sse._parse_url("ftp://example.com/"))

	func test_returns_false_for_bare_string() -> void:
		assert_false(_sse._parse_url("not-a-url"))

	func test_returns_false_for_empty_string() -> void:
		assert_false(_sse._parse_url(""))

	func test_returns_false_for_empty_host() -> void:
		assert_false(_sse._parse_url("http:///path"))

	func test_localhost_pushes_warning() -> void:
		_sse._parse_url("http://localhost/path")
		assert_push_warning_count(1)

	func test_127_0_0_1_no_warning() -> void:
		_sse._parse_url("http://127.0.0.1/path")
		assert_push_warning_count(0)


class TestEmitEvent:
	extends GutTest

	var _sse: C3SSERequest

	func before_each() -> void:
		_sse = C3SSERequest.new()
		add_child_autofree(_sse)
		watch_signals(_sse)

	func test_single_data_line_emits_event() -> void:
		_sse._emit_event("data: hello")
		assert_signal_emitted_with_parameters(_sse, "event_received", ["hello", "message"])

	func test_leading_space_after_colon_stripped() -> void:
		_sse._emit_event("data: with space")
		assert_signal_emitted_with_parameters(_sse, "event_received", ["with space", "message"])

	func test_no_leading_space_value_unchanged() -> void:
		_sse._emit_event("data:no-space")
		assert_signal_emitted_with_parameters(_sse, "event_received", ["no-space", "message"])

	func test_multiple_data_lines_joined_with_newline() -> void:
		_sse._emit_event("data: line one\ndata: line two")
		assert_signal_emitted_with_parameters(_sse, "event_received", ["line one\nline two", "message"])

	func test_comment_line_suppressed() -> void:
		_sse._emit_event(": keep-alive")
		assert_signal_not_emitted(_sse, "event_received")

	func test_comment_mixed_with_data_only_data_emitted() -> void:
		_sse._emit_event(": comment\ndata: real")
		assert_signal_emitted_with_parameters(_sse, "event_received", ["real", "message"])

	func test_event_type_surfaced_with_data() -> void:
		_sse._emit_event("event: update\ndata: payload")
		assert_signal_emitted_with_parameters(_sse, "event_received", ["payload", "update"])

	func test_event_type_defaults_to_message_when_absent() -> void:
		_sse._emit_event("data: hello")
		assert_signal_emitted_with_parameters(_sse, "event_received", ["hello", "message"])

	func test_empty_event_emits_nothing() -> void:
		_sse._emit_event("")
		assert_signal_not_emitted(_sse, "event_received")

	func test_only_comments_emits_nothing() -> void:
		_sse._emit_event(": ping\n: pong")
		assert_signal_not_emitted(_sse, "event_received")

	func test_event_field_alone_emits_nothing() -> void:
		_sse._emit_event("event: message")
		assert_signal_not_emitted(_sse, "event_received")

	func test_id_field_alone_emits_nothing() -> void:
		_sse._emit_event("id: 42")
		assert_signal_not_emitted(_sse, "event_received")

	func test_retry_field_alone_emits_nothing() -> void:
		_sse._emit_event("retry: 3000")
		assert_signal_not_emitted(_sse, "event_received")

	func test_id_field_with_data_emits_only_data() -> void:
		_sse._emit_event("id: 42\ndata: hello")
		assert_signal_emitted_with_parameters(_sse, "event_received", ["hello", "message"])

	func test_retry_field_with_data_emits_only_data() -> void:
		_sse._emit_event("retry: 3000\ndata: hello")
		assert_signal_emitted_with_parameters(_sse, "event_received", ["hello", "message"])

	func test_event_emitted_exactly_once() -> void:
		_sse._emit_event("data: once")
		assert_signal_emit_count(_sse, "event_received", 1)


class TestDrainBuffer:
	extends GutTest

	var _sse: C3SSERequest

	func before_each() -> void:
		_sse = C3SSERequest.new()
		add_child_autofree(_sse)
		watch_signals(_sse)

	func test_complete_event_emits_signal() -> void:
		_sse._buffer = "data: hello\n\n"
		_sse._drain_buffer()
		assert_signal_emitted_with_parameters(_sse, "event_received", ["hello", "message"])

	func test_complete_event_clears_buffer() -> void:
		_sse._buffer = "data: hello\n\n"
		_sse._drain_buffer()
		assert_eq(_sse._buffer, "")

	func test_two_complete_events_emit_two_signals() -> void:
		_sse._buffer = "data: first\n\ndata: second\n\n"
		_sse._drain_buffer()
		assert_signal_emit_count(_sse, "event_received", 2)

	func test_partial_event_not_emitted() -> void:
		_sse._buffer = "data: no-terminator"
		_sse._drain_buffer()
		assert_signal_not_emitted(_sse, "event_received")

	func test_partial_event_preserved_in_buffer() -> void:
		_sse._buffer = "data: no-terminator"
		_sse._drain_buffer()
		assert_eq(_sse._buffer, "data: no-terminator")

	func test_partial_tail_preserved_after_complete_event() -> void:
		_sse._buffer = "data: done\n\ndata: partial"
		_sse._drain_buffer()
		assert_signal_emit_count(_sse, "event_received", 1)
		assert_eq(_sse._buffer, "data: partial")

	func test_empty_buffer_no_signal() -> void:
		_sse._buffer = ""
		_sse._drain_buffer()
		assert_signal_not_emitted(_sse, "event_received")


class TestRequestErrors:
	extends GutTest

	var _sse: C3SSERequest

	func before_each() -> void:
		_sse = C3SSERequest.new()
		add_child_autofree(_sse)

	func test_invalid_url_returns_err_invalid_parameter() -> void:
		var err := _sse.request("not-a-url")
		assert_eq(err, ERR_INVALID_PARAMETER)

	func test_empty_url_returns_err_invalid_parameter() -> void:
		var err := _sse.request("")
		assert_eq(err, ERR_INVALID_PARAMETER)

	func test_unsupported_scheme_returns_err_invalid_parameter() -> void:
		var err := _sse.request("ftp://example.com/")
		assert_eq(err, ERR_INVALID_PARAMETER)

	func test_busy_when_connecting() -> void:
		_sse._state = C3SSERequest._State.CONNECTING
		var err := _sse.request("http://example.com/")
		assert_eq(err, ERR_BUSY)

	func test_busy_when_requesting() -> void:
		_sse._state = C3SSERequest._State.REQUESTING
		var err := _sse.request("http://example.com/")
		assert_eq(err, ERR_BUSY)

	func test_busy_when_streaming() -> void:
		_sse._state = C3SSERequest._State.STREAMING
		var err := _sse.request("http://example.com/")
		assert_eq(err, ERR_BUSY)


class TestFinish:
	extends GutTest

	var _sse: C3SSERequest

	func before_each() -> void:
		_sse = C3SSERequest.new()
		add_child_autofree(_sse)
		watch_signals(_sse)

	func test_finish_emits_finished() -> void:
		_sse._finish()
		assert_signal_emitted(_sse, "finished")

	func test_finish_resets_state_to_idle() -> void:
		_sse._state = C3SSERequest._State.STREAMING
		_sse._finish()
		assert_eq(_sse._state, C3SSERequest._State.IDLE)

	func test_finish_clears_buffer() -> void:
		_sse._buffer = "leftover"
		_sse._finish()
		assert_eq(_sse._buffer, "")

	func test_finish_flushes_unterminated_data() -> void:
		_sse._buffer = "data: final chunk"
		_sse._finish()
		assert_signal_emitted(_sse, "event_received")

	func test_finish_skips_whitespace_only_buffer() -> void:
		_sse._buffer = "  \n  "
		_sse._finish()
		assert_signal_not_emitted(_sse, "event_received")

	func test_finish_stops_processing() -> void:
		_sse.set_process(true)
		_sse._finish()
		assert_false(_sse.is_processing())


class TestFail:
	extends GutTest

	var _sse: C3SSERequest

	func before_each() -> void:
		_sse = C3SSERequest.new()
		add_child_autofree(_sse)
		watch_signals(_sse)

	func test_fail_emits_request_failed_with_reason() -> void:
		_sse._fail("something broke")
		assert_signal_emitted_with_parameters(_sse, "request_failed", ["something broke"])

	func test_fail_resets_state_to_idle() -> void:
		_sse._state = C3SSERequest._State.STREAMING
		_sse._fail("error")
		assert_eq(_sse._state, C3SSERequest._State.IDLE)

	func test_fail_clears_buffer() -> void:
		_sse._buffer = "partial data"
		_sse._fail("error")
		assert_eq(_sse._buffer, "")

	func test_fail_stops_processing() -> void:
		_sse.set_process(true)
		_sse._fail("error")
		assert_false(_sse.is_processing())

	func test_fail_does_not_emit_finished() -> void:
		_sse._fail("error")
		assert_signal_not_emitted(_sse, "finished")


class TestIsOk:
	extends GutTest

	var _sse: C3SSERequest

	func before_each() -> void:
		_sse = C3SSERequest.new()
		add_child_autofree(_sse)

	func test_200_is_ok() -> void:
		assert_true(_sse._is_ok(200))

	func test_201_is_ok() -> void:
		assert_true(_sse._is_ok(201))

	func test_299_is_ok() -> void:
		assert_true(_sse._is_ok(299))

	func test_199_is_not_ok() -> void:
		assert_false(_sse._is_ok(199))

	func test_300_is_not_ok() -> void:
		assert_false(_sse._is_ok(300))

	func test_404_is_not_ok() -> void:
		assert_false(_sse._is_ok(404))

	func test_500_is_not_ok() -> void:
		assert_false(_sse._is_ok(500))


class TestFinishErrorBody:
	extends GutTest

	var _sse: C3SSERequest

	func before_each() -> void:
		_sse = C3SSERequest.new()
		add_child_autofree(_sse)
		watch_signals(_sse)

	func test_emits_response_error_with_code_and_body() -> void:
		_sse._response_code = 401
		_sse._buffer = '{"error": "bad key"}'
		_sse._finish_error_body()
		assert_signal_emitted_with_parameters(
			_sse, "response_error", [401, '{"error": "bad key"}']
		)

	func test_emits_empty_body_when_buffer_empty() -> void:
		_sse._response_code = 503
		_sse._buffer = ""
		_sse._finish_error_body()
		assert_signal_emitted_with_parameters(_sse, "response_error", [503, ""])

	func test_resets_state_to_idle() -> void:
		_sse._state = C3SSERequest._State.ERROR_BODY
		_sse._finish_error_body()
		assert_eq(_sse._state, C3SSERequest._State.IDLE)

	func test_clears_buffer() -> void:
		_sse._buffer = "leftover"
		_sse._finish_error_body()
		assert_eq(_sse._buffer, "")

	func test_stops_processing() -> void:
		_sse.set_process(true)
		_sse._finish_error_body()
		assert_false(_sse.is_processing())

	func test_does_not_emit_finished() -> void:
		_sse._finish_error_body()
		assert_signal_not_emitted(_sse, "finished")


class TestBusyDuringErrorBody:
	extends GutTest

	var _sse: C3SSERequest

	func before_each() -> void:
		_sse = C3SSERequest.new()
		add_child_autofree(_sse)

	func test_busy_when_receiving_error_body() -> void:
		_sse._state = C3SSERequest._State.ERROR_BODY
		var err := _sse.request("http://example.com/")
		assert_eq(err, ERR_BUSY)
