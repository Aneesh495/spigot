// Spigot Core Axis-Aligned Bounding Box (AABB) Library
// Used for spatial partitioning, deck collision avoidance, and labware footprint verification.

class AABB {
    min = null; // Vector3
    max = null; // Vector3

    constructor(min_pt, max_pt) {
        min = Vector3(
            (min_pt.x < max_pt.x) ? min_pt.x : max_pt.x,
            (min_pt.y < max_pt.y) ? min_pt.y : max_pt.y,
            (min_pt.z < max_pt.z) ? min_pt.z : max_pt.z
        );
        max = Vector3(
            (min_pt.x > max_pt.x) ? min_pt.x : max_pt.x,
            (min_pt.y > max_pt.y) ? min_pt.y : max_pt.y,
            (min_pt.z > max_pt.z) ? min_pt.z : max_pt.z
        );
    }

    // Returns width along the X axis.
    function width() {
        return max.x - min.x;
    }

    // Returns depth along the Y axis.
    function depth() {
        return max.y - min.y;
    }

    // Returns height along the Z axis.
    function height() {
        return max.z - min.z;
    }

    // Returns center point of the box.
    function center() {
        return Vector3(
            (min.x + max.x) * 0.5,
            (min.y + max.y) * 0.5,
            (min.z + max.z) * 0.5
        );
    }

    // Returns total volume in cubic millimeters.
    function volume() {
        return width() * depth() * height();
    }

    // Tests whether a 3D point lies inside the bounding box.
    function contains_point(pt, margin = 0.0) {
        return (pt.x >= min.x - margin && pt.x <= max.x + margin &&
                pt.y >= min.y - margin && pt.y <= max.y + margin &&
                pt.z >= min.z - margin && pt.z <= max.z + margin);
    }

    // Tests whether this AABB intersects with another AABB.
    function intersects(other, margin = 0.0) {
        if (max.x + margin < other.min.x || min.x - margin > other.max.x) return false;
        if (max.y + margin < other.min.y || min.y - margin > other.max.y) return false;
        if (max.z + margin < other.min.z || min.z - margin > other.max.z) return false;
        return true;
    }

    // Computes the intersection AABB of two overlapping boxes.
    function intersection(other) {
        if (!intersects(other)) {
            return null;
        }
        local new_min = Vector3(
            (min.x > other.min.x) ? min.x : other.min.x,
            (min.y > other.min.y) ? min.y : other.min.y,
            (min.z > other.min.z) ? min.z : other.min.z
        );
        local new_max = Vector3(
            (max.x < other.max.x) ? max.x : other.max.x,
            (max.y < other.max.y) ? max.y : other.max.y,
            (max.z < other.max.z) ? max.z : other.max.z
        );
        return AABB(new_min, new_max);
    }

    // Computes the bounding box that encompasses both this box and another.
    function union_box(other) {
        local new_min = Vector3(
            (min.x < other.min.x) ? min.x : other.min.x,
            (min.y < other.min.y) ? min.y : other.min.y,
            (min.z < other.min.z) ? min.z : other.min.z
        );
        local new_max = Vector3(
            (max.x > other.max.x) ? max.x : other.max.x,
            (max.y > other.max.y) ? max.y : other.max.y,
            (max.z > other.max.z) ? max.z : other.max.z
        );
        return AABB(new_min, new_max);
    }

    // Expands the bounding box uniformly by a padding amount.
    function expand(padding) {
        local p = padding.tofloat();
        return AABB(
            Vector3(min.x - p, min.y - p, min.z - p),
            Vector3(max.x + p, max.y + p, max.z + p)
        );
    }

    // Translates the bounding box by an offset vector.
    function translate(offset) {
        return AABB(min.add(offset), max.add(offset));
    }

    // Returns string representation.
    function tostring() {
        return "AABB(" + min.tostring() + " -> " + max.tostring() + ")";
    }
}
