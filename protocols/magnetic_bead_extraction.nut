// Spigot Magnetic Bead SPRI Nucleic Acid Extraction Protocol
// Models paramagnetic bead binding, magnetic pull-down, ethanol wash cycles, and elution.

dofile("protocols/protocol_base.nut");
dofile("deck/plate.nut");
dofile("deck/reservoir.nut");
dofile("deck/tip_rack.nut");
dofile("deck/accessories.nut");

class MagneticBeadExtractionProtocol extends AssayProtocol {
    sample_vol_ul = 50.0;
    bead_vol_ul = 50.0;
    ethanol_wash_vol_ul = 150.0;
    elution_vol_ul = 30.0;

    reservoir = null; // Ch1: SPRI Beads, Ch2: 80% EtOH, Ch3: TE Elution Buffer
    process_plate = null;
    elution_plate = null;
    tip_rack = null;
    mag_block = null;

    constructor() {
        base.constructor("MagneticBeadExtraction", "SPRI Paramagnetic Bead DNA/RNA Extraction and Purification");
        _setup_deck();
    }

    function _setup_deck() {
        reservoir = Reservoir12Channel("res_beads", "Reagents Reservoir");
        // Ch1: SPRI Magnetic Beads 10 mL
        reservoir.well_list[0].dispense(10000.0, "SPRI_Beads", { bead_conc_mg_ml = 10.0 });
        // Ch2: 80% Ethanol 20 mL
        reservoir.well_list[1].dispense(20000.0, "Ethanol_80");
        // Ch3: TE Elution Buffer 10 mL
        reservoir.well_list[2].dispense(10000.0, "TE_Buffer");
        deck.load_labware(1, reservoir);

        process_plate = Plate96WellVBottom("process_plate_1", "Sample Processing V-Bottom Plate");
        // Pre-fill well A1 with lysed DNA sample
        process_plate.get_well("A1").dispense(sample_vol_ul, "Lysed_Sample", { genomic_dna_ng = 500.0 });
        deck.load_labware(2, process_plate);

        elution_plate = Plate96WellVBottom("elution_plate_1", "Purified Elution Plate");
        deck.load_labware(3, elution_plate);

        tip_rack = TipRack("tip_rack_beads", "200uL Tip Rack", 200.0, true);
        deck.load_labware(4, tip_rack);

        mag_block = MagneticSeparationBlock("mag_block_1");
        deck.load_labware(5, mag_block);
    }

    // Runs magnetic bead purification on target well (e.g. A1).
    function run_well(well_id = "A1") {
        local proc_well = process_plate.get_well(well_id);
        local elut_well = elution_plate.get_well(well_id);

        // 1. Add 50 uL SPRI magnetic beads
        pick_tip_from_rack(tip_rack, 0);
        transfer(reservoir.well_list[0], proc_well, bead_vol_ul, null, null, 0, false, false);
        // Mix 5x to ensure homogeneous bead-DNA binding
        mix(proc_well, 40.0, 5, 0);
        eject_tip_to_waste(0);

        // 2. Engage magnetic separation block to pellet beads to well wall
        mag_block.engage_magnets();

        // 3. Aspirate supernatant to liquid waste
        pick_tip_from_rack(tip_rack, 0);
        local sup_vol = proc_well.volume_ul - 5.0; // Leave 5 uL to avoid disturbing pellet
        proc_well.aspirate(sup_vol);
        gantry.actuators[0].aspirate_stroke(sup_vol);
        eject_tip_to_waste(0);

        // 4. Wash 1: 150 uL 80% Ethanol
        pick_tip_from_rack(tip_rack, 0);
        transfer(reservoir.well_list[1], proc_well, ethanol_wash_vol_ul, null, null, 0, false, false);
        // Aspirate ethanol wash out to waste
        local wash1_vol = proc_well.volume_ul - 5.0;
        proc_well.aspirate(wash1_vol);
        gantry.actuators[0].aspirate_stroke(wash1_vol);
        eject_tip_to_waste(0);

        // 5. Wash 2: 150 uL 80% Ethanol
        pick_tip_from_rack(tip_rack, 0);
        transfer(reservoir.well_list[1], proc_well, ethanol_wash_vol_ul, null, null, 0, false, false);
        local wash2_vol = proc_well.empty();
        gantry.actuators[0].aspirate_stroke(wash2_vol);
        eject_tip_to_waste(0);

        // 6. Disengage magnets for elution
        mag_block.disengage_magnets();

        // 7. Dispense 30 uL TE elution buffer and mix to resuspend pellet
        pick_tip_from_rack(tip_rack, 0);
        transfer(reservoir.well_list[2], proc_well, elution_vol_ul, null, null, 0, false, false);
        mix(proc_well, 20.0, 6, 0);
        eject_tip_to_waste(0);

        // 8. Re-engage magnets to separate clean eluate from bead pellet
        mag_block.engage_magnets();

        // 9. Transfer purified eluate to clean elution plate
        pick_tip_from_rack(tip_rack, 0);
        local pure_vol = 25.0; // Transfer 25 uL pure DNA
        transfer(proc_well, elut_well, pure_vol, null, null, 0, false, true);
        eject_tip_to_waste(0);

        elut_well.solutes["purified_dna_ng"] <- 420.0; // ~84% recovery yield
        return true;
    }
}
