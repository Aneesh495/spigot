// Unit tests for Deck layout, Labware definitions, and Well Geometry

dofile("tests/assert.nut");
dofile("deck/deck_layout.nut");
dofile("deck/plate.nut");
dofile("deck/tip_rack.nut");
dofile("deck/reservoir.nut");
dofile("deck/tube_rack.nut");
dofile("deck/accessories.nut");

local suite = TestSuite("Deck and Labware Subsystem Test Suite");

// 1. DeckLayout tests
local deck = DeckLayout("Test 12-Slot Deck", 3, 4);
suite.assert_equal(deck.get_total_slot_count(), 12, "Deck has 12 slots");

local slot1 = deck.get_slot(1);
suite.assert_equal(slot1.slot_id, 1, "Slot 1 ID matches");
suite.assert_false(slot1.is_occupied(), "Slot 1 initially empty");

// 2. Labware mounting and coordinate transformation
local plate96 = Plate96WellFlat("assay_plate_1", "Assay Plate 96");
deck.load_labware(1, plate96);
suite.assert_true(slot1.is_occupied(), "Slot 1 occupied after loading");

local a1 = plate96.get_well("A1");
suite.assert_equal(a1.id, "A1", "Well A1 retrieved");
suite.assert_near(a1.position.x, slot1.origin.x + 14.38, 1e-4, "Well A1 X world coordinate");
suite.assert_near(a1.position.y, slot1.origin.y + 11.24 + (7 * 9.0), 1e-4, "Well A1 Y world coordinate");

// Test well indexing by integer
local w0 = plate96.get_well(0);
suite.assert_equal(w0.id, "A1", "Well index 0 is A1");

// Test row and column slicing
local row_a = plate96.get_row("A");
suite.assert_equal(row_a.len(), 12, "Row A has 12 wells");
suite.assert_equal(row_a[0].id, "A1", "Row A first well is A1");
suite.assert_equal(row_a[11].id, "A12", "Row A last well is A12");

local col_1 = plate96.get_column(0);
suite.assert_equal(col_1.len(), 8, "Col 1 has 8 wells");
suite.assert_equal(col_1[0].id, "A1", "Col 1 top well is A1");
suite.assert_equal(col_1[7].id, "H1", "Col 1 bottom well is H1");

// 3. Well geometry and volume inversion tests
local flat_geom = WellGeometry(WellShapeType.FLAT_CYLINDER, 10.0, 6.0, 0.0, 5.0);
local test_vol = flat_geom.calculate_volume_at_height(5.0);
// Cylinder: V = pi * r^2 * h = pi * 3^2 * 5 = 45 * pi ~= 141.37 uL
suite.assert_near(test_vol, 45.0 * PI, 1e-3, "Cylindrical volume at h=5mm");
local inv_h = flat_geom.calculate_height_at_volume(test_vol);
suite.assert_near(inv_h, 5.0, 1e-3, "Volume-to-height inversion matches");

// 4. Well aspiration and dispensing
a1.dispense(150.0, "PBS", { nacl = 137.0 });
suite.assert_near(a1.volume_ul, 150.0, 1e-4, "Dispensed 150 uL into A1");
suite.assert_equal(a1.liquid_class_name, "PBS", "Liquid class is PBS");
suite.assert_near(a1.solutes["nacl"], 137.0, 1e-4, "Solute NaCl concentration");

local drawn = a1.aspirate(50.0);
suite.assert_near(drawn, 50.0, 1e-4, "Aspirated 50 uL");
suite.assert_near(a1.volume_ul, 100.0, 1e-4, "Remaining volume 100 uL");

// 5. 384-Well plate
local plate384 = Plate384Well("plate_384_test");
suite.assert_equal(plate384.well_list.len(), 384, "384-well plate has 384 wells");
local p24 = plate384.get_well("P24");
suite.assert_equal(p24.id, "P24", "Well P24 retrieved from 384-well plate");

// 6. TipRack tests
local tip_rack = TipRack("tip_rack_test", "Test 200uL Tip Rack", 200.0);
deck.load_labware(2, tip_rack);
suite.assert_equal(tip_rack.get_remaining_tip_count(), 96, "Initially 96 tips present");

local next_tip = tip_rack.find_next_tip();
suite.assert_equal(next_tip.id, "A1", "Next available tip is A1");

local spec = tip_rack.pick_tip("A1");
suite.assert_near(spec.max_volume_ul, 200.0, 1e-4, "Picked tip has 200 uL spec");
suite.assert_false(tip_rack.has_tip("A1"), "Tip A1 now marked as picked");
suite.assert_equal(tip_rack.get_remaining_tip_count(), 95, "95 tips remaining");

// Test multichannel column picking
local col2_spec = tip_rack.pick_column(1); // Column 2
suite.assert_equal(tip_rack.get_remaining_tip_count(), 87, "87 tips remaining after picking 8-tip column");

// 7. Active Accessories
local shaker = PeltierThermalShaker("shaker_1");
shaker.set_temperature(37.0);
suite.assert_near(shaker.target_temperature_c, 37.0, 1e-4, "Target temperature set to 37 C");
shaker.step_thermal_simulation(2.0); // 2.5 C/s * 2s = +5.0 C => 25.0 C
suite.assert_near(shaker.current_temperature_c, 25.0, 1e-4, "Temperature simulated after 2 seconds");

local mag = MagneticSeparationBlock("mag_1");
suite.assert_false(mag.is_engaged(), "Magnet initially disengaged");
mag.engage_magnets();
suite.assert_true(mag.is_engaged(), "Magnet engaged");

local success = suite.summary();
if (!success) {
    throw "Deck and labware tests failed.";
}
