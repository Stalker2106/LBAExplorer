extends ScrollContainer

const HexContent = preload("res://viewers/hex_content.tscn");

func set_data(entry: Dictionary):
    var layout = get_node("Layout");
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
            decoded_text += "." if data == 0 else char(data);
        row.get_node("Data").set_text(data_text);
        row.get_node("Decoded").set_text(decoded_text);
        layout.add_child(row);
