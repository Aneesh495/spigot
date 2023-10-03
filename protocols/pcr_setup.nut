// Spigot 96-Well Quantitative PCR (qPCR) Setup Protocol
// Distributes master mix, adds primers and cDNA templates, and prepares No-Template Control (NTC) wells.

dofile("protocols/protocol_base.nut");
dofile("deck/plate.nut");
dofile("deck/reservoir.nut");
dofile("deck/tube_rack.nut");
dofile("deck/tip_rack.nut");

class PCRSetupProtocol extends AssayProtocol {
    master_mix_vol_ul = 15.0;
    primer_vol_ul = 2.0;
    template_vol_ul = 5.0;

    reservoir = null;
    tube_rack = null;
    pcr_plate = null;
    tip_rack = null;

    constructor() {
        base.constructor("PCRSetup", "96-Well qPCR Reaction Setup with NTC Controls");
        _setup_deck();
    }

    function _setup_deck() {
        reservoir = Reservoir12Channel("res_mm", "Master Mix Reservoir");
        // Pre-fill channel 1 with 2.5 mL 2x qPCR Master Mix
        reservoir.well_list[0].dispense(2500.0, "PCR_MasterMix", { taq = 1.0, dntp = 0.4 });
        deck.load_labware(1, reservoir);

        tube_rack = TubeRack24Eppendorf("tubes_templates", "Template and Primer Tubes");
        // Tube A1: Primer mix (10 uM)
        tube_rack.get_well("A1").dispense(500.0, "Primers", { primer_fw = 10.0, primer_rev = 10.0 });
        // Tube B1: DNA Sample 1 (50 ng/uL)
        tube_rack.get_well("B1").dispense(200.0, "DNA_Sample_1", { dna_ng_ul = 50.0 });
        // Tube C1: Nuclease-free water for NTC
        tube_rack.get_well("C1").dispense(1000.0, "NucleaseFreeWater");
        deck.load_labware(2, tube_rack);

        pcr_plate = Plate96WellVBottom("pcr_plate_1", "96-Well V-Bottom PCR Plate");
        deck.load_labware(3, pcr_plate);

        tip_rack = TipRack("tip_rack_pcr", "200uL Tip Rack", 200.0, true);
        deck.load_labware(4, tip_rack);
    }

    // Runs qPCR setup across specified row (e.g. Row A).
    function run_row(row_letter = "A") {
        local target_wells = pcr_plate.get_row(row_letter);

        // 1. Distribute 15 uL master mix across all 12 wells
        pick_tip_from_rack(tip_rack, 0);
        foreach (w in target_wells) {
            transfer(reservoir.well_list[0], w, master_mix_vol_ul, null, null, 0, false, false);
        }
        eject_tip_to_waste(0);

        // 2. Add 2 uL primers to all 12 wells
        local primer_tube = tube_rack.get_well("A1");
        pick_tip_from_rack(tip_rack, 0);
        foreach (w in target_wells) {
            transfer(primer_tube, w, primer_vol_ul, null, null, 0, false, false);
        }
        eject_tip_to_waste(0);

        // 3. Add 5 uL DNA template to sample wells (Columns 1 to 10)
        local dna_tube = tube_rack.get_well("B1");
        for (local c = 0; c < 10; c++) {
            pick_tip_from_rack(tip_rack, 0);
            transfer(dna_tube, target_wells[c], template_vol_ul, null, null, 0, false, true);
            mix(target_wells[c], 10.0, 2, 0);
            eject_tip_to_waste(0);
        }

        // 4. Add 5 uL nuclease-free water to NTC wells (Columns 11 and 12)
        local water_tube = tube_rack.get_well("C1");
        pick_tip_from_rack(tip_rack, 0);
        transfer(water_tube, target_wells[10], template_vol_ul, null, null, 0, false, true);
        transfer(water_tube, target_wells[11], template_vol_ul, null, null, 0, false, true);
        eject_tip_to_waste(0);

        return true;
    }
}
