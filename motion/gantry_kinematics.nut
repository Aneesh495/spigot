// Spigot Gantry Kinematics and Multi-Axis Motion Controller
// Coordinates Cartesian XYZ execution, S-curve trajectory profiling, and TCP tracking.

dofile("core/math.nut");
dofile("motion/axis_limits.nut");
dofile("motion/s_curve.nut");
dofile("motion/multi_channel_pitch.nut");
dofile("motion/collision_envelope.nut");
dofile("motion/pipette_actuator.nut");

class GantryKinematics {
    constraints = null; // GantryConstraints
    current_head_pos = null; // Vector3 (nozzle face origin)
    pitch_actuator = null; // MultiChannelPitchActuator
    actuators = null; // Array of PipetteActuator for channels 0..7
    envelope_planner = null; // CollisionEnvelopePlanner

    cumulative_distance_mm = 0.0;
    cumulative_motion_time_s = 0.0;

    constructor(layout = null) {
        constraints = GantryConstraints();
        current_head_pos = Vector3(50.0, 50.0, 180.0); // Home position
        pitch_actuator = MultiChannelPitchActuator(8, 9.0);
        envelope_planner = (layout != null) ? CollisionEnvelopePlanner(layout) : null;

        actuators = [];
        for (local i = 0; i < 8; i++) {
            actuators.append(PipetteActuator(i));
        }

        cumulative_distance_mm = 0.0;
        cumulative_motion_time_s = 0.0;
    }

    // Computes the Tool Center Point (TCP) taking attached tip length into account.
    function get_tcp_position(channel_idx = 0) {
        local tip_len = actuators[channel_idx].get_effective_tip_length_mm();
        local channel_positions = pitch_actuator.get_channel_positions(current_head_pos);
        local ch_pos = channel_positions[channel_idx];
        return Vector3(ch_pos.x, ch_pos.y, ch_pos.z - tip_len);
    }

    // Executes a single-segment Cartesian move, validating axis limits.
    function move_linear(target_pos, speed_mm_s = 200.0) {
        constraints.x_axis.validate_position(target_pos.x);
        constraints.y_axis.validate_position(target_pos.y);
        constraints.z_axis.validate_position(target_pos.z);

        local dist = current_head_pos.distance_to(target_pos);
        if (dist > 1e-4) {
            local s_curve = SCurveProfile(dist, speed_mm_s, 2000.0, 10000.0);
            cumulative_distance_mm += dist;
            cumulative_motion_time_s += s_curve.total_duration_s;
            current_head_pos = target_pos.copy();
        }
        return current_head_pos;
    }

    // Executes a safe transit move between two points, automatically retracting to safe transit Z.
    function move_safe(target_pos, speed_mm_s = 250.0) {
        if (envelope_planner != null) {
            local waypoints = envelope_planner.plan_safe_transit(current_head_pos, target_pos);
            for (local i = 1; i < waypoints.len(); i++) {
                move_linear(waypoints[i], speed_mm_s);
            }
        } else {
            // Default 3-phase move if planner not attached
            local safe_z = 180.0;
            if (current_head_pos.z < safe_z) {
                move_linear(Vector3(current_head_pos.x, current_head_pos.y, safe_z), speed_mm_s);
            }
            move_linear(Vector3(target_pos.x, target_pos.y, safe_z), speed_mm_s);
            move_linear(target_pos, speed_mm_s);
        }
        return current_head_pos;
    }

    // Moves the TCP of a specific channel directly to target coordinates.
    function move_channel_tcp_to(channel_idx, target_tcp_pos, speed_mm_s = 200.0) {
        local tip_len = actuators[channel_idx].get_effective_tip_length_mm();
        local target_head_z = target_tcp_pos.z + tip_len;
        local y_offset = channel_idx * pitch_actuator.current_pitch_mm;
        local target_head_y = target_tcp_pos.y - y_offset;
        local target_head_pos = Vector3(target_tcp_pos.x, target_head_y, target_head_z);

        return move_safe(target_head_pos, speed_mm_s);
    }
}
