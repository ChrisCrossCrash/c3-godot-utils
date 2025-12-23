extends Node
class_name StateMachine

@export var starting_state: State

var current_state: State

# Initialize the state machine by giving each child state a reference to the
# context node it belongs to and enter the default starting_state.
func init(context: Node) -> void:
    for child in get_children():
        child.context = context

    # Initialize to the default state
    change_state(starting_state)

# Change to the new state by first calling any exit logic on the current state.
func change_state(new_state: State) -> void:
    if current_state:
        current_state.exit()

    print(new_state)
    current_state = new_state
    current_state.enter()

# Pass through functions for the context node to call,
# handling state changes as needed.
func _physics_process(delta: float) -> void:
    var new_state = current_state.process_physics(delta)
    if new_state:
        change_state(new_state)

func _unhandled_input(event: InputEvent) -> void:
    var new_state = current_state.process_input(event)
    if new_state:
        change_state(new_state)

func _process(delta: float) -> void:
    var new_state = current_state.process_frame(delta)
    if new_state:
        change_state(new_state)
