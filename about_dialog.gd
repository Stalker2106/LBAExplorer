extends Window

func _ready() -> void:
    connect("close_requested", Callable(self, "close"));
    var about_text = "[center][img]res://assets/icon.png[/img]\n"
    about_text += "[wave amp=20.0 freq=5.0 connected=1]LBAExplorer v%s[/wave]\n" % ProjectSettings.get_setting("application/config/version")
    about_text += "Made with Godot by Stalker2106\n\n"
    about_text += "[url=https://github.com/Stalker2106/LBAExplorer]https://github.com/Stalker2106/LBAExplorer[/url]\n\n"
    about_text += "This software widely uses the work of many projects from [url=https://github.com/LBALab]https://github.com/LBALab[/url] and the work of many people from the LBA discord community.\n"
    about_text += "Big thanks to all of them, especially members of the Magicball network, who have made the reverse engineering of the game possible.\n\n"
    about_text += "This is a fan-made tool and is not affiliated with Adeline Software or the current rights holders of Little Big Adventure. All trademarks and content belong to their respective owners.[/center]\n"
    get_node("Text").set_text(about_text);

func close():
    visible = false;
