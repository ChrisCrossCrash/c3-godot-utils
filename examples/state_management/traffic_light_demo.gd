class_name TrafficLightDemo
extends Node


@export var red_seconds := 1.5
@export var green_seconds := 2.0
@export var yellow_seconds := 0.75

var timer := 0.0

@onready var sm: StateMachine = $TrafficLightStateMachine
@onready var label: Label = $TrafficLightLabel

# Reuse state instances (no allocations during transitions).
var red_state: State
var green_state: State
var yellow_state: State


func _ready() -> void:
    # Optional: sm.context defaults to parent in StateMachine._ready(),
    # but here's how you would set the context explicitly:
    #sm.context = self
    sm.state_changed.connect(_on_state_changed)

    # Create and store state instances.
    red_state = StateRed.new()
    green_state = StateGreen.new()
    yellow_state = StateYellow.new()

    sm.set_initial_state(red_state)


func _process(_delta: float) -> void:
    # Manual advance for quick testing (Space/Enter by default).
    if Input.is_action_just_pressed("ui_accept"):
        _manual_next()


func reset_timer() -> void:
    timer = 0.0


func set_light(text: String, color: Color) -> void:
    label.text = text
    label.add_theme_color_override("font_color", color)


func _manual_next() -> void:
    match sm.get_state_id():
        StateID.RED:
            sm.transition_to(green_state)
        StateID.GREEN:
            sm.transition_to(yellow_state)
        StateID.YELLOW:
            sm.transition_to(red_state)
        _:
            sm.transition_to(red_state)


func _on_state_changed(prev_id: int, next_id: int, _prev: State, _next: State) -> void:
    print("STATE CHANGED: %s -> %s" % [prev_id, next_id])


enum StateID {
    RED,
    GREEN,
    YELLOW
}


class StateBase:
    extends State

    # We could just access `context` from the inheriting state classes,
    # but it's nicer to have a typed `demo` interface.
    var demo: TrafficLightDemo:
        get: return context


class StateRed:
    extends StateBase

    func get_state_id() -> int:
        return StateID.RED

    func enter() -> void:
        demo.set_light("RED", Color(1.0, 0.0, 0.0))
        demo.reset_timer()
        print("ENTER RED")

    func update_physics(delta: float) -> void:
        demo.timer += delta

        if demo.timer >= demo.red_seconds:
            request_transition(demo.green_state)


class StateGreen:
    extends StateBase

    func get_state_id() -> int:
        return StateID.GREEN

    func enter() -> void:
        demo.set_light("GREEN", Color(0.0, 1.0, 0.0))
        demo.reset_timer()
        print("ENTER GREEN")

    func update_physics(delta: float) -> void:
        demo.timer += delta

        if demo.timer >= demo.green_seconds:
            request_transition(demo.yellow_state)


class StateYellow:
    extends StateBase

    func get_state_id() -> int:
        return StateID.YELLOW

    func enter() -> void:
        demo.set_light("YELLOW", Color(1.0, 1.0, 0.0))
        demo.reset_timer()
        print("ENTER YELLOW")

    func update_physics(delta: float) -> void:
        demo.timer += delta

        if demo.timer >= demo.yellow_seconds:
            request_transition(demo.red_state)
