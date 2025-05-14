extends Node

var console;

const WORLD_SCALE = 1 / 32.0;
const ANGLE_MAX = 1024;

enum EntryType {
    PALETTE,
    IMAGE,
    SPRITE,
    MODEL,
    ANIMATION,
    UNKNOWN
}

const SUPPORTED_EXTENSIONS = ["HQR", "ILE", "OBL", "VOX"];
