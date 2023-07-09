// Spigot Disposable Tip Rack Model
// Manages tip inventory, multichannel column pickups, tip geometry, and orifice calibrations.

dofile("deck/labware_definition.nut");

class TipSpecification {
    max_volume_ul = 200.0;
    length_mm = 51.2;
    orifice_diameter_mm = 0.5;
    barrel_diameter_mm = 4.0;
    has_aerosol_filter = true;
    immersion_retention_ul = 0.15; // Fluid retained on outer tip surface

    constructor(vol = 200.0, len = 51.2, orif_diam = 0.5, filter = true) {
        max_volume_ul = vol.tofloat();
        length_mm = len.tofloat();
        orifice_diameter_mm = orif_diam.tofloat();
        barrel_diameter_mm = (vol > 300.0) ? 7.0 : 4.0;
        has_aerosol_filter = filter;
        immersion_retention_ul = (vol > 300.0) ? 0.4 : 0.15;
    }
}

class TipRack extends Labware {
    tip_spec = null;
    tip_presence = null; // Table: "A1" -> bool (true if tip present, false if picked)

    constructor(id = "tip_rack_200", name = "96-Tip Rack 200uL", tip_volume = 200.0, filter = true) {
        local geom = WellGeometry(WellShapeType.FLAT_CYLINDER, 51.2, 5.0, 0.0, 0.0);
        base.constructor(id, name, "TIP_RACK", 8, 12, 9.0, 9.0, 14.38, 11.24, 55.0, geom);

        tip_spec = TipSpecification(tip_volume, 51.2, 0.5, filter);
        tip_presence = {};
        foreach (w in well_list) {
            tip_presence[w.id] <- true;
        }
    }

    // Checks if tip is currently present at specified well position.
    function has_tip(identifier) {
        local w = get_well(identifier);
        return tip_presence.rawin(w.id) && tip_presence[w.id];
    }

    // Picks a single tip from specified position.
    function pick_tip(identifier) {
        local w = get_well(identifier);
        if (!has_tip(w.id)) {
            throw "TipUnavailableException: No tip available at " + w.id + " in rack '" + name + "'";
        }
        tip_presence[w.id] = false;
        return tip_spec;
    }

    // Finds the next available single tip in column-major order (standard automated pipetting pattern).
    function find_next_tip() {
        for (local c = 0; c < cols; c++) {
            for (local r = 0; r < rows; r++) {
                local idx = (r * cols) + c;
                local w = well_list[idx];
                if (has_tip(w.id)) {
                    return w;
                }
            }
        }
        return null;
    }

    // Picks an entire 8-tip column simultaneously for multichannel pipetting head.
    function pick_column(col_idx) {
        local column_wells = get_column(col_idx);
        foreach (w in column_wells) {
            if (!has_tip(w.id)) {
                throw "TipColumnIncompleteException: Column " + (col_idx + 1) + " does not have all 8 tips available.";
            }
        }
        foreach (w in column_wells) {
            tip_presence[w.id] = false;
        }
        return tip_spec;
    }

    // Returns total count of remaining unused tips.
    function get_remaining_tip_count() {
        local count = 0;
        foreach (k, present in tip_presence) {
            if (present) count++;
        }
        return count;
    }
}
