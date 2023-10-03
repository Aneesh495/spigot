// Spigot Enzyme-Linked Immunosorbent Assay (ELISA) Protocol
// Executes antibody binding, wash cycles, substrate incubation, stop reaction, and 450nm plate reading.

dofile("protocols/protocol_base.nut");
dofile("deck/plate.nut");
dofile("deck/reservoir.nut");
dofile("deck/tip_rack.nut");
dofile("deck/accessories.nut");

class ELISAAssayProtocol extends AssayProtocol {
    wash_volume_ul = 200.0;
    sample_volume_ul = 100.0;
    substrate_volume_ul = 100.0;
    stop_solution_volume_ul = 50.0;

    reservoir = null; // Reservoir12Channel: Ch1=WashBuffer, Ch2=TMB, Ch3=StopSolution
    elisa_plate = null; // Plate96WellFlat
    tip_rack = null; // TipRack
    shaker = null; // PeltierThermalShaker
    reader = null; // MicroplateReaderStation

    constructor() {
        base.constructor("ELISA_Assay", "Sandwich ELISA with Automated Wash and 450nm Spectrophotometric Detection");
        _setup_deck();
    }

    function _setup_deck() {
        reservoir = Reservoir12Channel("res_elisa", "ELISA Reagent Reservoir");
        // Channel 1: Wash buffer (PBST 0.05% Tween) 20 mL
        reservoir.well_list[0].dispense(20000.0, "PBST_Wash");
        // Channel 2: TMB Substrate 15 mL
        reservoir.well_list[1].dispense(15000.0, "TMB_Substrate", { substrate = 1.0 });
        // Channel 3: 2M H2SO4 Stop Solution 10 mL
        reservoir.well_list[2].dispense(10000.0, "StopSolution_H2SO4");
        deck.load_labware(1, reservoir);

        elisa_plate = Plate96WellFlat("elisa_plate_1", "ELISA Microplate 96-Well");
        // Pre-fill row A with sample dilutions
        local stock_conc = 10.0; // ng/mL
        for (local c = 1; c <= 8; c++) {
            local w = elisa_plate.get_well("A" + c);
            w.dispense(100.0, "Serum_Sample", { target_antigen = stock_conc });
            stock_conc *= 0.5; // 2-fold serial standards
        }
        deck.load_labware(2, elisa_plate);

        tip_rack = TipRack("tip_rack_elisa", "200uL Tip Rack", 200.0, true);
        deck.load_labware(3, tip_rack);

        shaker = PeltierThermalShaker("shaker_elisa");
        deck.load_labware(4, shaker);

        reader = MicroplateReaderStation("reader_elisa");
        deck.load_labware(5, reader);
    }

    // Performs an automated wash cycle across target wells.
    function execute_wash_cycle(wells_array) {
        pick_tip_from_rack(tip_rack, 0);
        // 1. Aspirate sample contents to waste
        foreach (w in wells_array) {
            if (w.volume_ul > 0.0) {
                local vol = w.empty();
                gantry.actuators[0].aspirate_stroke(vol);
                eject_tip_to_waste(0);
                pick_tip_from_rack(tip_rack, 0);
            }
        }

        // 2. Dispense 200 uL wash buffer into each well
        local wash_buffer_channel = reservoir.well_list[0];
        foreach (w in wells_array) {
            transfer(wash_buffer_channel, w, wash_volume_ul, null, null, 0, false, false);
        }

        // 3. Aspirate wash buffer back out to waste
        foreach (w in wells_array) {
            local vol = w.empty();
            gantry.actuators[0].aspirate_stroke(vol);
            // Evacuate wash buffer to waste
            gantry.actuators[0].dispense_stroke(vol, true);
        }
        eject_tip_to_waste(0);
    }

    // Runs complete ELISA development sequence: Wash -> TMB -> Incubation -> Stop -> Read
    function run() {
        local test_wells = [];
        for (local c = 1; c <= 8; c++) {
            test_wells.append(elisa_plate.get_well("A" + c));
        }

        // 1. Wash out unbound antigen/antibodies
        execute_wash_cycle(test_wells);

        // 2. Add 100 uL TMB substrate to each well
        pick_tip_from_rack(tip_rack, 0);
        local tmb_channel = reservoir.well_list[1];
        foreach (w in test_wells) {
            transfer(tmb_channel, w, substrate_volume_ul, null, null, 0, false, false);
        }
        eject_tip_to_waste(0);

        // 3. Simulated 15-minute chromogenic color development at 25 C
        shaker.set_temperature(25.0);
        shaker.step_thermal_simulation(900.0); // 15 mins

        // Invert antigen concentration to product signal: Product = Antigen * k * t
        for (local c = 1; c <= 8; c++) {
            local w = elisa_plate.get_well("A" + c);
            local ag_conc = 10.0 * pow(0.5, c - 1);
            w.solutes["substrate_product"] <- ag_conc * 0.15;
        }

        // 4. Add 50 uL Stop solution to freeze enzymatic reaction
        pick_tip_from_rack(tip_rack, 0);
        local stop_channel = reservoir.well_list[2];
        foreach (w in test_wells) {
            transfer(stop_channel, w, stop_solution_volume_ul, null, null, 0, false, false);
        }
        eject_tip_to_waste(0);

        // 5. Read absorbance at 450 nm on reader station
        reader.set_wavelength(450);
        local read_results = reader.read_absorbance_matrix(elisa_plate);

        return read_results;
    }
}
