extends Control

var package_parser;
var palette_parser;
var image_parser;
var sprite_parser;
var model_parser;
var parsers_assoc;

var tree;
var console;

var packages;
var current_palette;
var animations;

func _ready() -> void:
    package_parser = load("res://parsers/package.gd").new();
    palette_parser = load("res://parsers/palette.gd").new();
    image_parser = load("res://parsers/image.gd").new();
    sprite_parser = load("res://parsers/sprite.gd").new();
    model_parser = load("res://parsers/model2.gd").new();
    current_palette = palette_parser.generate_grayscale();
    var palette_img = palette_parser.create_preview(current_palette);
    get_node("Layout/MainContainer/Entry/Bottom/Palette/Image").texture = ImageTexture.create_from_image(palette_img);
    packages = [];
    animations = [];
    console = get_node("Layout/MainContainer/Entry/Bottom/Console");
    # UI
    tree = get_node("Layout/MainContainer/TreeContainer/Tree");
    tree.connect("item_selected", Callable(self, "tree_select"));
    var collapse_button = get_node("Layout/MainContainer/TreeContainer/Toolbar/CollapseButton");
    collapse_button.connect("pressed", Callable(tree, "collapse"));
    var open_file_button = get_node("Layout/MainContainer/TreeContainer/Toolbar/OpenFileButton");
    open_file_button.connect("pressed", Callable(self, "file_menu").bind(0));
    get_node("Layout/MenuBar/File").connect("id_pressed", Callable(self, "file_menu"));
    get_node("Layout/MenuBar/About").connect("id_pressed", Callable(self, "about_menu"));
    get_node("OpenFileDialog").connect("file_selected", Callable(self, "load_package").bind(false));
    get_node("OpenFileDialog").connect("files_selected", Callable(self, "load_multiple"));
    # Debug
    console.print("LBAExplorer v%s" % ProjectSettings.get_setting("application/config/version"), Color.GRAY, true);
    if OS.has_feature("editor"):
        load_multiple([
            "E:\\SteamLibrary\\steamapps\\common\\Little Big Adventure 2\\Common\\RESS.HQR",
            "E:\\SteamLibrary\\steamapps\\common\\Little Big Adventure 2\\Common\\BODY.HQR",
            "E:\\SteamLibrary\\steamapps\\common\\Little Big Adventure 2\\Common\\ANIM.HQR",
            "E:\\SteamLibrary\\steamapps\\common\\Little Big Adventure 2\\Common\\SPRITES.HQR",
            "E:\\SteamLibrary\\steamapps\\common\\Little Big Adventure 2\\Common\\SPRIRAW.HQR"
            ]);

func file_menu(idx: int):
    if idx == 0:
        get_node("OpenFileDialog").visible = true;

func about_menu(idx: int):
    if idx == 0:
        get_node("AboutDialog").visible = true;

func load_multiple(files: Array[String]):
    for file in files:
        load_package(file, true);

func load_package(path: String, lazy: bool):
    if !Utils.SUPPORTED_EXTENSIONS.has(path.get_extension()):
        console.print("Error: '%s' Unsupported file format" % path, Color.RED);
        return null;
    for pkg in packages:
        if pkg.path == path:
            console.print("'%s' already in workspace, skipping..." % path, Color.BLUE);
            return null;
    var package_index = packages.size();
    var package = package_parser.parse(path, package_index, lazy);
    if package == null:
        console.print("Error: parsing '%s'" % path, Color.RED);
        return null;
    packages.push_back(package);
    if !lazy:
        var metadata = get_lbalab_metadata(package.path.get_file(), package.entries_count);
        if metadata:
            package["metadata"] = metadata;
    tree.set_package(package_index, package, lazy);
    get_node("Layout/MainContainer/TreeContainer/Footer").set_text("%d package(s) loaded" % packages.size());
    
func populate_details(package_index: int, entry_index: int):
    var details = get_node("Layout/MainContainer/Entry/Bottom/Details/Text");
    if entry_index != -1:
        var entry = packages[package_index].entries[entry_index];
        if entry == null:
            return;
        details.set_text(get_entry_details(package_index, entry_index));
    else:
        details.set_text("Package");

func populate_viewer(package_index: int, entry_index: int):
    var entry = packages[package_index].entries[entry_index];
    if entry == null:
        return;
    var viewport2d = get_node("Layout/MainContainer/Entry/ViewerContainer/2D");
    viewport2d.visible = false;
    var viewport3d = get_node("Layout/MainContainer/Entry/ViewerContainer/3D");
    viewport3d.visible = false;
    var hex = get_node("Layout/MainContainer/Entry/ViewerContainer/Hex");
    hex.visible = false;
    if entry.type == Utils.EntryType.IMAGE:
        var image = image_parser.parse(entry, current_palette);
        viewport2d.visible = true;
        viewport2d.reset(false);
        viewport2d.set_preview(ImageTexture.create_from_image(image));
    elif entry.type == Utils.EntryType.SPRITE:
        var image = sprite_parser.parse_raw(entry, current_palette);
        if !image:
            image = sprite_parser.parse(entry, current_palette);
        viewport2d.visible = true;
        viewport2d.reset(false);
        viewport2d.set_preview(ImageTexture.create_from_image(image));
    elif entry.type == Utils.EntryType.PALETTE:
        var palette = palette_parser.parse(entry);
        var palette_img = palette_parser.create_preview(palette);
        viewport2d.visible = true;
        viewport2d.reset(true);
        viewport2d.set_preview(ImageTexture.create_from_image(palette_img));
        viewport2d.set_zoom(Vector2(15,15));
    elif entry.type == Utils.EntryType.MODEL:
        var model_data = model_parser.parse(entry);
        var model = model_parser.build_model(model_data, current_palette);
        viewport3d.visible = true;
        viewport3d.reset();
        viewport3d.set_preview(model);
    else:
        hex.visible = true;
        hex.reset();
        hex.set_data(entry);

func tree_select():
    var item = tree.get_selected();
    var meta = item.get_metadata(0);
    if meta:
        var pkg = packages[meta.package_index];
        # Perform load for lazy loaded entries
        if !pkg.loaded:
            var metadata = get_lbalab_metadata(pkg.path.get_file(), pkg.entries_count);
            if metadata:
                pkg["metadata"] = metadata;
            packages[meta.package_index] = pkg;
            pkg = package_parser.parse_entries(meta.package_index, pkg);
            tree.call_deferred("set_package", meta.package_index, packages[meta.package_index], false);
        # Fill data
        if meta.entry_index != -1:
            populate_details(meta.package_index, meta.entry_index);
            populate_viewer(meta.package_index, meta.entry_index);

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
        var palette_img = palette_parser.create_preview(current_palette);
        get_node("Layout/MainContainer/Entry/Bottom/Palette/Image").texture = ImageTexture.create_from_image(palette_img);

func get_lbalab_metadata(package_file: String, package_entries_count: int):
    for lba_version in range(1, 3):
        var metadata_path = "res://metadata/LBA%d/HQR/%s.json" % [lba_version, package_file];
        if FileAccess.file_exists(metadata_path):
            var file = FileAccess.open(metadata_path, FileAccess.READ);
            var metadata = JSON.parse_string(file.get_as_text());
            if metadata.entries.size() == package_entries_count:
                return metadata;
    return null;
