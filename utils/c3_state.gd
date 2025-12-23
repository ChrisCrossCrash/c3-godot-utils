class_name State
## Base class for a single state in a StateMachine.[br][br]
##
## A State represents one mode of behavior for an owner object
## (e.g. a race phase, AI mode, menu screen, etc.). States are
## responsible for implementing behavior in `enter()`, `update()`,
## `update_physics()`, and `exit()`, and may request transitions to
## other states.[br][br]
##
## State instances are owned and driven by a `StateMachine`. They
## should not perform transitions directly; instead, they request
## transitions via `request_transition()`.[br][br]
##
## Concrete states are expected to override `get_state_id()` and
## typically return an enum value defined by the project.


## Reference to the object being controlled by this state.[br][br]
##
## This is assigned automatically by the StateMachine when the
## state becomes active. Concrete states may cast this to a
## project-specific type (e.g. RaceManager).
var context: Object


## State requested for transition during this state's update.
var _requested_state: State = null


## Called once when this state becomes active.[br][br]
##
## Override this to perform setup such as resetting timers,
## enabling input, or updating HUD elements.
func enter() -> void:
    pass


## Called once when this state is replaced.[br][br]
##
## Override this to perform cleanup such as stopping timers,
## disabling input, or clearing temporary state.
func exit() -> void:
    pass


## Called every render frame by the StateMachine while this state is active.[br][br]
##
## Override this to implement per-frame behavior. To request a
## transition, call `request_transition(next_state)`.
func update(_delta: float) -> void:
    pass


## Called every physics tick by the StateMachine while this state is active.[br][br]
##
## Override this to implement physics-tick behavior (movement, forces,
## collision-driven logic, etc.). To request a transition, call
## `request_transition(next_state)`.
func update_physics(_delta: float) -> void:
    pass


## Requests a transition to another state.[br][br]
##
## The transition will be applied by the StateMachine after the
## current update cycle (render or physics) completes.
func request_transition(next: State) -> void:
    _requested_state = next


## Returns and clears any requested transition.[br][br]
##
## This is consumed internally by the StateMachine.
func consume_requested_transition() -> State:
    var out := _requested_state
    _requested_state = null
    return out


## Returns an integer identifier for this state.[br][br]
##
## Concrete states must override this method and typically return
## an enum value defined by the project. This ID is used for HUD,
## debugging, and state transition signals.
func get_state_id() -> int:
    push_error("%s must override get_state_id()" % [get_class()])
    return -1
