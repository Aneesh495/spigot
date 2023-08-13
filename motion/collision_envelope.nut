// Spigot Collision Envelope and Safe Transit Planner
// Computes dynamic obstacle clearance heights and non-colliding transit corridors across the deck.

dofile("core/math.nut");
dofile("core/aabb.nut");
dofile("core/errors.nut");

class CollisionEnvelopePlanner {
    deck_layout = null; // DeckLayout
    min_clearance_margin_mm = 15.0; // Margin above tallest labware
    default_safe_z_mm = 160.0;

    constructor(layout, margin_mm = 15.0) {
        deck_layout = layout;
        min_clearance_margin_mm = margin_mm.tofloat();
    }

    // Computes the minimum safe Z transit height above all installed labware on deck.
    function calculate_safe_transit_z() {
        local max_z = 0.0;
        local occupied = deck_layout.get_occupied_slots();
        foreach (slot in occupied) {
            local lw = slot.installed_labware;
            local top_z = slot.origin.z + lw.total_height_mm;
            if (top_z > max_z) {
                max_z = top_z;
            }
        }
        local safe_z = max_z + min_clearance_margin_mm;
        if (safe_z < default_safe_z_mm) {
            safe_z = default_safe_z_mm;
        }
        return safe_z;
    }

    // Generates a 3-segment safe travel path from start_pos to target_pos:
    // 1. Vertical retract to safe Z
    // 2. Horizontal XY traverse
    // 3. Vertical descent to target Z
    function plan_safe_transit(start_pos, target_pos) {
        local safe_z = calculate_safe_transit_z();
        if (start_pos.z > safe_z) safe_z = start_pos.z;
        if (target_pos.z > safe_z) safe_z = target_pos.z;

        local waypoints = [];
        // Waypoint 0: Current position
        waypoints.append(start_pos.copy());

        // Waypoint 1: Retracted at current X, Y, safe Z
        if (abs(start_pos.z - safe_z) > 1.0) {
            waypoints.append(Vector3(start_pos.x, start_pos.y, safe_z));
        }

        // Waypoint 2: Traversed to target X, Y, safe Z
        waypoints.append(Vector3(target_pos.x, target_pos.y, safe_z));

        // Waypoint 3: Descended to target position
        if (abs(target_pos.z - safe_z) > 1.0) {
            waypoints.append(target_pos.copy());
        }

        return waypoints;
    }

    // Checks whether an AABB representing the gantry head intersects any installed labware on deck.
    function check_collision(head_box) {
        local occupied = deck_layout.get_occupied_slots();
        foreach (slot in occupied) {
            local lw_bounds = slot.installed_labware.get_bounds();
            if (head_box.intersects(lw_bounds)) {
                return slot.installed_labware.name;
            }
        }
        return null;
    }
}
