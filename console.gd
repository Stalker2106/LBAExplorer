extends MarginContainer

const CONSOLE_LIMIT = 500;

var input;
var index;

func _ready() -> void:
    Utils.console = self;
    index = 0;
    input = get_node("Layout/Input");

func _input(event: InputEvent) -> void:
    if input.has_focus() && event is InputEventKey \
        && (event.keycode == KEY_ENTER || event.keycode == KEY_KP_ENTER):
        input.set_text("");

func print(message: String, color: Color = Color.GRAY, hide_index: bool = false):
    var container = get_node("Layout/Content/VBoxContainer");
    if container.get_child_count() > CONSOLE_LIMIT:
        for i in range(0, container.get_child_count() - CONSOLE_LIMIT):
            container.get_child(i).queue_free();
    var label = Label.new();
    if hide_index:
        label.set_text(message);
    else:
        label.set_text("%d: %s" % [index, message]);
    label.add_theme_color_override("font_color", color);
    label.add_theme_font_override("font", load("res://assets/courrier.ttf"));
    container.add_child(label);
    var scroll_container = get_node("Layout/Content");
    scroll_container.set_v_scroll(scroll_container.get_v_scroll_bar().max_value);
    index += 1;
