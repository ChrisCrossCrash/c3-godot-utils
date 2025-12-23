class_name State
extends Node

## Holds a reference to the parent so that it can be controlled by the state
var context: Node

func enter() -> void:
    pass

func exit() -> void:
    pass

func process_input(_event: InputEvent) -> State:
    return null

func process_frame(_delta: float) -> State:
    return null

func process_physics(_delta: float) -> State:
    return null
