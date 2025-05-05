extends Control

var package_parser;
var palette_parser;
var image_parser;
var sprite_parser;
var model_parser;
var parsers_assoc;

var tree;
var tree_root;

var packages;
var current_palette;

func _ready() -> void:
    package_parser = load("res://parsers/package.gd").new();
    palette_parser = load("res://parsers/palette.gd").new();
    image_parser = load("res://parsers/image.gd").new();
    sprite_parser = load("res://parsers/sprite.gd").new();
    model_parser = load("res://parsers/model.gd").new();
    parsers_assoc = {
        ".HQR": package_parser,
        ".ILE": package_parser,
        ".OBL": package_parser,
        ".LIM": image_parser,
        ".PAL": palette_parser,
        ".SPR": sprite_parser,
        ".LFN": model_parser,
        "Unknown": null
    }
    current_palette = palette_parser.generate_random();
    # UI
    tree = get_node("Layout/MainContainer/VBoxContainer/Tree");
    tree_root = tree.create_item();
    tree.hide_root = true;
    tree.connect("item_selected", Callable(self, "tree_select"));
    get_node("Layout/MenuBar/File").connect("id_pressed", Callable(self, "file_menu"));
    get_node("OpenFileDialog").connect("file_selected", Callable(self, "load_package"));
    get_node("OpenFileDialog").connect("files_selected", Callable(self, "load_multiple"));
    #Load
    packages = [];
    #var main_package = load_package("./data/RESS.HQR");
    #var citadel = load_package("./data/CITADEL.ILE");
    #var citadelo = load_package("./data/CITADEL.OBL");

func file_menu(idx: int):
    if idx == 0:
        get_node("OpenFileDialog").visible = true;

func load_multiple(files: Array[String]):
    for file in files:
        load_package(file);

func load_package(path: String):
    var package = package_parser.parse(path);
    packages.push_back(package);
    #test
    var tree_package = tree.create_item(tree_root);
    tree_package.set_text(0, path.get_file());
    for entry_index in range(0, package.entries.size()):
        var entry = package.entries[entry_index];
        var tree_entry = tree.create_item(tree_package);
        var entry_text = "%d: " % (entry_index + 1);
        if entry == null:
            entry_text += "Blank"
            tree_entry.set_selectable(0, false);
        else:
            entry_text += "%s Entry" % entry.type
            if entry.repeats != -1:
                entry_text += "(R%d)" % (entry.repeats + 1);
            tree_entry.set_metadata(0, { "package_index": packages.size() - 1, "entry_index": entry_index });
        tree_entry.set_text(0, entry_text);
    get_node("Layout/MainContainer/VBoxContainer/Label").set_text("%d package(s) loaded" % packages.size());
    return package;
    
func populate_details(package_index: int, entry_index: int):
    var entry = packages[package_index].entries[entry_index];
    if entry == null:
        return;
    var details = get_node("Layout/MainContainer/Entry/Panel/Details");
    details.set_text(get_entry_details(package_index, entry_index));
    var parser = parsers_assoc[entry.type];
    var viewport2d = get_node("Layout/MainContainer/Entry/ColorRect/SubViewport2D");
    var viewport3d = get_node("Layout/MainContainer/Entry/ColorRect/SubViewport3D");
    var hex_viewer = get_node("Layout/MainContainer/Entry/ColorRect/HexViewer");
    if entry.type == ".LIM" || entry.type == ".SPR":
        var image = parser.parse(entry, current_palette);
        hex_viewer.visible = false;
        viewport3d.visible = false;
        viewport2d.visible = true;
        viewport2d.reset(false);
        viewport2d.set_preview(ImageTexture.create_from_image(image));
    elif entry.type == ".PAL":
        var palette = parser.parse(entry);
        var palette_img = parser.create_preview(palette);
        hex_viewer.visible = false;
        viewport3d.visible = false;
        viewport2d.visible = true;
        viewport2d.reset(true);
        viewport2d.set_preview(ImageTexture.create_from_image(palette_img));
        viewport2d.set_zoom(Vector2(15,15));
    elif entry.type == ".LFN":
        var skeletonData = parser.parse(entry);
        var skeleton = parser.build_skeleton(skeletonData);
        hex_viewer.visible = false;
        viewport2d.visible = false;
        viewport3d.visible = true;
        viewport3d.reset_camera();
    else:
        viewport3d.visible = false;
        viewport2d.visible = false;
        hex_viewer.visible = true;
        hex_viewer.set_data(entry);

func tree_select():
    var item = tree.get_selected();
    var meta = item.get_metadata(0);
    if meta:
        populate_details(meta.package_index, meta.entry_index);

func get_entry_details(package_index: int, entry_index: int):
    var entry = packages[package_index].entries[entry_index];
    var text = "Package %d: Entry %d\n" % [package_index, entry_index];
    text += "Offset: %d\n" % entry.offset;
    text += "Type: %s\n" % entry.type;
    text += "Size: %d (%d compressed)\n" % [entry.original_size / 8, entry.compressed_size / 8];
    return text;
    
func set_current_palette():
    var item = tree.get_selected();
    var meta = item.get_metadata(0);
    if meta:
        var entry = packages[meta.package_index].entries[meta.entry_index];
        current_palette = palette_parser.parse(entry);
