// Spigot Core Mathematical Library
// Provides 3D vector primitives, spatial projections, and geometric interpolation.

class Vector3 {
    x = 0.0;
    y = 0.0;
    z = 0.0;

    constructor(x_ = 0.0, y_ = 0.0, z_ = 0.0) {
        x = x_.tofloat();
        y = y_.tofloat();
        z = z_.tofloat();
    }

    // Returns a new vector representing the sum of this vector and another.
    function add(other) {
        return Vector3(x + other.x, y + other.y, z + other.z);
    }

    // Returns a new vector representing the difference of this vector and another.
    function sub(other) {
        return Vector3(x - other.x, y - other.y, z - other.z);
    }

    // Multiplies the vector by a scalar factor.
    function scale(factor) {
        local s = factor.tofloat();
        return Vector3(x * s, y * s, z * s);
    }

    // Divides the vector by a scalar factor.
    function divide(factor) {
        local s = factor.tofloat();
        if (s == 0.0) {
            throw "DivisionByZeroException: Cannot divide Vector3 by zero.";
        }
        return Vector3(x / s, y / s, z / s);
    }

    // Computes the Euclidean norm (length) of the vector.
    function length() {
        return sqrt(x * x + y * y + z * z);
    }

    // Computes squared length to avoid expensive square root in threshold comparisons.
    function length_squared() {
        return x * x + y * y + z * z;
    }

    // Computes Euclidean distance to another point.
    function distance_to(other) {
        local dx = x - other.x;
        local dy = y - other.y;
        local dz = z - other.z;
        return sqrt(dx * dx + dy * dy + dz * dz);
    }

    // Computes squared distance to another point.
    function distance_squared_to(other) {
        local dx = x - other.x;
        local dy = y - other.y;
        local dz = z - other.z;
        return dx * dx + dy * dy + dz * dz;
    }

    // Returns a normalized unit vector.
    function normalize() {
        local len = length();
        if (len < 1e-9) {
            return Vector3(0.0, 0.0, 0.0);
        }
        return Vector3(x / len, y / len, z / len);
    }

    // Computes the dot product with another vector.
    function dot(other) {
        return (x * other.x) + (y * other.y) + (z * other.z);
    }

    // Computes the 3D cross product with another vector.
    function cross(other) {
        return Vector3(
            (y * other.z) - (z * other.y),
            (z * other.x) - (x * other.z),
            (x * other.y) - (y * other.x)
        );
    }

    // Linear interpolation between this vector and a target vector.
    function lerp(target, t) {
        local factor = t.tofloat();
        if (factor < 0.0) factor = 0.0;
        if (factor > 1.0) factor = 1.0;
        return Vector3(
            x + (target.x - x) * factor,
            y + (target.y - y) * factor,
            z + (target.z - z) * factor
        );
    }

    // Equality check with tolerance for floating point imprecision.
    function equals(other, epsilon = 1e-6) {
        local dx = abs(x - other.x);
        local dy = abs(y - other.y);
        local dz = abs(z - other.z);
        return (dx <= epsilon) && (dy <= epsilon) && (dz <= epsilon);
    }

    // Duplicates the current vector.
    function copy() {
        return Vector3(x, y, z);
    }

    // Returns human-readable string representation.
    function tostring() {
        return "Vector3(" + x + ", " + y + ", " + z + ")";
    }
}

// Global helper functions for common numerical routines.
function math_clamp(val, min_val, max_val) {
    if (val < min_val) return min_val;
    if (val > max_val) return max_val;
    return val;
}

function math_lerp(a, b, t) {
    return a + (b - a) * t;
}

function math_smoothstep(edge0, edge1, x) {
    local t = math_clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
    return t * t * (3.0 - 2.0 * t);
}
