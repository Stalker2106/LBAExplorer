extends SubViewportContainer

var camera;
var dragging;

func _ready() -> void:
    camera = get_node("Viewport/Camera")
    dragging = false;
    get_node("Viewport/CanvasLayer/PaletteButton").connect("pressed", Callable(get_node("/root/App"), "set_current_palette"));

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            dragging = event.pressed;
        elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
            camera.zoom += Vector2(0.5, 0.5);
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            camera.zoom -= Vector2(0.5, 0.5);
    if event is InputEventMouseMotion && dragging:
        camera.position -= event.relative / camera.zoom;

func reset(is_palette: bool):
    get_node("Viewport/CanvasLayer/PaletteButton").visible = is_palette;
    camera.position = Vector2.ZERO;
    camera.zoom = Vector2(1,1);

func set_zoom(vec: Vector2):
    camera.zoom = vec;

func set_preview(tex: ImageTexture):
    get_node("Viewport/Preview").set_texture(tex);
