extends BaseLightState
class_name RedState

func enter() -> void:
    super()  # The super class sets the color of the text.
    demo.label.text = "RED"

func process_frame(delta: float) -> BaseLightState:
    elapsed_time += delta

    if elapsed_time >= duration:
        elapsed_time = 0.0
        return green_state

    return null
