extends Node

const SCALE = 1 / 32.0;

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
            "vert_index": sdata.get_u16()
        }
        sdata.get_u16() # dummy
        sdata.get_u16() # dummy
        bones.push_back(bone);
    # Parse vertices
    var vertices: Array[Dictionary] = [];
    sdata.seek(vertices_offset);
    for i in range(0, vertices_count):
        var vert = {
            "position": Vector3(sdata.get_16(), sdata.get_16(), sdata.get_16()),
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
            "size": sdata.get_u8(),
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

func build_skeleton(data: Dictionary):
    var skeleton = Skeleton3D.new();
    # Add all bones
    for bone_index in range(0, data.bones.size()):
        skeleton.add_bone("Bone%d" % bone_index);
    # Configure bones
    for bone_index in range(0, data.bones.size()):
        skeleton.set_bone_parent(bone_index, data.bones[bone_index].parent_bone);
        skeleton.set_bone_pose_position(bone_index, data.bones[bone_index].vert);
    return skeleton;

func build_model(data: Dictionary, palette: Array[Color]) -> Node3D:
    var node = null;
    if data.bones.size() > 0:
        node = Skeleton3D.new();
    else:
        node = Node3D.new();
    node.scale = Vector3(SCALE, SCALE, SCALE);
    # Build model
    var poly_surf_tools = {};
    for mesh in data.meshes:
        for face in mesh.faces:
            var mat_name = "%d" % face.color_index;
            var st = null;
            if !poly_surf_tools.has(mat_name):
                st = SurfaceTool.new();
                st.begin(Mesh.PRIMITIVE_TRIANGLES);
                var mat = StandardMaterial3D.new();
                mat.albedo_color = palette[face.color_index];
                mat.cull_mode = BaseMaterial3D.CULL_DISABLED;
                st.set_material(mat);
                poly_surf_tools[mat_name] = st;
            st = poly_surf_tools[mat_name];
            if face.vertex_index_0 > data.vertices.size() || face.vertex_index_1 > data.vertices.size() \
                || face.vertex_index_2 > data.vertices.size():
                Utils.console.print("Error: invalid vertex index in face", Color.RED);
                continue;
            st.add_vertex(data.vertices[face.vertex_index_0].position);
            st.add_vertex(data.vertices[face.vertex_index_1].position);
            st.add_vertex(data.vertices[face.vertex_index_2].position);
            # Handle quads
            if face.has("vertex_index_3"):
                if face.vertex_index_3 > data.vertices.size():
                    Utils.console.print("Error: invalid vertex index in face", Color.RED);
                    continue;
                st.add_vertex(data.vertices[face.vertex_index_0].position);
                st.add_vertex(data.vertices[face.vertex_index_2].position);
                st.add_vertex(data.vertices[face.vertex_index_3].position);
    for mat in poly_surf_tools.keys():
        var poly_mesh_instance = MeshInstance3D.new();
        poly_mesh_instance.mesh = poly_surf_tools[mat].commit();
        node.add_child(poly_mesh_instance);
    # Build edges
    var edge_surf_tools = {};
    for edge in data.edges:
        var mat_name = "%d" % edge.color_index;
        var st = null;
        if !edge_surf_tools.has(mat_name):
            st = SurfaceTool.new();
            st.begin(Mesh.PRIMITIVE_LINES);
            var mat = StandardMaterial3D.new();
            mat.albedo_color = palette[edge.color_index];
            mat.cull_mode = BaseMaterial3D.CULL_DISABLED;
            st.set_material(mat);
            edge_surf_tools[mat_name] = st;
        st = edge_surf_tools[mat_name];
        if edge.vertex_index_0 > data.vertices.size() || edge.vertex_index_1 > data.vertices.size():
            Utils.console.print("Error: invalid vertex index in edge", Color.RED);
            continue;
        st.add_vertex(data.vertices[edge.vertex_index_0].position);
        st.add_vertex(data.vertices[edge.vertex_index_1].position);
    for mat in edge_surf_tools.keys():
        var edge_mesh_instance = MeshInstance3D.new();
        edge_mesh_instance.mesh = edge_surf_tools[mat].commit();
        node.add_child(edge_mesh_instance);
    # Build spheres
    for sphere in data.spheres:
        var mesh_instance = MeshInstance3D.new();
        if sphere.vertex_index > data.vertices.size():
            Utils.console.print("Error: invalid vertex index for sphere", Color.RED);
            continue;
        mesh_instance.position = data.vertices[sphere.vertex_index].position;
        var sphere_mesh = SphereMesh.new();
        sphere_mesh.radial_segments = 8;
        sphere_mesh.rings = 8;
        sphere_mesh.radius = sphere.size / 2;
        sphere_mesh.height = sphere.size;
        mesh_instance.mesh = sphere_mesh;
        var mat = StandardMaterial3D.new();
        mat.albedo_color = palette[sphere.color_index];
        mat.cull_mode = BaseMaterial3D.CULL_DISABLED;
        sphere_mesh.set_material(mat);
        node.add_child(mesh_instance);
    return node;
        
