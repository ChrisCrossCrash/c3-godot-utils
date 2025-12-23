class_name StateMachine
extends Node
## A lightweight, context-driven finite state machine.[br][br]
##
## StateMachine manages a single active `State` instance, forwarding
## per-frame and per-physics-tick updates and handling requested
## transitions. States request transitions via `request_transition()`;
## the machine performs the actual swap, calling `exit()` and `enter()`
## hooks as appropriate.[br][br]
##
## The machine itself is agnostic to the meaning of state IDs — projects
## are expected to define their own enums and return them from
## `State.get_state_id()`.[br][br]
##
## Typical usage:[br]
## - Add StateMachine as a child of the controlling node (the "context")[br]
## - Set the initial State[br]
## - Optionally assign `context` if it is not the parent node[br]
## - Listen to `state_changed` for transitions[br][br]
##
## By default, StateMachine runs itself via `_process()` and
## `_physics_process()`. You may disable either loop via the exported
## toggles, or call `update()` / `update_physics()` manually.


## Emitted whenever the active state changes.[br][br]
##
## `prev_id` and `next_id` are integer identifiers returned by
## `State.get_state_id()` (usually enum values defined by the project).[br]
## `prev_state` and `next_state` provide direct access to the state
## instances involved in the transition.
signal state_changed(
    prev_id: int,
    next_id: int,
    prev_state: State,
    next_state: State
)


## If true, forwards render-frame updates to the active state.
@export var run_process := true


## If true, forwards physics-tick updates to the active state.
@export var run_physics := true


## Object being controlled by this state machine.[br][br]
##
## This is typically the parent node, but may be set explicitly if the
## state machine is used to control a different object.
var context: Object


## Currently active state instance.
var _state: State = null


## Called when the StateMachine enters the scene tree.[br][br]
##
## If `context` has not been assigned explicitly, it defaults to the
## StateMachine's parent node.
func _ready() -> void:
    # Default context to parent for the common "add as child component" pattern.
    if context == null:
        context = get_parent()


## Forwards render-frame updates to the active state.[br][br]
##
## This is driven automatically by Godot's `_process()` callback when
## `run_process` is enabled.
func _process(delta: float) -> void:
    if run_process:
        update(delta)


## Forwards physics-tick updates to the active state.[br][br]
##
## This is driven automatically by Godot's `_physics_process()` callback
## when `run_physics` is enabled.
func _physics_process(delta: float) -> void:
    if run_physics:
        update_physics(delta)


## Sets the initial active state without emitting `state_changed`.[br][br]
##
## Intended for one-time setup during initialization. The state's
## `enter()` method is called immediately.
func set_initial_state(state: State) -> void:
    _set_state_internal(state, false)


## Advances the state machine by one render frame.[br][br]
##
## Calls `State.update(delta)` on the active state and applies any
## transition requested during that update.
func update(delta: float) -> void:
    if not _state:
        return

    _state.update(delta)

    var requested := _state.consume_requested_transition()
    if requested:
        transition_to(requested)


## Advances the state machine by one physics tick.[br][br]
##
## Calls `State.update_physics(delta)` on the active state and applies
## any transition requested during that update.
func update_physics(delta: float) -> void:
    if not _state:
        return

    _state.update_physics(delta)

    var requested := _state.consume_requested_transition()
    if requested:
        transition_to(requested)


## Transitions to the given state instance.[br][br]
##
## Calls `exit()` on the current state (if any), then activates the new
## state and calls its `enter()` method. Emits `state_changed` on success.
func transition_to(next: State) -> void:
    if not next:
        return
    if _state == next:
        return

    var prev := _state
    var prev_id := prev.get_state_id() if prev else -1
    var next_id := next.get_state_id()

    if prev:
        prev.exit()

    _state = next
    _state.context = context
    _state.enter()

    state_changed.emit(prev_id, next_id, prev, _state)


## Returns the currently active state instance.
func get_state() -> State:
    return _state


## Returns the ID of the currently active state.[br][br]
##
## If no state is active, returns -1.
func get_state_id() -> int:
    return _state.get_state_id() if _state else -1


## Internal helper for assigning a state.[br][br]
##
## Used during initialization to activate a state without triggering
## a transition signal.
func _set_state_internal(state: State, should_emit_signal: bool) -> void:
    _state = state
    if _state:
        _state.context = context
        _state.enter()
    if should_emit_signal:
        state_changed.emit(-1, get_state_id(), null, _state)
