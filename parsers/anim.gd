extends Node

func parse(entry: Dictionary) -> Dictionary:
    var sdata = StreamPeerBuffer.new();
    sdata.data_array = entry.data;
    # Parse animation
    var keyframes_count = sdata.get_u16();
    var boneframes_count = sdata.get_u16();
    var loop_start = sdata.get_u16();
    sdata.get_u16() # dummy
    # Parse keyframes
    var keyframes = [];
    for i in range(0, keyframes_count):
        var keyframe = {
            "duration": sdata.get_u16(),
            "step": Vector3(sdata.get_16(), sdata.get_u16(), sdata.get_16())
        }
        # Parse boneframes
        # types are:
        # 0 for rotation frame
        # any for position frame
        var boneframes = [];
        for j in range(0, boneframes_count):
            var bframe = {
                "type": sdata.get_u16(),
            };
            if bframe.type == 0:
                bframe["vector"] = Vector3(2 * PI * sdata.get_16() / Utils.ANGLE_MAX, 2 * PI * sdata.get_16() / Utils.ANGLE_MAX, 2 * PI * sdata.get_16() / Utils.ANGLE_MAX)
            else:
                bframe["vector"] = Vector3(sdata.get_16(), sdata.get_16(), sdata.get_16())
            boneframes.push_back(bframe);
        keyframe["boneframes"] = boneframes;
    return {
        "keyframes": keyframes,
        "loop_start": loop_start
    }
        
func build_anim(data: Dictionary) -> Animation:
    var anim = Animation.new();
    var current_time = 0;
    # Create all bones tracks
    var bone_tracks = {};
    for bone_id in range(0, data.keyframes[0].boneframes):
        bone_tracks[bone_id] = {
            "position": anim.add_track(Animation.TYPE_POSITION_3D),
            "rotation": anim.add_track(Animation.TYPE_ROTATION_3D)
        };
    # Assign all frames
    for frame in data.keyframes:
        for bone_id in range(0, frame.boneframes):
            if frame.boneframes[bone_id] == 0:
                anim.rotation_track_insert_key(bone_tracks[bone_id].rotation, current_time, frame.boneframes[bone_id].vector);
            else:
                anim.position_track_insert_key(bone_tracks[bone_id].position, current_time, frame.boneframes[bone_id].vector);
        current_time += frame.duration;
    return anim;
