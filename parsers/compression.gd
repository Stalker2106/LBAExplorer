extends Node

enum CompressionType {
    NONE = 0,
    LZSS_LBA_TYPE_1 = 1,
    LZSS_LBA_TYPE_2 = 2,
}

func decompress(file: FileAccess, entry: Dictionary) -> PackedByteArray:
    if entry["compression"] == 0:
        return file.get_buffer(entry["original_size"])
    elif entry["compression"] == 1 or entry["compression"] == 2:
        var compressed_data = file.get_buffer(entry["compressed_size"])
        return decompress_lzss_lba(compressed_data, entry["original_size"], entry["compression"])
    else:
        push_error("Invalid compression type")
        return PackedByteArray();

func decompress_lzss_lba(buffer: PackedByteArray, original_size: int, compression: int) -> PackedByteArray:
    if original_size == buffer.size():
        return buffer
    var source := buffer
    var target := PackedByteArray()
    target.resize(original_size)
    var src_pos := 0
    var tgt_pos := 0
    while src_pos + 1 <= source.size():
        var flag := source[src_pos]
        for i in 8:
            src_pos += 1
            if src_pos >= source.size():
                break
            if (flag & (1 << i)) != 0:
                target[tgt_pos] = source[src_pos]
                tgt_pos += 1
            else:
                if src_pos + 1 >= source.size():
                    break
                var e := source[src_pos] * 256 + source[src_pos + 1]
                var length := ((e >> 8) & 0x0F) + compression + 1
                var addr := ((e << 4) & 0x0FF0) + ((e >> 12) & 0x00FF)

                for _i in length:
                    target[tgt_pos] = target[tgt_pos - addr - 1]
                    tgt_pos += 1
                src_pos += 1
            if src_pos + 1 >= source.size():
                break
        src_pos += 1
    return target
