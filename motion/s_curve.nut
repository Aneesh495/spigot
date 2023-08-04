// Spigot S-Curve Jerk-Limited Trajectory Profile Generator
// Produces smooth C2 continuous trajectories to prevent liquid splashing and meniscus vibration.

dofile("core/math.nut");

class SCurveProfile {
    distance_mm = 0.0;
    max_v = 100.0;
    max_a = 500.0;
    max_j = 2500.0;

    // Phase timings (symmetric 7-phase S-curve)
    t_j = 0.0; // Jerk ramp duration (s)
    t_a = 0.0; // Constant acceleration duration (s)
    t_v = 0.0; // Constant cruise velocity duration (s)
    t_accel = 0.0; // Total acceleration phase duration = 2*t_j + t_a
    total_duration_s = 0.0;

    actual_v = 0.0;
    actual_a = 0.0;

    constructor(dist_mm, v_max, a_max, j_max) {
        distance_mm = abs(dist_mm.tofloat());
        max_v = v_max.tofloat();
        max_a = a_max.tofloat();
        max_j = j_max.tofloat();

        _compute_profile();
    }

    function _compute_profile() {
        if (distance_mm < 1e-6) {
            total_duration_s = 0.0;
            return;
        }

        // Time to reach max acceleration: t_j = a_max / j_max
        t_j = max_a / max_j;

        // Velocity reached during jerk ramp up and ramp down: v_j = j_max * t_j^2 = a_max * t_j
        local v_j = max_a * t_j;

        if (max_v > v_j) {
            // Can accelerate beyond jerk ramps
            t_a = (max_v - v_j) / max_a;
            actual_a = max_a;
            actual_v = max_v;
        } else {
            // Short move: cannot reach full a_max
            t_a = 0.0;
            t_j = sqrt(max_v / max_j);
            actual_a = max_j * t_j;
            actual_v = max_v;
        }

        t_accel = (2.0 * t_j) + t_a;

        // Distance covered during acceleration phase:
        // s_accel = actual_v * t_accel * 0.5
        local s_accel = actual_v * t_accel;

        if (distance_mm >= s_accel) {
            // Cruise phase exists
            t_v = (distance_mm - s_accel) / actual_v;
        } else {
            // Triangle / short move profile without cruise phase
            t_v = 0.0;
            // Scale down velocity to match distance: s = v * t_accel
            local scale = sqrt(distance_mm / s_accel);
            actual_v *= scale;
            actual_a *= scale;
            t_j *= scale;
            t_a *= scale;
            t_accel = (2.0 * t_j) + t_a;
        }

        total_duration_s = (2.0 * t_accel) + t_v;
    }

    // Evaluates normalized position [0.0, distance_mm] at time t in seconds.
    function evaluate_position(t) {
        if (t <= 0.0) return 0.0;
        if (t >= total_duration_s) return distance_mm;

        // Acceleration phase
        if (t <= t_accel) {
            if (t <= t_j) {
                // Phase 1: Jerk ramp up: s = (1/6) * j * t^3
                return (1.0 / 6.0) * max_j * t * t * t;
            } else if (t <= t_j + t_a) {
                // Phase 2: Constant acceleration
                local dt = t - t_j;
                local s1 = (1.0 / 6.0) * max_j * t_j * t_j * t_j;
                local v1 = 0.5 * max_j * t_j * t_j;
                return s1 + (v1 * dt) + (0.5 * actual_a * dt * dt);
            } else {
                // Phase 3: Jerk ramp down
                local dt = t - (t_j + t_a);
                local s2 = evaluate_position(t_j + t_a);
                local v2 = actual_v - (0.5 * max_j * (t_j - dt) * (t_j - dt));
                return s2 + (actual_v * dt) - ((1.0 / 6.0) * max_j * dt * dt * dt);
            }
        }
        // Cruise phase
        else if (t <= t_accel + t_v) {
            local dt = t - t_accel;
            local s_acc = actual_v * t_accel * 0.5;
            return s_acc + (actual_v * dt);
        }
        // Deceleration phase (symmetric reflection)
        else {
            local t_rem = total_duration_s - t;
            local s_from_end = evaluate_position(t_rem);
            return distance_mm - s_from_end;
        }
    }

    // Evaluates current velocity in mm/s at time t.
    function evaluate_velocity(t) {
        if (t <= 0.0 || t >= total_duration_s) return 0.0;
        if (t <= t_accel) {
            local frac = t / t_accel;
            return actual_v * math_smoothstep(0.0, 1.0, frac);
        } else if (t <= t_accel + t_v) {
            return actual_v;
        } else {
            local t_dec = total_duration_s - t;
            local frac = t_dec / t_accel;
            return actual_v * math_smoothstep(0.0, 1.0, frac);
        }
    }
}
