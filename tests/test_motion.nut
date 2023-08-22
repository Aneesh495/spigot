// Unit tests for Robotic Motion, Kinematics, S-Curves, and Collision Envelopes

dofile("tests/assert.nut");
dofile("motion/axis_limits.nut");
dofile("motion/s_curve.nut");
dofile("motion/multi_channel_pitch.nut");
dofile("motion/collision_envelope.nut");
dofile("motion/pipette_actuator.nut");
dofile("motion/gantry_kinematics.nut");
dofile("deck/deck_layout.nut");
dofile("deck/plate.nut");
dofile("deck/tip_rack.nut");

local suite = TestSuite("Robotic Motion and Kinematics Test Suite");

// 1. AxisLimits tests
local x_axis = AxisLimits("X", 0.0, 500.0, 400.0, 2000.0, 10000.0);
suite.assert_near(x_axis.validate_position(250.0), 250.0, 1e-4, "Valid position accepted");

local caught_limit = false;
try {
    x_axis.validate_position(550.0);
} catch (e) {
    caught_limit = true;
    suite.assert_true(e instanceof AxisLimitError, "AxisLimitError thrown on overflow");
}
suite.assert_true(caught_limit, "Position limit violation caught");

// 2. S-Curve profile generator
local s_curve = SCurveProfile(100.0, 200.0, 1000.0, 5000.0);
suite.assert_true(s_curve.total_duration_s > 0.0, "S-Curve total duration is positive");
suite.assert_near(s_curve.evaluate_position(0.0), 0.0, 1e-4, "Position at t=0 is 0");
suite.assert_near(s_curve.evaluate_position(s_curve.total_duration_s), 100.0, 1e-3, "Position at end is 100 mm");

local mid_t = s_curve.total_duration_s * 0.5;
local mid_pos = s_curve.evaluate_position(mid_t);
suite.assert_near(mid_pos, 50.0, 2.0, "Position at midpoint is approximately 50 mm (symmetric)");

// 3. Multichannel pitch actuator
local pitch = MultiChannelPitchActuator(8, 9.0);
suite.assert_near(pitch.get_total_span_mm(), 63.0, 1e-4, "8-channel 9mm pitch total span is 63 mm");

local ch_pos = pitch.get_channel_positions(Vector3(100.0, 50.0, 20.0));
suite.assert_equal(ch_pos.len(), 8, "8 channel positions computed");
suite.assert_near(ch_pos[0].y, 50.0, 1e-4, "Channel 0 Y position");
suite.assert_near(ch_pos[7].y, 50.0 + 63.0, 1e-4, "Channel 7 Y position");

// Change to 384-well pitch (4.5 mm)
pitch.set_pitch(4.5);
suite.assert_near(pitch.get_total_span_mm(), 31.5, 1e-4, "8-channel 4.5mm pitch total span is 31.5 mm");

// 4. Collision envelope and safe transit planner
local deck = DeckLayout("Test Deck");
local plate = Plate96WellFlat("plate1");
deck.load_labware(1, plate);
local tip_rack = TipRack("tips1");
deck.load_labware(2, tip_rack);

local planner = CollisionEnvelopePlanner(deck, 20.0);
local safe_z = planner.calculate_safe_transit_z();
// tip_rack height is 55 mm + margin 20 mm = 75 mm, but default_safe_z is 160 mm
suite.assert_true(safe_z >= 160.0, "Safe transit Z is at least default safe height (160 mm)");

local waypoints = planner.plan_safe_transit(Vector3(50.0, 50.0, 30.0), Vector3(200.0, 150.0, 25.0));
suite.assert_true(waypoints.len() >= 3, "Waypoints generate retracted corridor");
suite.assert_near(waypoints[1].z, safe_z, 1e-4, "Waypoint 1 retracts to safe Z");
suite.assert_near(waypoints[2].z, safe_z, 1e-4, "Waypoint 2 traverses at safe Z");

// 5. Pipette plunger actuator
local act = PipetteActuator(0, 20.0);
suite.assert_false(act.has_tip, "Actuator initially has no tip");

local caught_no_tip = false;
try {
    act.aspirate_stroke(50.0);
} catch (e) {
    caught_no_tip = true;
    suite.assert_true(e instanceof TipMissingError, "TipMissingError thrown on dry stroke");
}
suite.assert_true(caught_no_tip, "Cannot aspirate without tip mounted");

local tip_spec = TipSpecification(200.0, 51.2, 0.5, true);
act.mount_tip(tip_spec);
suite.assert_true(act.has_tip, "Tip mounted successfully");
suite.assert_near(act.get_effective_tip_length_mm(), 51.2, 1e-4, "Effective tip length 51.2 mm");

act.aspirate_stroke(100.0);
suite.assert_near(act.current_liquid_volume_ul, 100.0, 1e-4, "Aspirated 100 uL into tip");
suite.assert_near(act.plunger_pos_mm, 5.0, 1e-4, "Plunger moved 5.0 mm (at 20 uL/mm)");

act.dispense_stroke(100.0, true);
suite.assert_near(act.current_liquid_volume_ul, 0.0, 1e-4, "Dispensed 100 uL with blowout");

act.eject_tip();
suite.assert_false(act.has_tip, "Tip ejected into waste");

// 6. Gantry kinematics
local gantry = GantryKinematics(deck);
local home = gantry.current_head_pos;
suite.assert_near(home.z, 180.0, 1e-4, "Gantry homed at Z=180 mm");

gantry.actuators[0].mount_tip(tip_spec);
local tcp = gantry.get_tcp_position(0);
suite.assert_near(tcp.z, 180.0 - 51.2, 1e-4, "TCP accounts for tip length");

local target = Vector3(150.0, 100.0, 170.0);
gantry.move_safe(target, 300.0);
suite.assert_near(gantry.current_head_pos.x, 150.0, 1e-4, "Gantry moved to target X");
suite.assert_near(gantry.current_head_pos.y, 100.0, 1e-4, "Gantry moved to target Y");
suite.assert_near(gantry.current_head_pos.z, 170.0, 1e-4, "Gantry moved to target Z");
suite.assert_true(gantry.cumulative_distance_mm > 0.0, "Cumulative travel distance recorded");

local success = suite.summary();
if (!success) {
    throw "Motion tests failed.";
}
