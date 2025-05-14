extends Node

const image_parser = preload("res://parsers/image.gd");

# Parses HQR, ILE or OBL packages
func parse(path: String, lazy: bool):
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        Utils.console.print("Error: unable to open file: " + path, Color.RED);
        return {}
    var package := {
        "path": path,
        "entries": [],
        "entries_count": int(file.get_32() / 4) - 1,
        "loaded": false
    }
    if !lazy:
        return parse_entries(package);
    return package;

func parse_entries(package):
    var file := FileAccess.open(package.path, FileAccess.READ)
    if file == null:
        Utils.console.print("Error: unable to open file: " + package.path, Color.RED);
        return {}
    var file_size = file.get_length();
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
        if offset != 0 && offset < file_size:
            file.seek(offset)
            entry = {
                "offset": offset,
                "original_size": file.get_32(),
                "compressed_size": file.get_32(),
                "compression": file.get_16() as Compression.CompressionType,
                "repeats": package["entries"].find_custom(func (pkg): return pkg && pkg.offset == offset)
            }
            entry["data"] = Compression.decompress(file, entry);
            entry["type"] = detect_entry_type(package, i, entry);
        package["entries"].append(entry)
    package["loaded"] = true;
    return package;

func detect_entry_type(package: Dictionary, entry_index: int, entry: Dictionary):
    if package.has("metadata") && package.metadata.entries[entry_index]:
        match package.metadata.entries[entry_index].type:
            "animation":
                return Utils.EntryType.ANIMATION;
    if entry.original_size in image_parser.sizes:
        return Utils.EntryType.IMAGE;
    elif entry.original_size == 768:
        return Utils.EntryType.PALETTE;
    elif entry.data[0] == 8 && entry.data[1] == 0 && entry.data[2] == 0 && entry.data[3] == 0:
        return Utils.EntryType.SPRITE;
    elif (entry.data[0] == 16 && entry.data[4] == 96) || (entry.data[0] == 4 && entry.data[1] == 4):
        return Utils.EntryType.MODEL;
    elif ([32, 44, 60, 64, 100, 120, 140, 144, 160, 180, 200, 240].has(entry.data[8])) && (entry.data[9] == 0 || entry.data[9] == 1):
        return Utils.EntryType.ANIMATION;
    return Utils.EntryType.UNKNOWN;
