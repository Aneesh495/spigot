// Spigot Custom Protocol Authoring Example
// Demonstrates subclassing AssayProtocol to implement a custom biochemical binding screen.

dofile("protocols/protocol_base.nut");
dofile("deck/reservoir.nut");
dofile("deck/plate.nut");
dofile("deck/tip_rack.nut");
dofile("deck/accessories.nut");
dofile("analysis/audit_manifest.nut");
dofile("ui/deck_renderer.nut");
dofile("ui/plate_heatmap.nut");

class CustomFluorescenceBindingAssay extends AssayProtocol {
    reagent_reservoir = null;
    reaction_plate = null;
    tip_rack = null;
    thermal_shaker = null;

    constructor() {
        base.constructor("FluorescenceBindingScreen");

        // 1. Setup workstation deck configuration
        reagent_reservoir = Reservoir12Channel("res_fluor", "Fluorophore Reagents");
        reaction_plate = Plate96WellFlat("reaction_plate", "Fluorescence Assay 96");
        tip_rack = TipRack("tips_custom", "200uL Pipette Tips");
        thermal_shaker = PeltierThermalShaker("shaker_mod", "Peltier Incubation Shaker");

        deck.load_labware(1, reagent_reservoir);
        deck.load_labware(2, reaction_plate);
        deck.load_labware(3, tip_rack);
        deck.load_labware(6, thermal_shaker);

        // Pre-fill reagent reservoir channel 1 (Buffer) and channel 2 (Fluorophore probe)
        reagent_reservoir.get_well("A1").dispense(15000.0);
        reagent_reservoir.get_well("A2").dispense(10000.0);
    }

    function run_screen(row = "A") {
        ::print("\n>> Starting Custom Fluorescence Binding Screen for Row " + row + "...\n");

        // Step 1: Pick up a fresh 200uL tip
        pick_tip_from_rack(tip_rack, 0);

        // Step 2: Distribute 80 uL assay buffer to wells 1 through 6
        for (local c = 1; c <= 6; c++) {
            local dst_well = row + c;
            transfer(reagent_reservoir.get_well("A1"), reaction_plate.get_well(dst_well), 80.0, "Standard_Aqueous");
        }

        // Step 3: Add 20 uL fluorophore probe to wells 1 through 6
        for (local c = 1; c <= 6; c++) {
            local dst_well = row + c;
            transfer(reagent_reservoir.get_well("A2"), reaction_plate.get_well(dst_well), 20.0, "Standard_Aqueous");
            // Mix 3 times in-place with 50 uL stroke
            mix(reaction_plate.get_well(dst_well), 50.0, 3);
        }

        // Step 4: Drop dirty tip
        eject_tip_to_waste(0);

        // Step 5: Active accessory incubation and shaking
        thermal_shaker.set_temperature(37.0);
        thermal_shaker.start_shaking(800);
        ::print("Incubating reaction plate at 37 C and 800 RPM...\n");
        thermal_shaker.stop_shaking();

        ::print(">> Screen completed successfully!\n");
    }
}

// Instantiate and execute custom assay
local assay = CustomFluorescenceBindingAssay();
assay.run_screen("A");

// Display deck visualizer and well volume heatmap
local renderer = DeckRenderer(assay.deck, true);
renderer.print_deck();

local heatmap = PlateHeatmap(assay.reaction_plate, true);
heatmap.print_heatmap();

// Display audit manifest
local manifest = AuditManifest("CustomScreenRun");
manifest.complete(assay);
::print(manifest.generate_summary_text() + "\n");
