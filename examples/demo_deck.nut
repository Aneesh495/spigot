// Spigot Workstation Deck Configuration Example
// Demonstrates populating a 12-slot deck with diverse labware and active robotic accessories.

dofile("deck/deck_layout.nut");
dofile("deck/plate.nut");
dofile("deck/tip_rack.nut");
dofile("deck/reservoir.nut");
dofile("deck/tube_rack.nut");
dofile("deck/accessories.nut");
dofile("ui/deck_renderer.nut");

::print("=== Spigot Workstation Deck Configuration Demo ===\n");

// Initialize standard 12-slot deck (3 rows x 4 columns)
local deck = DeckLayout("Full Production Bio-Assay Deck", 3, 4);

// Mount consumables and plates
deck.load_labware(1, Reservoir12Channel("res_buffers", "12-Channel Reagents 22mL"));
deck.load_labware(2, Plate96WellFlat("assay_target", "96-Well Reaction Plate"));
deck.load_labware(3, TipRack("tips_200", "200uL Pipette Tips"));
deck.load_labware(4, Plate384Well("compound_lib", "384-Well Compound Library"));
deck.load_labware(5, TubeRack24Eppendorf("standards", "24-Tube Calibrator Standards"));

// Mount active robotic accessories
deck.load_labware(6, PeltierThermalShaker("heater_shaker", "Peltier Shaker Module"));
deck.load_labware(7, MagneticSeparationBlock("magnet_ring", "96-Ring Magnetic Bead Separator"));
deck.load_labware(8, MicroplateReaderStation("optical_reader", "450nm Absorbance Reader"));

// Render ASCII deck representation
local renderer = DeckRenderer(deck, true);
renderer.print_deck();

::print("\nDeck Configuration Summary:\n");
for (local i = 1; i <= 12; i++) {
    local slot = deck.get_slot(i);
    local status = slot.is_occupied() ? (slot.installed_labware.name + " (" + slot.installed_labware.category + ")") : "[Empty]";
    ::print("  Slot " + i + ": " + status + "\n");
}
