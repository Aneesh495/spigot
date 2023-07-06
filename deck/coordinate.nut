// Spigot Deck Coordinates and Coordinate Frames
// Models deck origins, slot relative offsets, and spatial frame transformations.

dofile("core/math.nut");

class DeckCoordinate {
    base_pos = null; // Vector3 in robot world frame (mm)
    frame_name = "WORLD";

    constructor(x_ = 0.0, y_ = 0.0, z_ = 0.0, name = "WORLD") {
        base_pos = Vector3(x_, y_, z_);
        frame_name = name;
    }

    // Translates coordinate by delta vector.
    function offset(dx, dy, dz) {
        return DeckCoordinate(
            base_pos.x + dx,
            base_pos.y + dy,
            base_pos.z + dz,
            frame_name
        );
    }

    // Returns the Euclidean distance to another coordinate.
    function distance_to(other) {
        return base_pos.distance_to(other.base_pos);
    }

    function tostring() {
        return "[" + frame_name + ": " + base_pos.x + ", " + base_pos.y + ", " + base_pos.z + " mm]";
    }
}
