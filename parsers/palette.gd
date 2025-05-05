extends Node

# Parses PAL files
func parse(entry: Dictionary) -> Array[Color]:
    if entry["original_size"] != 768:
        print("Invalid size: " + str(entry["original_size"]))
        return [];
    var palette : Array[Color] = [];
    for i in range(0, entry["original_size"], 3):
        palette.push_back(Color(entry.data[i] / 255.0, entry.data[i + 1] / 255.0, entry.data[i + 2] / 255.0));
    return palette;

func generate_random() -> Array[Color]:
    var palette : Array[Color] = [];
    for i in range(0, 256):
        palette.push_back(Color(randf_range(0.0, 1.0), randf_range(0.0, 1.0), randf_range(0.0, 1.0)));
    return palette;

const palette_width = 32;
func create_preview(palette: Array[Color]) -> Image:
    var image = Image.create_empty(palette_width, 256 / palette_width, false, Image.Format.FORMAT_RGB8);
    for i in range(0, 256):
        image.set_pixel(i % palette_width, i / palette_width, palette[i]);
    return image;
