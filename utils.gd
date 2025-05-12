extends Node

var console;

enum EntryType {
    PALETTE,
    IMAGE,
    SPRITE,
    MODEL,
    ANIMATION,
    UNKNOWN
}

const SUPPORTED_EXTENSIONS = ["HQR", "ILE", "OBL", "VOX"];
