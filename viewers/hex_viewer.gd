extends Control

const NON_PRINTABLE_CHARS = [
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
    16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28,
    29, 30, 31, 132, 133, 134, 135
];

const HexContent = preload("res://viewers/hex_content.tscn");

func reset():
    get_node("HexViewer").set_v_scroll(0);

func set_data(entry: Dictionary):
    var layout = get_node("HexViewer/Layout");
    # Clear
    for child in layout.get_children():
        child.queue_free();
    # Fill
    var header = HexContent.instantiate();
    layout.add_child(header);
    var rows = (entry.data.size() / 16) + (1 if entry.data.size() % 16 != 0 else 0);
    for i in range(0, rows):
        var row = HexContent.instantiate();
        row.get_node("Address").set_text("%08x" % (i * 16));
        var data_text = "";
        var decoded_text = "";
        for j in range(0, 16):
            if (i * 16) + j >= entry.data.size():
                break;
            var data = entry.data[(i * 16) + j];
            data_text += "%02x " % data;
            if NON_PRINTABLE_CHARS.has(data):
                decoded_text += ".";
            else:
                decoded_text += char(data);
        row.get_node("Data").set_text(data_text);
        row.get_node("Data").add_theme_color_override("font_uneditable_color", Color.WHITE);
        row.get_node("Decoded").set_text(decoded_text);
        row.get_node("Decoded").add_theme_color_override("font_uneditable_color", Color.WHITE);
        layout.add_child(row);
