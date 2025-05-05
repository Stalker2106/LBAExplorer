extends Node

func parse(entry: Dictionary) -> Dictionary:
    var sdata = StreamPeerBuffer.new();
    sdata.data_array = entry.data;
    # Start parse
    var flags = sdata.get_u16();
    sdata.get_string(2 * 12) # dummy
    # Parse vertices
    var vertices: Array[Vector3] = [];
    var vertices_count = sdata.get_u16();
    for i in range(0, vertices_count):
        vertices.push_back(Vector3(sdata.get_16(), sdata.get_16(), sdata.get_16()));
    # Parse bones
    var bones = [];
    var bones_count = sdata.get_u16();
    for i in range(0, bones_count):
        var bone = {
            "first_point": sdata.get_u16() / 6,
            "points_count": sdata.get_u16(),
            "parent_point": sdata.get_u16() / 6,
            "parent_bone": sdata.get_16() / 38,
            "bone_type": sdata.get_u16(),
            "vert": Vector3(sdata.get_16(), sdata.get_16(), sdata.get_16()),
            "normals_count": sdata.get_u16(),
        }
        sdata.get_string(2 + 4 + 4 + 4 + 4 + 2) # dummy
        bones.push_back(bone);
    # Parse normals
    var normals = [];
    var normals_count = sdata.get_u16();
    for i in range(0, normals_count):
        var normal = Vector3(sdata.get_16(), sdata.get_16(), sdata.get_16());
        sdata.get_16() # dummy
        normals.push_back(normal);
    # Parse poly
    var polygons = []
    var polygons_count = sdata.get_u16();
    for i in range(0, polygons_count):
        var polygon = {
            "render_type": sdata.get_u8(),
            "vertices_count": sdata.get_u8(),
            "color_index": sdata.get_u8()
        }
        sdata.get_u8() # dummy
        # Parse poly vertices
        var polygon_vertices = []
        if polygon.render_type >= 9: # each vertex has a normal
            for j in range(0, polygon.vertices_count):
                polygon_vertices.push_back({
                    "normal_index": sdata.get_u16(),
                    "vert_index": sdata.get_u16()
                })
        elif polygon.render_type >= 7: # one normal for the whole polygon
            var normal_index = sdata.get_u16();
            for j in range(0, polygon.vertices_count):
                polygon_vertices.push_back({
                    "normal_index": normal_index,
                    "vert_index": sdata.get_u16()
                })
        else: # no normal (?)
            for j in range(polygon.vertices_count):
                polygon_vertices.push_back({
                    "normal_index": null,
                    "vert_index": sdata.get_u16()
                })
        polygon["polygon_vertices"] = polygon_vertices;
        polygons.push_back(polygon);
    # Parse edges
    var edges = [];
    var edges_count = sdata.get_u16();
    for i in range(0, edges_count):
        sdata.get_u32() # dummy
        edges.push_back({
            "vertex_index_0": sdata.get_u16(),
            "vertex_index_1": sdata.get_u16()
        })
    # Parse circles (?)
    var circles = []
    var circles_count = sdata.get_u16();
    for i in range(0, circles_count):
        sdata.get_u8() # dummy
        var circle = {
            "color": sdata.get_u8()
        }
        sdata.get_u16() # dummy
        circle["size"] = sdata.get_u16()
        circle["vertex_index"] = sdata.get_u16() / 6
        circles.push_back(circle);
    # return all data
    return {
        "vertices": vertices,
        "bones": bones,
        "normals": normals,
        "polygons": polygons,
        "edges": edges,
        "circles": circles
    };

func build_skeleton(data: Dictionary):
    var skeleton = Skeleton3D.new();
    # Add all bones
    for bone_index in range(0, data.bones.size()):
        skeleton.add_bone("Bone%d" % bone_index);
    # Configure bones
    for bone_index in range(0, data.bones.size()):
        skeleton.set_bone_parent(bone_index, data.bones[bone_index].parent_bone);
        skeleton.set_bone_pose_position(bone_index, data.bones[bone_index].vert);
    # Build model
    for polygon_index in range(0, data.polygons.size()):
        var meshInstance = MeshInstance3D.new();
        skeleton.add_child(meshInstance);
    return skeleton;
