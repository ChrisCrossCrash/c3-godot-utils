extends Node
class_name TrafficLightDemo

@onready var state_machine: StateMachine = $StateMachine
@onready var label: Label = $TrafficLightLabel

func _ready() -> void:
    state_machine.init(self)
