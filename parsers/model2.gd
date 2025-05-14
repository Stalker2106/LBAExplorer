extends Node

func parse(entry: Dictionary) -> Dictionary:
    var sdata = StreamPeerBuffer.new();
    sdata.data_array = entry.data;
    sdata.big_endian = false;
    # Start parse
    var flags = sdata.get_32();
    sdata.seek(0x20);
    var bones_count = sdata.get_u32();
    var bones_offset = sdata.get_u32();
    var vertices_count = sdata.get_u32();
    var vertices_offset = sdata.get_u32();
    var normals_count = sdata.get_u32();
    var normals_offset = sdata.get_u32();
    sdata.get_u32(); # dummy
    sdata.get_u32(); # dummy
    var meshes_count = sdata.get_u32();
    var meshes_offset = sdata.get_u32();
    var edges_count = sdata.get_u32();
    var edges_offset = sdata.get_u32();
    var spheres_count = sdata.get_u32();
    var spheres_offset = sdata.get_u32();
    var uv_count = sdata.get_u32();
    var uv_offset = sdata.get_u32();
    # Parse bones
    var bones = [];
    sdata.seek(bones_offset);
    for i in range(0, bones_count):
        var bone = {
            "parent_bone": sdata.get_u16(),
            "vertex_index": sdata.get_u16()
        }
        sdata.get_u16() # dummy
        sdata.get_u16() # dummy
        bones.push_back(bone);
    # Parse vertices
    var vertices: Array[Dictionary] = [];
    sdata.seek(vertices_offset);
    for i in range(0, vertices_count):
        var vert = {
            "position": Vector3(sdata.get_16(), sdata.get_16(), sdata.get_16()) * Utils.WORLD_SCALE,
            "bone": sdata.get_u16()
        }
        vertices.push_back(vert);
    # Parse normals
    var normals = [];
    sdata.seek(normals_offset);
    for i in range(0, normals_count):
        var normal = Vector3(sdata.get_16(), sdata.get_16(), sdata.get_16());
        sdata.get_16() # dummy
        normals.push_back(normal);
    # Parse meshes
    var current_mesh_offset = meshes_offset;
    sdata.seek(meshes_offset);
    var meshes = [];
    while current_mesh_offset < edges_offset:
            meshes.push_back(parse_mesh(sdata));
            current_mesh_offset = sdata.get_position();
    # Parse edges
    var edges = [];
    sdata.seek(edges_offset);
    for i in range(0, edges_count):
        sdata.get_u16() # dummy
        var color_raw = sdata.get_u16();
        edges.push_back({
            "color_index": (color_raw & 0x00FF) / 16,
            "vertex_index_0": sdata.get_u16(),
            "vertex_index_1": sdata.get_u16()
        })
    # Parse spheres
    var spheres = []
    sdata.seek(spheres_offset);
    for i in range(0, spheres_count):
        sdata.get_u16() # dummy
        sdata.get_u8() # dummy
        var sphere = {
            "color_index": sdata.get_u8(),
            "vertex_index": sdata.get_u16(),
            "size": sdata.get_u8() * Utils.WORLD_SCALE,
        }
        sdata.get_u8() # dummy
        spheres.push_back(sphere);
    # Parse textures
    var uvs = []
    sdata.seek(uv_offset);
    for i in range(0, uv_count):
        var uv = Vector4(sdata.get_u8(), sdata.get_u8(), sdata.get_u8(), sdata.get_u8());
        uvs.push_back(uv);
    # return all data
    var model_data = {
        "vertices": vertices,
        "bones": bones,
        "normals": normals,
        "meshes": meshes,
        "edges": edges,
        "spheres": spheres,
        "uvs": uvs
    };
    return model_data;

func parse_mesh(sdata: StreamPeerBuffer):
    var mesh_offset = sdata.get_position();
    var render_type = sdata.get_u16();
    var mesh = {
        "mesh_type": (render_type >> 8) & 0xFF,
        "render_type": render_type,
        "faces_count": sdata.get_u16(),
        "size": sdata.get_u16()
    }
    sdata.get_u16() # dummy
    # Parse faces
    var faces = []
    if mesh.size > 0 && mesh.faces_count > 0:
        # Blocksizes:
        # Quad and Extra = 16
        # Quad and Tex = 32
        # Quad and Color = 12
        # Tri and Extra = 16
        # Tri and Tex = 24
        # Tri and Color = 12
        var face_block_size = (mesh.size - 8) / mesh.faces_count;
        var vertex_count = 4 if (mesh.render_type & 0x8000) else 3;
        var has_texture = mesh.mesh_type > 7 && face_block_size > 16;
        # Parse faces
        var faces_offset = sdata.get_position();
        for i in range(0, mesh.faces_count):
            sdata.seek(faces_offset + (i * face_block_size));
            var face = {};
            for v in vertex_count:
                face["vertex_index_%d" % v] = sdata.get_u16();
            # If it has a triangulated texture
            if has_texture && vertex_count == 3:
                sdata.get_u8(); # should not be dummy
                sdata.get_u8(); # dummy
            else:
                sdata.get_u16(); # dummy
            var color = sdata.get_u8();
            face["color_index"] = color / 16;
            face["intensity"] = color % 16;
            if has_texture:
                for v in vertex_count:
                    face["u_%d" % v] = sdata.get_u8();
                    face["v_%d" % v] = sdata.get_u8();
                # for blocksize 32 with quad texture
                if vertex_count == 4:
                    sdata.get_u8(); # should not be dummy
            faces.push_back(face);
    mesh["faces"] = faces;
    sdata.seek(mesh_offset + mesh.size);
    return mesh;

func add_vertex(st: SurfaceTool, node, vertices: Array, normals: Array, vertex_index: int):
    if vertex_index > vertices.size():
        Utils.console.print("Error: vertex index %d is invalid" % vertex_index, Color.RED);
        return;
    st.set_normal(normals[vertex_index]);
    if node is Skeleton3D:
        var bone_id = vertices[vertex_index].bone;
        var bone_rest_transform = node.get_bone_rest(bone_id);
        st.set_weights([1.0, 0.0, 0.0, 0.0]);
        st.set_bones([bone_id, 0, 0, 0]);
        st.add_vertex(bone_rest_transform.origin + vertices[vertex_index].position);
    else:
        st.add_vertex(vertices[vertex_index].position);

func build_model(data: Dictionary, palette: Array[Color]) -> Node3D:
    var node = null;
    if data.bones.size() > 0:
        node = Skeleton3D.new();
        node.show_rest_only = true;
        # Add bones if necessary
        for bone_id in range(0, data.bones.size()):
            node.add_bone("bone%02d" % bone_id);
        for bone_id in range(0, data.bones.size()):
            var bone = data.bones[bone_id];
            var rest_pos = data.vertices[bone.vertex_index].position
            if bone.parent_bone != 0xFFFF:
                node.set_bone_parent(bone_id, bone.parent_bone);
                var parent_rest_transform = node.get_bone_rest(bone.parent_bone);
                rest_pos += parent_rest_transform.origin;
            node.set_bone_rest(bone_id, Transform3D(Basis.IDENTITY, rest_pos));
    else:
        node = Node3D.new();
    # Build model
    var surf_tools = {};
    for mesh in data.meshes:
        for face in mesh.faces:
            var mat_name = "%d" % face.color_index;
            var st = null;
            if !surf_tools.has(mat_name):
                st = SurfaceTool.new();
                st.begin(Mesh.PRIMITIVE_TRIANGLES);
                var mat = StandardMaterial3D.new();
                mat.albedo_color = palette[face.color_index];
                mat.cull_mode = BaseMaterial3D.CULL_DISABLED;
                st.set_material(mat);
                surf_tools[mat_name] = st;
            st = surf_tools[mat_name];
            add_vertex(st, node, data.vertices, data.normals, face.vertex_index_0);
            add_vertex(st, node, data.vertices, data.normals, face.vertex_index_1);
            add_vertex(st, node, data.vertices, data.normals, face.vertex_index_2);
            # Handle quads
            if face.has("vertex_index_3"):
                add_vertex(st, node, data.vertices, data.normals, face.vertex_index_0);
                add_vertex(st, node, data.vertices, data.normals, face.vertex_index_2);
                add_vertex(st, node, data.vertices, data.normals, face.vertex_index_3);
    # Build edges
    for edge in data.edges:
        var mat_name = "%d_edge" % edge.color_index;
        var st = null;
        if !surf_tools.has(mat_name):
            st = SurfaceTool.new();
            st.begin(Mesh.PRIMITIVE_LINES);
            var mat = StandardMaterial3D.new();
            mat.albedo_color = palette[edge.color_index];
            mat.cull_mode = BaseMaterial3D.CULL_DISABLED;
            st.set_material(mat);
            surf_tools[mat_name] = st;
        st = surf_tools[mat_name];
        if edge.vertex_index_0 > data.vertices.size() || edge.vertex_index_1 > data.vertices.size():
            Utils.console.print("Error: invalid vertex index in edge", Color.RED);
            continue;
        add_vertex(st, node, data.vertices, data.normals, edge.vertex_index_0);
        add_vertex(st, node, data.vertices, data.normals, edge.vertex_index_1);
    # Build spheres
    for sphere in data.spheres:
        # Build sphere
        var base_sphere := SphereMesh.new()
        base_sphere.radial_segments = 8;
        base_sphere.rings = 8;
        base_sphere.radius = sphere.size;
        base_sphere.height = sphere.size;
        var sphere_vertex = data.vertices[sphere.vertex_index];
        # Create surface tool
        var mat_name = "%d_sphere" % sphere.color_index;
        var st = null;
        if !surf_tools.has(mat_name):
            st = SurfaceTool.new();
            st.begin(Mesh.PRIMITIVE_TRIANGLES);
            var mat = StandardMaterial3D.new();
            mat.albedo_color = palette[sphere.color_index];
            mat.cull_mode = BaseMaterial3D.CULL_DISABLED;
            st.set_material(mat);
            surf_tools[mat_name] = st;
        st = surf_tools[mat_name];
        # Convert procedural spheremesh to sftool
        var arrays = base_sphere.get_mesh_arrays();
        var positions = arrays[Mesh.ARRAY_VERTEX];
        var normals = arrays[Mesh.ARRAY_NORMAL];
        var indices = arrays[Mesh.ARRAY_INDEX]
        var base_vertices = data.vertices.size();
        for i in range(0, positions.size()):
            data.vertices.push_back({"position": sphere_vertex.position + positions[i], "bone": sphere_vertex.bone})
            data.normals.push_back(normals[i]);
        for i in range(0, indices.size() - 2, 3):
            add_vertex(st, node, data.vertices, data.normals, indices[i] + base_vertices);
            add_vertex(st, node, data.vertices, data.normals, indices[i + 1] + base_vertices);
            add_vertex(st, node, data.vertices, data.normals, indices[i + 2] + base_vertices);
    # Build mesh
    var mesh = null;
    var mesh_instance = MeshInstance3D.new();
    for mat in surf_tools.keys():
        mesh = surf_tools[mat].commit(mesh);
    mesh_instance.mesh = mesh;
    node.add_child(mesh_instance);
    return node;
        
