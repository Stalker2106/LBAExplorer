extends Node

const image_parser = preload("res://parsers/image.gd");

# Parses HQR, ILE or OBL packages
func parse(path: String) -> Dictionary:
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("Unable to open file: " + path)
        return {}

    var package := {
        "file_size": file.get_length(),
        "entries": []
    }

    # Parse entries directory
    file.seek(0)
    var entries_offsets : Array[int] = []
    entries_offsets.append(file.get_32())

    var entries_count := int(entries_offsets[0] / 4) - 1
    for i in entries_count:
        entries_offsets.append(file.get_32())

    # Parse package entries
    for i in entries_count:
        var offset := entries_offsets[i]
        var entry = null;
        if offset != 0 && offset < package["file_size"]:
            file.seek(offset)
            entry = {
                "offset": offset,
                "original_size": file.get_32(),
                "compressed_size": file.get_32(),
                "compression": file.get_16(),
                "repeats": package["entries"].find_custom(func (pkg): return pkg && pkg.offset == offset)
            }
            entry["data"] = Compression.decompress(file, entry)
            entry["type"] = detect_entry_type(entry);
        package["entries"].append(entry)

    return package

func detect_entry_type(entry: Dictionary):
    if entry.original_size in image_parser.sizes:
        return ".LIM";
    elif entry.original_size == 768:
        return ".PAL";
    elif entry.data[0] == 8 && entry.data[1] == 0 && entry.data[2] == 0 && entry.data[3] == 0:
        return ".SPR";
    elif (entry.data[0] == 16 && entry.data[4] == 96) || (entry.data[0] == 4 && entry.data[1] == 4):
        return ".LFN";
    return "Unknown";
