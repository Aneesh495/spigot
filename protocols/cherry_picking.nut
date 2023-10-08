// Spigot Automated Compound Cherry-Picking and Hit Transfer Protocol
// Parses hit picklists, performs individual transfers with fresh tips, and normalizes concentrations.

dofile("protocols/protocol_base.nut");
dofile("deck/plate.nut");
dofile("deck/tip_rack.nut");

class CherryPickingProtocol extends AssayProtocol {
    source_plate = null; // Plate96WellFlat
    dest_plate = null; // Plate96WellFlat
    tip_rack = null; // TipRack
    picklist = null; // Array of { src = "A1", tgt = "B3", volume = 25.0 }

    constructor() {
        base.constructor("CherryPicking", "Compound Library Cherry-Picking and Normalization");
        picklist = [];
        _setup_deck();
    }

    function _setup_deck() {
        source_plate = Plate96WellFlat("source_library", "Compound Library Source Plate");
        // Seed some compound stock in source plate
        source_plate.get_well("A1").dispense(100.0, "Compound_101", { compound = 50.0 });
        source_plate.get_well("B4").dispense(100.0, "Compound_204", { compound = 80.0 });
        source_plate.get_well("D7").dispense(100.0, "Compound_307", { compound = 120.0 });
        source_plate.get_well("H12").dispense(100.0, "Compound_412", { compound = 45.0 });
        deck.load_labware(1, source_plate);

        dest_plate = Plate96WellFlat("dest_assay", "Cherry-Picked Target Plate");
        deck.load_labware(2, dest_plate);

        tip_rack = TipRack("tip_rack_cherry", "200uL Tip Rack", 200.0, true);
        deck.load_labware(3, tip_rack);
    }

    function add_transfer(src_well_id, tgt_well_id, vol_ul) {
        picklist.append({
            src = src_well_id,
            tgt = tgt_well_id,
            volume = vol_ul.tofloat()
        });
    }

    // Executes all transfers in picklist using fresh tips for each hit to prevent cross-contamination.
    function run() {
        if (picklist.len() == 0) {
            // Default sample transfers if none explicitly loaded
            add_transfer("A1", "A1", 20.0);
            add_transfer("B4", "A2", 15.0);
            add_transfer("D7", "A3", 30.0);
            add_transfer("H12", "A4", 25.0);
        }

        foreach (item in picklist) {
            local src = source_plate.get_well(item.src);
            local tgt = dest_plate.get_well(item.tgt);

            // Always pick new tip for each unique compound
            pick_tip_from_rack(tip_rack, 0);
            transfer(src, tgt, item.volume, null, null, 0, false, true);
            eject_tip_to_waste(0);
        }

        return transfers_executed;
    }
}
