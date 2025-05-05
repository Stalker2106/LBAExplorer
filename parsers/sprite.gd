extends Node

func parse(entry: Dictionary, palette: Array[Color]) -> Image:
    var size = Vector2(entry.data[8], entry.data[9])
    var image = Image.create_empty(size.x, size.y, false, Image.Format.FORMAT_RGB8)
    for i in range(12, entry.original_size):
        image.set_pixel(size.x, size.y, palette[entry.data[i]]);
    return image;
