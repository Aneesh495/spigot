// Spigot Labware Definition Base Class
// Defines ANSI/SLAS compliant physical footprints, well indexing, and coordinate transformations.

dofile("core/math.nut");
dofile("core/aabb.nut");
dofile("deck/well.nut");

class Labware {
    id = "";
    name = "";
    category = "PLATE"; // PLATE, TIP_RACK, RESERVOIR, TUBE_RACK, ACCESSORY
    footprint_length_mm = 127.76;
    footprint_width_mm = 85.48;
    total_height_mm = 14.35; // Standard microplate height
    slot = null; // Assigned DeckSlot

    rows = 0;
    cols = 0;
    well_pitch_x_mm = 9.0;
    well_pitch_y_mm = 9.0;
    first_well_offset_x_mm = 14.38;
    first_well_offset_y_mm = 11.24;

    wells = null; // Table: "A1" -> Well
    well_list = null; // Array of Well in row-major order
    default_geometry = null; // WellGeometry

    constructor(lw_id, lw_name, cat, r, c, pitch_x, pitch_y, off_x, off_y, height_mm, geom) {
        id = lw_id;
        name = lw_name;
        category = cat;
        rows = r;
        cols = c;
        well_pitch_x_mm = pitch_x.tofloat();
        well_pitch_y_mm = pitch_y.tofloat();
        first_well_offset_x_mm = off_x.tofloat();
        first_well_offset_y_mm = off_y.tofloat();
        total_height_mm = height_mm.tofloat();
        default_geometry = geom;

        wells = {};
        well_list = [];
        slot = null;

        _generate_wells();
    }

    function _row_name(r) {
        local letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        if (r < 26) {
            return letters.slice(r, r + 1);
        } else {
            local first = (r / 26) - 1;
            local second = r % 26;
            return letters.slice(first, first + 1) + letters.slice(second, second + 1);
        }
    }

    function _generate_wells() {
        for (local r = 0; r < rows; r++) {
            local row_letter = _row_name(r);
            for (local c = 0; c < cols; c++) {
                local col_num = c + 1;
                local well_id = row_letter + col_num;

                // Position relative to labware origin (front-left bottom)
                local rel_x = first_well_offset_x_mm + (c * well_pitch_x_mm);
                local rel_y = first_well_offset_y_mm + ((rows - 1 - r) * well_pitch_y_mm);
                local rel_z = total_height_mm;
                local pos = Vector3(rel_x, rel_y, rel_z);

                local w = Well(well_id, r, c, pos, default_geometry);
                wells[well_id] <- w;
                well_list.append(w);
            }
        }
    }

    function assign_to_slot(deck_slot) {
        slot = deck_slot;
        _recalculate_world_positions();
    }

    function unassign_slot() {
        slot = null;
        _recalculate_world_positions();
    }

    function _recalculate_world_positions() {
        local slot_origin = (slot != null) ? slot.origin : Vector3(0.0, 0.0, 0.0);
        local letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        for (local r = 0; r < rows; r++) {
            local row_letter = letters.slice(r, r + 1);
            for (local c = 0; c < cols; c++) {
                local well_id = row_letter + (c + 1);
                local rel_x = first_well_offset_x_mm + (c * well_pitch_x_mm);
                local rel_y = first_well_offset_y_mm + ((rows - 1 - r) * well_pitch_y_mm);
                local rel_z = total_height_mm;

                local world_pos = Vector3(
                    slot_origin.x + rel_x,
                    slot_origin.y + rel_y,
                    slot_origin.z + rel_z
                );
                if (wells.rawin(well_id)) {
                    wells[well_id].position = world_pos;
                }
            }
        }
    }

    function get_well(identifier) {
        local t = typeof identifier;
        if (t == "string") {
            if (!wells.rawin(identifier)) {
                throw "NoSuchWellException: Well '" + identifier + "' does not exist in labware '" + name + "'";
            }
            return wells[identifier];
        } else if (t == "integer") {
            if (identifier < 0 || identifier >= well_list.len()) {
                throw "IndexOutOfBoundsException: Well index " + identifier + " out of bounds [0, " + (well_list.len() - 1) + "]";
            }
            return well_list[identifier];
        }
        throw "InvalidArgumentException: Well identifier must be a string (e.g. 'A1') or integer index.";
    }

    function get_row(row_idx) {
        local r = row_idx;
        if (typeof row_idx == "string") {
            local letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
            r = letters.find(row_idx);
            if (r == null) throw "InvalidRowException: Row string must be single letter A-Z";
        }
        local row_wells = [];
        for (local c = 0; c < cols; c++) {
            local idx = (r * cols) + c;
            row_wells.append(well_list[idx]);
        }
        return row_wells;
    }

    function get_column(col_idx) {
        local c = col_idx; // 0-based
        if (c < 0 || c >= cols) {
            throw "InvalidColumnException: Column index " + col_idx + " out of bounds";
        }
        local col_wells = [];
        for (local r = 0; r < rows; r++) {
            local idx = (r * cols) + c;
            col_wells.append(well_list[idx]);
        }
        return col_wells;
    }

    function get_total_volume_ul() {
        local tot = 0.0;
        foreach (w in well_list) {
            tot += w.volume_ul;
        }
        return tot;
    }

    function get_bounds() {
        local slot_origin = (slot != null) ? slot.origin : Vector3(0.0, 0.0, 0.0);
        return AABB(slot_origin, slot_origin.add(Vector3(footprint_length_mm, footprint_width_mm, total_height_mm)));
    }
}
