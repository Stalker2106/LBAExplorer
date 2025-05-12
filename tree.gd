extends Tree

const Icons = {
    Utils.EntryType.UNKNOWN: preload("res://assets/unknown.png"),
    Utils.EntryType.IMAGE: preload("res://assets/image.png"),
    Utils.EntryType.SPRITE: preload("res://assets/image.png"),
    Utils.EntryType.MODEL: preload("res://assets/model.png"),
    Utils.EntryType.ANIMATION: preload("res://assets/anim.png"),
    Utils.EntryType.PALETTE: preload("res://assets/palette2.png")
}

var tree_root;
var tree_packages;

func _ready() -> void:
    tree_packages = [];
    set_column_custom_minimum_width(0, 55);
    set_column_expand(0, false);
    tree_root = create_item();

func set_package(package_index: int, package: Dictionary, collapsed: bool):
    var tree_package = null;
    if package_index >= tree_packages.size():
        tree_package = create_item(tree_root);
        tree_packages.push_back(tree_package);
    else:
        tree_package = tree_packages[package_index];
    tree_package.set_text(1, package.path.get_file());
    tree_package.set_metadata(0, { "package_index": package_index, "entry_index": -1 });
    for entry_index in range(0, package.entries.size()):
        var entry = package.entries[entry_index];
        var tree_entry = create_item(tree_package);
        tree_entry.set_text(0, "%d" % (entry_index + 1));
        if entry == null:
            tree_entry.set_text(1, "Blank");
            tree_entry.set_selectable(0, false);
        else:
            var entry_text = "";
            if package.has("metadata"):
                var entry_metadata = package.metadata.entries[entry_index];
                entry_text = entry_metadata.description if entry_metadata else "Entry";
            else:
                entry_text = "Entry";
            if entry.repeats != -1:
                entry_text += "(R%d)" % (entry.repeats + 1);
            tree_entry.set_icon(1, Icons[entry.type]);
            tree_entry.set_metadata(0, { "package_index": package_index, "entry_index": entry_index });
            tree_entry.set_text(1, entry_text);
    tree_package.set_collapsed(collapsed);

func collapse():
    for pkg in tree_root.get_children():
     pkg.set_collapsed(true);
