// Spigot Motion Axis Limits and Kinematic Constraints
// Defines physical travel boundaries, maximum velocities, accelerations, and jerk limits.

dofile("core/errors.nut");

class AxisLimits {
    name = "X";
    min_pos_mm = 0.0;
    max_pos_mm = 650.0;
    max_velocity_mm_s = 500.0;
    max_acceleration_mm_s2 = 2500.0;
    max_jerk_mm_s3 = 10000.0;

    constructor(ax_name, min_p, max_p, max_v, max_a, max_j) {
        name = ax_name;
        min_pos_mm = min_p.tofloat();
        max_pos_mm = max_p.tofloat();
        max_velocity_mm_s = max_v.tofloat();
        max_acceleration_mm_s2 = max_a.tofloat();
        max_jerk_mm_s3 = max_j.tofloat();
    }

    function validate_position(pos_mm) {
        local p = pos_mm.tofloat();
        if (p < min_pos_mm || p > max_pos_mm) {
            throw AxisLimitError(name, p, min_pos_mm, max_pos_mm);
        }
        return p;
    }

    function is_within_limits(pos_mm) {
        local p = pos_mm.tofloat();
        return (p >= min_pos_mm && p <= max_pos_mm);
    }

    function clamp_position(pos_mm) {
        local p = pos_mm.tofloat();
        if (p < min_pos_mm) return min_pos_mm;
        if (p > max_pos_mm) return max_pos_mm;
        return p;
    }
}

class GantryConstraints {
    x_axis = null; // AxisLimits
    y_axis = null; // AxisLimits
    z_axis = null; // AxisLimits

    constructor() {
        x_axis = AxisLimits("X", 0.0, 750.0, 600.0, 3000.0, 15000.0);
        y_axis = AxisLimits("Y", 0.0, 500.0, 500.0, 2500.0, 12000.0);
        z_axis = AxisLimits("Z", 0.0, 400.0, 350.0, 2500.0, 12000.0);
    }
}
