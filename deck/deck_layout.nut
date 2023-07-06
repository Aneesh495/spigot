// Spigot Deck Layout Subsystem
// Manages the multi-slot grid, physical boundaries, and labware registry on the workstation.

dofile("deck/slot.nut");
dofile("core/errors.nut");

class DeckLayout {
    name = "Standard 12-Slot Deck";
    slots = null; // Table: slot_id -> DeckSlot
    grid_rows = 3;
    grid_cols = 4;
    waste_chute_pos = null; // Vector3
    wash_station_pos = null; // Vector3
    total_bounds = null; // AABB

    constructor(layout_name = "Standard 12-Slot Deck", rows = 3, cols = 4) {
        name = layout_name;
        grid_rows = rows;
        grid_cols = cols;
        slots = {};
        _build_default_grid();
    }

    function _build_default_grid() {
        // Standard spacing between slots: 142.0 mm X pitch, 102.0 mm Y pitch
        local pitch_x = 142.0;
        local pitch_y = 102.0;
        local margin_x = 20.0;
        local margin_y = 20.0;

        local id = 1;
        for (local r = 0; r < grid_rows; r++) {
            for (local c = 0; c < grid_cols; c++) {
                local ox = margin_x + (c * pitch_x);
                local oy = margin_y + (r * pitch_y);
                local label = "Slot_" + id + " (R" + (r + 1) + "C" + (c + 1) + ")";
                slots[id] <- DeckSlot(id, label, ox, oy, 0.0);
                id++;
            }
        }

        // Dedicated waste chute located at the far right corner
        waste_chute_pos = Vector3(margin_x + (grid_cols * pitch_x) + 15.0, margin_y, 0.0);
        // Dedicated tip wash station
        wash_station_pos = Vector3(margin_x + (grid_cols * pitch_x) + 15.0, margin_y + pitch_y, 0.0);

        local max_x = margin_x + (grid_cols * pitch_x) + 100.0;
        local max_y = margin_y + (grid_rows * pitch_y) + 40.0;
        total_bounds = AABB(Vector3(0.0, 0.0, 0.0), Vector3(max_x, max_y, 250.0));
    }

    function get_slot(slot_id) {
        if (!slots.rawin(slot_id)) {
            throw InvalidSlotError(slot_id, "Slot " + slot_id + " does not exist in deck layout '" + name + "'");
        }
        return slots[slot_id];
    }

    function has_slot(slot_id) {
        return slots.rawin(slot_id);
    }

    function load_labware(slot_id, labware) {
        local slot = get_slot(slot_id);
        slot.mount_labware(labware);
    }

    function unload_labware(slot_id) {
        local slot = get_slot(slot_id);
        return slot.remove_labware();
    }

    function find_labware_by_id(labware_id) {
        foreach (id, slot in slots) {
            if (slot.is_occupied() && slot.installed_labware.id == labware_id) {
                return slot.installed_labware;
            }
        }
        return null;
    }

    function find_slot_for_labware(labware_id) {
        foreach (id, slot in slots) {
            if (slot.is_occupied() && slot.installed_labware.id == labware_id) {
                return slot;
            }
        }
        return null;
    }

    function get_occupied_slots() {
        local occupied = [];
        foreach (id, slot in slots) {
            if (slot.is_occupied()) {
                occupied.append(slot);
            }
        }
        return occupied;
    }

    function get_total_slot_count() {
        return slots.len();
    }
}
