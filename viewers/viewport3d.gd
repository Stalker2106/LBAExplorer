extends SubViewportContainer

var camera;
var dragging;

func _ready() -> void:
    camera = get_node("Viewport/Camera")
    dragging = false;

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            dragging = event.pressed;
        elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
            camera.position -= Vector3(0, 0, 1);
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            camera.position += Vector3(0, 0, 1);
    if event is InputEventMouseMotion && dragging:
        camera.position -= Vector3(event.relative.x / 100.0, -event.relative.y / 100.0, 0);

func reset_camera():
    camera.position = Vector3(0, 0, 5);

func set_preview(model: Node3D):
    get_node("Viewport/Preview").mesh = model;
