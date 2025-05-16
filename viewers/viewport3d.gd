extends Control

var dragging;
var rotating;

var camera;
var camera_pivot;
var preview;
var animation_player;

var anim_dropdown;
var zoom_slider;

const MIN_ZOOM = -5000.0;

func _ready() -> void:
    camera_pivot = get_node("SubViewport3D/Viewport/CameraPivot");
    camera = get_node("SubViewport3D/Viewport/CameraPivot/Camera")
    get_node("Toolbar/ExportButton").connect("pressed", Callable(self, "export_model"));
    get_node("Toolbar/ResetButton").connect("pressed", Callable(self, "reset").bind(true));
    anim_dropdown = get_node("SubViewport3D/Viewport/CanvasLayer/AnimationsDropdown");
    anim_dropdown.connect("item_selected", Callable(self, "apply_anim"));
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
            camera_pivot.position -= Vector3(event.relative.x / 100.0 , -event.relative.y / 100.0 , 0);
        if rotating:
            camera_pivot.rotation -= Vector3(event.relative.y / 100.0 , event.relative.x / 100.0 , 0);

func reset(keep_preview: bool = false):
    if !keep_preview && preview:
        preview.queue_free();
    camera_pivot.rotation = Vector3.ZERO;
    camera_pivot.position = Vector3.ZERO;
    camera.position = Vector3(0, 10, 10);
    zoom_slider.value = -10;
    populate_anims();

func populate_anims():
    var anims = get_node("/root/App").animations;
    anim_dropdown.add_item("None");
    for anim_id in range(0, anims.size()):
        anim_dropdown.add_item("Anim%02d" % anim_id);
            
func apply_anim(selected_idx: int):
    var anim_id = selected_idx - 1;
    if anim_id < 0:
        return; #None selected
    var anim_meta = get_node("/root/App").animations[anim_id];
    var anim_entry = get_node("/root/App").packages[anim_meta.package_index].entries[anim_meta.entry_index];
    var anim_parser = load("res://parsers/anim.gd").new();
    var anim = anim_parser.build_anim(anim_parser.parse(anim_entry));
    var anim_library = AnimationLibrary.new();
    anim_library.add_animation("Anim_%02d" % anim_id, anim);
    animation_player.add_animation_library("lib", anim_library);
    

func set_preview(model: Node3D):
    preview = model;
    animation_player = AnimationPlayer.new();
    preview.add_child(animation_player);
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
    
