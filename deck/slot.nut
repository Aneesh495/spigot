// Spigot Deck Slot Model
// Conforms to ANSI/SLAS footprint standards (127.76 mm x 85.48 mm).

dofile("core/math.nut");
dofile("core/aabb.nut");
dofile("deck/coordinate.nut");

// Standard ANSI/SLAS footprint dimensions in mm
const ANSI_SLAS_LENGTH_MM = 127.76;
const ANSI_SLAS_WIDTH_MM  = 85.48;
const DEFAULT_SLOT_CLEARANCE_MM = 120.0;

class DeckSlot {
    slot_id = 0;
    label = "";
    origin = null; // Vector3 (front-left-bottom corner in mm)
    dimensions = null; // Vector3 (length, width, max_height)
    bounds = null; // AABB
    installed_labware = null;
    is_active_accessory = false;

    constructor(id, lbl, origin_x, origin_y, origin_z = 0.0) {
        slot_id = id;
        label = lbl;
        origin = Vector3(origin_x, origin_y, origin_z);
        dimensions = Vector3(ANSI_SLAS_LENGTH_MM, ANSI_SLAS_WIDTH_MM, DEFAULT_SLOT_CLEARANCE_MM);
        bounds = AABB(origin, origin.add(dimensions));
        installed_labware = null;
        is_active_accessory = false;
    }

    function is_occupied() {
        return installed_labware != null;
    }

    function mount_labware(labware) {
        if (is_occupied()) {
            throw "SlotOccupiedException: Slot " + slot_id + " (" + label + ") is already occupied by " + installed_labware.name;
        }
        installed_labware = labware;
        labware.assign_to_slot(this);
    }

    function remove_labware() {
        if (!is_occupied()) {
            return null;
        }
        local lw = installed_labware;
        installed_labware = null;
        lw.unassign_slot();
        return lw;
    }

    function get_center_top() {
        return Vector3(
            origin.x + (dimensions.x * 0.5),
            origin.y + (dimensions.y * 0.5),
            origin.z + dimensions.z
        );
    }

    function tostring() {
        local occ = is_occupied() ? (" [Occupied: " + installed_labware.name + "]") : " [Empty]";
        return "DeckSlot " + slot_id + " ('" + label + "')" + occ + " at " + origin.tostring();
    }
}
