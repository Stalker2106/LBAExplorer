extends Node

func parse(entry: Dictionary, palette: Array[Color]) -> Image:
    var sdata = StreamPeerBuffer.new();
    sdata.data_array = entry.data;
    sdata.big_endian = false;
    # Parse
    sdata.get_64() # dummy
    var size = Vector2i(sdata.get_u8(), sdata.get_u8());
    var offset = Vector2i(sdata.get_u8(), sdata.get_u8());
    var image = Image.create_empty(size.x, size.y, false, Image.Format.FORMAT_RGB8)
    for y in range(0, size.y):
        var run_count = sdata.get_u8();
        var x = 0;
        for run in range(0, run_count):
            var run_spec = sdata.get_u8();
            var run_length = (run_spec & 0b00111111) + 1;
            var type = (run_spec >> 6) & 0b00000011;
            if type == 2:
                var color = sdata.get_u8();
                for i in range(run_length):
                    image.set_pixel(x + offset.x, y + offset.y, palette[color]);
                    x += 1
            elif type == 1 or type == 3:
                for i in range(run_length):
                    image.set_pixel(x + offset.x, y + offset.y, palette[sdata.get_u8()]);
                    x += 1
            else:
                x += run_length
    return image;

func parse_raw(entry: Dictionary, palette: Array[Color]) -> Image:
    var size = Vector2i(entry.data[8], entry.data[9])
    var image = Image.create_empty(size.x, size.y, false, Image.Format.FORMAT_RGB8)
    if entry.data.size() < 12 + size.x * size.y:
        Utils.console.print("Error: Invalid sprite: size too small", Color.RED);
        return;
    for i in range(0, size.x * size.y):
        image.set_pixel(i % size.x, i / size.x, palette[entry.data[12 + i]]);
    return image;
