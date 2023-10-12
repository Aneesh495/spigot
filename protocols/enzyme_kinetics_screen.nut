// Spigot Michaelis-Menten Enzyme Kinetics Screening Protocol
// Titrates chromogenic substrate, initiates enzymatic reaction, and samples time-course absorbance.

dofile("protocols/protocol_base.nut");
dofile("deck/plate.nut");
dofile("deck/reservoir.nut");
dofile("deck/tip_rack.nut");
dofile("deck/accessories.nut");

class EnzymeKineticsScreenProtocol extends AssayProtocol {
    reservoir = null; // Ch1: Enzyme stock, Ch2: Substrate stock (1000 uM), Ch3: Buffer
    assay_plate = null;
    tip_rack = null;
    reader = null;

    constructor() {
        base.constructor("EnzymeKinetics", "Michaelis-Menten Enzyme Kinetics and Km/Vmax Assay");
        _setup_deck();
    }

    function _setup_deck() {
        reservoir = Reservoir12Channel("res_enzymes", "Enzyme Kinetics Reagents");
        // Ch1: Beta-galactosidase enzyme stock 5 mL
        reservoir.well_list[0].dispense(5000.0, "Enzyme_Stock", { enzyme_activity_u_ml = 2.0 });
        // Ch2: ONPG Substrate stock (1000 uM) 10 mL
        reservoir.well_list[1].dispense(10000.0, "Substrate_ONPG", { substrate_um = 1000.0 });
        // Ch3: Assay Buffer (pH 7.4) 15 mL
        reservoir.well_list[2].dispense(15000.0, "Assay_Buffer");
        deck.load_labware(1, reservoir);

        assay_plate = Plate96WellFlat("kinetics_plate_1", "Enzyme Kinetics Flat-Bottom Plate");
        deck.load_labware(2, assay_plate);

        tip_rack = TipRack("tip_rack_kinetics", "200uL Tip Rack", 200.0, true);
        deck.load_labware(3, tip_rack);

        reader = MicroplateReaderStation("reader_kinetics");
        reader.set_wavelength(405); // 405 nm for o-nitrophenol product
        deck.load_labware(4, reader);
    }

    // Runs substrate titration across row A (8 concentrations from 0 to 800 uM).
    function run_screen() {
        local substrate_volumes = [0.0, 10.0, 20.0, 40.0, 80.0, 120.0, 160.0, 200.0];
        local buffer_channel = reservoir.well_list[2];
        local substrate_channel = reservoir.well_list[1];
        local enzyme_channel = reservoir.well_list[0];

        // 1. Dispense buffer volume to bring wells to 200 uL total before enzyme
        pick_tip_from_rack(tip_rack, 0);
        for (local i = 0; i < 8; i++) {
            local target_well = assay_plate.get_well("A" + (i + 1));
            local buffer_vol = 200.0 - substrate_volumes[i];
            if (buffer_vol > 0.0) {
                transfer(buffer_channel, target_well, buffer_vol, null, null, 0, false, false);
            }
        }
        eject_tip_to_waste(0);

        // 2. Dispense substrate titration
        pick_tip_from_rack(tip_rack, 0);
        for (local i = 0; i < 8; i++) {
            local target_well = assay_plate.get_well("A" + (i + 1));
            local sub_vol = substrate_volumes[i];
            if (sub_vol > 0.0) {
                transfer(substrate_channel, target_well, sub_vol, null, null, 0, false, false);
                // Substrate concentration in uM: C = (sub_vol * 1000 uM) / 200 uL
                local actual_um = (sub_vol * 1000.0) / 200.0;
                target_well.solutes["substrate_um"] <- actual_um;
            } else {
                target_well.solutes["substrate_um"] <- 0.0;
            }
        }
        eject_tip_to_waste(0);

        // 3. Initiate reaction simultaneously by adding 20 uL enzyme to all wells
        pick_tip_from_rack(tip_rack, 0);
        for (local i = 0; i < 8; i++) {
            local target_well = assay_plate.get_well("A" + (i + 1));
            transfer(enzyme_channel, target_well, 20.0, null, null, 0, false, true);

            // Michaelis-Menten rate equation: V0 = (Vmax * [S]) / (Km + [S])
            // Constants: Vmax = 0.05 DeltaA/min, Km = 120 uM
            local s_conc = target_well.solutes["substrate_um"];
            local v0 = (0.05 * s_conc) / (120.0 + s_conc);
            target_well.solutes["reaction_velocity_v0"] <- v0;
            target_well.solutes["substrate_product"] <- v0 * 10.0; // After 10 mins reaction
        }
        eject_tip_to_waste(0);

        // 4. Measure optical density at 405 nm
        local abs_results = reader.read_absorbance_matrix(assay_plate);
        return abs_results;
    }
}
