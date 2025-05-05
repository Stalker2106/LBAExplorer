extends Node

func parse(entry: Dictionary) -> Dictionary:
    var sdata = StreamPeerBuffer.new();
    sdata.data_array = entry.data;
    # Parse animation
    var keyframes_count = sdata.get_u16();
    var bones_count = sdata.get_u16();
    var loop_start = sdata.get_u16();
    sdata.get_u16() # dummy
    # Parse keyframes
    var keyframes = [];
    for i in range(0, keyframes_count):
        var keyframe = {
            "delay": sdata.get_u16()
        }
        sdata.get_16() # dummy
        sdata.get_u16() # dummy
        sdata.get_16() # dummy
        # Parse bones
        var bones = [];
        for j in range(0, bones_count):
            bones.append({
                "flags": sdata.get_u16(),
                "orientation": Vector3(2 * PI * sdata.get_16() / 0x400, 2 * PI * sdata.get_16() / 0x400, 2 * PI * sdata.get_16() / 0x400)
            });
        keyframe["bones"] = bones;
        keyframes.push_back(keyframe);
    return {
        "keyframes": keyframes,
        "loop_start": loop_start
    }
        
