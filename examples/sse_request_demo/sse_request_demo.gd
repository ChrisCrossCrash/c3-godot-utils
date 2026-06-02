extends Control

@onready var label: Label = $Label
var _content := ""


func _ready() -> void:
	var sse := C3SSERequest.new()
	add_child(sse)
	sse.stream_started.connect(_on_stream_started)
	sse.event_received.connect(_on_event_received)
	sse.finished.connect(_on_finished)
	sse.request_failed.connect(_on_request_failed)

	var payload := {
		"model": "qwen3.5-2b",
		"messages": [{"role": "user", "content": "Count to 100."}],
		"stream": true,
	}
	var headers: PackedStringArray = [
		"Content-Type: application/json",
		"Authorization: Bearer lm-studio",
	]
	var err := sse.request(
		"http://127.0.0.1:1234/v1/chat/completions",
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(payload),
	)
	if err != OK:
		push_error("Couldn't start SSE request: %d" % err)


func _on_stream_started(code: int, _headers: PackedStringArray) -> void:
	if code != 200:
		push_warning("Non-200 response: %d" % code)


func _on_event_received(data: String, _event_type: String) -> void:
	if data == "[DONE]":
		return  # OpenAI sentinel; the finished signal follows on close anyway.
	var parsed: Variant = JSON.parse_string(data)
	if parsed == null:
		return
	var choices: Variant = parsed.get("choices")
	if not choices:
		return
	var piece: Variant = choices[0].get("delta", {}).get("content", "")
	if piece:
		_content += piece
		label.text = _content


func _on_finished() -> void:
	print("Stream complete:\n", _content)
	await get_tree().process_frame
	get_tree().quit()


func _on_request_failed(reason: String) -> void:
	push_error("SSE request failed: " + reason)
