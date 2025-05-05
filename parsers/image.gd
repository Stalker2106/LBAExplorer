extends Node

# Parses LIM files
const sizes = {
    307200: {
        "width": 640,
        "height": 480
    },
    131884: {
        "width": 512,
        "height": 256
    },
    65536: {
        "width": 256,
        "height": 256
    }
}

func parse(entry: Dictionary, palette: Array[Color]) -> Image:
    if entry["original_size"] not in sizes:
        print("Invalid size: " + str(entry["original_size"]))
        return null;
    var size = sizes[entry["original_size"]];
    var image = Image.create_empty(size.width, size.height, false, Image.Format.FORMAT_RGB8);
    for i in range(0, entry["original_size"]):
        image.set_pixel(i % size.width, i / size.width, palette[entry.data[i]]);
    return image;
