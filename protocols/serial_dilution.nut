// Spigot 12-Point Serial Dilution Protocol
// Pre-fills diluent buffer, transfers compound stock, mixes, performs serial 2x dilutions, and normalizes final volumes.

dofile("protocols/protocol_base.nut");
dofile("deck/plate.nut");
dofile("deck/reservoir.nut");
dofile("deck/tip_rack.nut");

class SerialDilutionProtocol extends AssayProtocol {
    dilution_factor = 2.0; // 1:2 dilution
    aliquot_volume_ul = 100.0;
    initial_stock_conc_um = 100.0;

    reservoir = null; // Reservoir12Channel
    assay_plate = null; // Plate96WellFlat
    tip_rack = null; // TipRack

    constructor() {
        base.constructor("SerialDilution", "12-Point 1:2 Serial Dilution Assay with Volume Normalization");
        _setup_deck();
    }

    function _setup_deck() {
        reservoir = Reservoir12Channel("res_1", "Diluent Buffer Reservoir");
        // Pre-fill reservoir channel 1 with 15 mL PBS
        reservoir.well_list[0].dispense(15000.0, "PBS", { nacl = 137.0 });
        deck.load_labware(1, reservoir);

        assay_plate = Plate96WellFlat("assay_plate_1", "96-Well Dilution Target Plate");
        deck.load_labware(2, assay_plate);

        tip_rack = TipRack("tip_rack_1", "200uL Tip Rack", 200.0, true);
        deck.load_labware(3, tip_rack);
    }

    // Executes the complete 12-point serial dilution workflow.
    function run() {
        // Step 1: Distribute 100 uL PBS diluent to wells A2 through A12
        local diluent_targets = [];
        for (local col = 2; col <= 12; col++) {
            diluent_targets.append(assay_plate.get_well("A" + col));
        }

        // Pick tip for diluent dispensing (can be reused since it only dispenses buffer above surface)
        pick_tip_from_rack(tip_rack, 0);
        foreach (tgt in diluent_targets) {
            transfer(reservoir.well_list[0], tgt, aliquot_volume_ul, null, null, 0, false, false);
        }
        eject_tip_to_waste(0);

        // Step 2: Add 200 uL of 100 uM compound stock to well A1
        local a1 = assay_plate.get_well("A1");
        a1.dispense(200.0, "Compound_Stock", { compound = initial_stock_conc_um });

        // Step 3: Perform serial 1:2 dilution across row A (columns 1 to 11)
        pick_tip_from_rack(tip_rack, 0);
        for (local c = 1; c <= 10; c++) {
            local src = assay_plate.get_well("A" + c);
            local tgt = assay_plate.get_well("A" + (c + 1));

            // Transfer 100 uL from src to tgt
            transfer(src, tgt, aliquot_volume_ul, null, null, 0, false, true);

            // Mix 3 times in target well
            mix(tgt, aliquot_volume_ul, 3, 0);
        }

        // Step 4: Discard 100 uL from well A11 to waste so all wells A1..A11 end with exactly 100 uL
        local a11 = assay_plate.get_well("A11");
        a11.aspirate(aliquot_volume_ul);
        eject_tip_to_waste(0);

        return true;
    }

    // Returns array of final compound concentrations across row A wells (A1 to A12).
    function get_concentration_profile() {
        local profile = [];
        for (local c = 1; c <= 12; c++) {
            local w = assay_plate.get_well("A" + c);
            local conc = w.solutes.rawin("compound") ? w.solutes["compound"] : 0.0;
            profile.append({ well = w.id, concentration_um = conc, volume_ul = w.volume_ul });
        }
        return profile;
    }
}
