extends Control

var camera;
var dragging;
var rotating;

var preview;

var zoom_slider;

const MIN_ZOOM = -5000.0;

func _ready() -> void:
    camera = get_node("SubViewport3D/Viewport/Camera")
    get_node("Toolbar/ExportButton").connect("pressed", Callable(self, "export_model"));
    get_node("Toolbar/ResetButton").connect("pressed", Callable(self, "reset").bind(true));
    zoom_slider = get_node("SubViewport3D/Viewport/CanvasLayer/ZoomSlider/VSlider");
    zoom_slider.min_value = MIN_ZOOM;
    dragging = false;
    rotating = false;

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            dragging = event.pressed;
        if event.button_index == MOUSE_BUTTON_RIGHT:
            rotating = event.pressed;
        elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
            update_zoom(3);
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            update_zoom(-3);
    if event is InputEventMouseMotion:
        if dragging:
            camera.position -= Vector3(event.relative.x / 100.0 , -event.relative.y / 100.0 , 0);
        if rotating:
            preview.rotation += Vector3(event.relative.y / 100.0 , event.relative.x / 100.0 , 0);

func reset(keep_preview: bool = false):
    if !keep_preview && preview:
        preview.queue_free();
    elif keep_preview:
        preview.rotation = Vector3.ZERO;        
    camera.position = Vector3(0, 20, 20);
    zoom_slider.value = -10;

func set_preview(model: Node3D):
    preview = model;
    get_node("SubViewport3D/Viewport").add_child(preview);

func export_model():
    if !preview:
        return;
    var export_dialog = get_node("/root/App/ExportFileDialog")
    export_dialog.visible = true;
    export_dialog.current_file = "model.glb";
    await export_dialog.confirmed;
    var export_path = export_dialog.current_path;
    var gltf_document := GLTFDocument.new();
    var gltf_state := GLTFState.new();
    gltf_document.append_from_scene(preview, gltf_state);
    gltf_document.write_to_filesystem(gltf_state, export_path);

func update_zoom(value: float):
    zoom_slider.set_value(zoom_slider.value + value);
    camera.position.z = -zoom_slider.value;
    
