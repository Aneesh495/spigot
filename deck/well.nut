// Spigot Well State and Liquid Inventory Model
// Tracks dynamic liquid volumes, solute concentrations, meniscus heights, and cross-contamination history.

dofile("core/math.nut");
dofile("deck/well_geometry.nut");
dofile("core/errors.nut");

class Well {
    id = "A1";
    row = 0;
    col = 0;
    position = null; // Vector3 world coordinates of well center top (mm)
    geometry = null; // WellGeometry
    volume_ul = 0.0;
    liquid_class_name = "Water";
    solutes = null; // Table of solute concentrations (uM or mg/mL)
    contamination_history = null; // Array of reagent names that contacted this well
    color_hex = "#1E88E5";

    constructor(well_id, r, c, pos, geom, initial_vol = 0.0, lclass = "Water") {
        id = well_id;
        row = r;
        col = c;
        position = pos;
        geometry = geom;
        volume_ul = initial_vol.tofloat();
        liquid_class_name = lclass;
        solutes = {};
        contamination_history = [];
        color_hex = "#1E88E5";
    }

    // Returns whether the well contains essentially zero liquid volume.
    function is_empty() {
        return volume_ul <= 1e-4;
    }

    // Checks whether the well has at least the required volume above the dead volume threshold.
    function has_available_volume(requested_ul) {
        local avail = volume_ul - geometry.dead_volume_ul;
        return avail >= requested_ul;
    }

    // Computes the current liquid height in mm from the well bottom.
    function get_liquid_height() {
        return geometry.calculate_height_at_volume(volume_ul);
    }

    // Computes the absolute Z coordinate of the liquid meniscus surface in world frame.
    function get_meniscus_z() {
        local bottom_z = position.z - geometry.total_depth_mm;
        return bottom_z + get_liquid_height();
    }

    // Computes the absolute Z coordinate of the physical bottom of the well.
    function get_bottom_z() {
        return position.z - geometry.total_depth_mm;
    }

    // Withdraws liquid volume from the well.
    function aspirate(amount_ul) {
        local req = amount_ul.tofloat();
        if (req < 0.0) {
            throw "InvalidVolumeException: Cannot aspirate negative volume.";
        }
        local avail = volume_ul - geometry.dead_volume_ul;
        if (req > avail + 1e-5) {
            throw InsufficientVolumeError(id, req, volume_ul, geometry.dead_volume_ul);
        }
        volume_ul -= req;
        if (volume_ul < 0.0) volume_ul = 0.0;
        return req;
    }

    // Injects liquid volume into the well, mixing solutes.
    function dispense(amount_ul, incoming_lclass = null, incoming_solutes = null) {
        local add_vol = amount_ul.tofloat();
        if (add_vol < 0.0) {
            throw "InvalidVolumeException: Cannot dispense negative volume.";
        }
        local new_vol = volume_ul + add_vol;
        if (new_vol > geometry.max_volume_ul + 1e-5) {
            throw WellOverfillError(id, geometry.max_volume_ul, new_vol);
        }

        // Mix solute concentrations proportionally based on dilution formula C_new = (C1*V1 + C2*V2) / V_new
        if (incoming_solutes != null && incoming_solutes.len() > 0) {
            foreach (solute, c2 in incoming_solutes) {
                local c1 = solutes.rawin(solute) ? solutes[solute] : 0.0;
                local merged_c = ((c1 * volume_ul) + (c2 * add_vol)) / new_vol;
                solutes[solute] <- merged_c;
            }
        }

        if (incoming_lclass != null && incoming_lclass != "") {
            liquid_class_name = incoming_lclass;
        }

        volume_ul = new_vol;
        return volume_ul;
    }

    // Records a contact event from a tip to audit possible cross-contamination.
    function record_contact(reagent_or_tip_id) {
        contamination_history.append({
            reagent = reagent_or_tip_id,
            timestamp = time(),
            current_volume = volume_ul
        });
    }

    function tostring() {
        return "Well(" + id + ": " + volume_ul + "/" + geometry.max_volume_ul + " uL, h=" + get_liquid_height() + " mm, " + liquid_class_name + ")";
    }
}
