// Spigot Boundary Conditions and Edge Case Test Suite
// Verifies engine behavior at physical and algorithmic limits.

dofile("tests/assert.nut");
dofile("core/math.nut");
dofile("deck/well.nut");
dofile("deck/well_geometry.nut");
dofile("deck/plate.nut");
dofile("deck/deck_layout.nut");
dofile("fluidics/liquid_classes.nut");
dofile("fluidics/poiseuille_model.nut");
dofile("motion/multi_channel_pitch.nut");
dofile("motion/collision_envelope.nut");
dofile("motion/pipette_actuator.nut");

local suite = TestSuite("Boundary Conditions and Edge Case Suite");

// 1. Zero volume operations
local plate = Plate96WellFlat("edge_plate");
local well = plate.get_well("A1");
well.dispense(0.0);
suite.assert_near(well.volume_ul, 0.0, 1e-6, "Dispensing 0.0 uL succeeds without error");

well.dispense(50.0);
local asp_zero = well.aspirate(0.0);
suite.assert_near(asp_zero, 0.0, 1e-6, "Aspirating 0.0 uL succeeds without modifying volume");
suite.assert_near(well.volume_ul, 50.0, 1e-6, "Volume remains unchanged after zero aspirate");

// 2. Overfill protection
local threw_overfill = false;
try {
    well.dispense(1000.0); // Flat 96 well max volume is ~360 uL
} catch (err) {
    threw_overfill = true;
}
suite.assert_true(threw_overfill, "Dispensing beyond maximum well capacity throws OverfillError");

// 3. Complete drain on already empty well
well.empty();
local second_drain = well.empty();
suite.assert_near(second_drain, 0.0, 1e-6, "Emptying an already empty well safely returns 0.0 uL");

// 4. Extremely high viscosity fluidics (Glycerol 80%)
local visc_class = ViscousGlycerol80Class();
suite.assert_true(visc_class.properties.dynamic_viscosity_pa_s > 0.05, "Glycerol 80% dynamic viscosity > 0.05 Pa.s");
local press_drop = PoiseuilleModel.calculate_pressure_drop_mbar(10.0, visc_class.properties.dynamic_viscosity_pa_s, 50.0, 4.0, 0.5);
suite.assert_true(press_drop > 0.0, "High viscosity generates positive flow pressure drop");

// 5. 1536-well plate micro-volume boundary
local plate1536 = Plate1536Well("edge_1536");
local micro_well = plate1536.get_well("A1");
micro_well.dispense(0.5); // 500 nL
suite.assert_near(micro_well.volume_ul, 0.5, 1e-6, "1536-well accepts 500 nL dispense");
local micro_height = micro_well.geometry.calculate_height_at_volume(micro_well.volume_ul);
suite.assert_true(micro_height > 0.0, "Micro-volume liquid height is positive");
suite.assert_true(micro_height < micro_well.geometry.total_depth_mm, "Micro-volume liquid height within well bounds");

// 6. Multichannel pitch actuator extremes
local pitch = MultiChannelPitchActuator(8, 9.0);
pitch.set_pitch(4.5); // Minimum 384-well pitch
suite.assert_near(pitch.current_pitch_mm, 4.5, 1e-5, "Pitch set to minimum 4.5 mm");
suite.assert_near(pitch.get_total_span_mm(), 31.5, 1e-5, "8-channel total span at 4.5 mm pitch is 31.5 mm");

pitch.set_pitch(18.0); // Maximum 24-tube rack pitch
suite.assert_near(pitch.current_pitch_mm, 18.0, 1e-5, "Pitch set to maximum 18.0 mm");

local threw_pitch_low = false;
try {
    pitch.set_pitch(2.0); // Below 4.5 mm limit
} catch (err) {
    threw_pitch_low = true;
}
suite.assert_true(threw_pitch_low, "Pitch below minimum throws limit error");

local threw_pitch_high = false;
try {
    pitch.set_pitch(30.0); // Above 18.0 mm limit
} catch (err) {
    threw_pitch_high = true;
}
suite.assert_true(threw_pitch_high, "Pitch above maximum throws limit error");

// 7. Collision safe transit Z with populated deck
local deck = DeckLayout("Edge Deck");
local planner = CollisionEnvelopePlanner(deck, 15.0);
local safe_z = planner.calculate_safe_transit_z();
suite.assert_true(safe_z >= 160.0, "Safe transit Z clears baseline safety height");
suite.assert_true(safe_z <= 400.0, "Safe transit Z within gantry limits");

local summary_ok = suite.summary();
if (!summary_ok) {
    throw "Boundary edge cases failed.";
}
