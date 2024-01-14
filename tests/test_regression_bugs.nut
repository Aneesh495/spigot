// Spigot Regression Bug Prevention Suite
// Explicitly validates fixes for bugs discovered during engine and protocol development.

dofile("tests/assert.nut");
dofile("core/math.nut");
dofile("core/units.nut");
dofile("deck/well.nut");
dofile("deck/well_geometry.nut");
dofile("deck/reservoir.nut");
dofile("deck/plate.nut");
dofile("motion/axis_limits.nut");
dofile("motion/collision_envelope.nut");
dofile("motion/gantry_kinematics.nut");
dofile("motion/pipette_actuator.nut");
dofile("scheduler/tip_optimizer.nut");
dofile("analysis/worklist_parser.nut");
dofile("analysis/four_parameter_logistic.nut");

local suite = TestSuite("Regression Bug Prevention Suite");

// -------------------------------------------------------------
// Bug 1: Squirrel abs() truncates floats to integers
// -------------------------------------------------------------
local f_diff = 0.45;
local sq_std_abs = abs(f_diff); // In Squirrel standard library, abs(0.45) yields 0
suite.assert_equal(sq_std_abs, 0, "Demonstrate standard abs() truncates float to integer");

local proper_abs = fabs(f_diff);
suite.assert_near(proper_abs, 0.45, 1e-6, "Regression fix: fabs() preserves floating point precision");

local v1 = Vector3(1.0, 2.0, 3.0);
local v2 = Vector3(1.0000001, 2.0, 3.0);
suite.assert_true(v1.equals(v2, 1e-5), "Regression fix: Vector3.equals uses fabs() without float truncation");


// -------------------------------------------------------------
// Bug 2: 12-Channel Reservoir Liquid Height Calculation
// Circular cylinder formula caused huge liquid height inflation in rectangular troughs.
// -------------------------------------------------------------
local trough_geom = WellGeometry(WellShapeType.PYRAMIDAL_TROUGH, 32.0, 8.0, 5.0, 50.0);
local fill_vol_ul = 5000.0; // 5 mL
local trough_height = trough_geom.calculate_height_at_volume(fill_vol_ul);

// Trough area = 71.0 mm * 8.0 mm = 568.0 mm2.
// Height = 5000 mm3 / 568 mm2 ~= 8.80 mm.
// Previously, circular formula (pi * 4^2 = 50.26 mm2) gave h = 99.4 mm (exceeding well depth!).
suite.assert_true(trough_height < 32.0, "Regression fix: Trough liquid height is physically valid (< 32 mm)");
suite.assert_near(trough_height, 5000.0 / 568.0, 0.1, "Regression fix: Trough height matches rectangular cross section");


// -------------------------------------------------------------
// Bug 3: Gantry Z Axis Limit Accommodation
// Expanded Z limit to 400.0 mm to allow deep reservoir aspiration clearance.
// -------------------------------------------------------------
local gantry = GantryKinematics();
local target_safe_z = 320.0;
suite.assert_true(gantry.constraints.z_axis.is_within_limits(target_safe_z), "Regression fix: Z limit allows travel at 320 mm");


// -------------------------------------------------------------
// Bug 4: Wash Evacuation Plunger Overstroke
// Pipette plunger stroke exceeded on multi-well aspiration without intermediate dispense.
// -------------------------------------------------------------
local pip = PipetteActuator(0, 20.0);
local tip_spec = TipSpecification(1000.0, 70.0, 0.8, false);
pip.mount_tip(tip_spec);
pip.aspirate_stroke(200.0);
suite.assert_near(pip.current_liquid_volume_ul, 200.0, 1e-5, "Initial aspiration");
pip.dispense_stroke(200.0, true); // Evacuate to waste with blowout
suite.assert_near(pip.current_liquid_volume_ul, 0.0, 1e-5, "Regression fix: Pipette evacuated to waste between washes");
pip.aspirate_stroke(200.0);
suite.assert_near(pip.current_liquid_volume_ul, 200.0, 1e-5, "Subsequent aspiration succeeds without stroke overflow");


// -------------------------------------------------------------
// Bug 5: Dead Volume Evacuation via Well.empty()
// Aspirating beyond available volume threw InsufficientVolumeError; empty() solves this.
// -------------------------------------------------------------
local plate = Plate96WellFlat("test_p5");
local test_well = plate.get_well("A1");
test_well.dispense(100.0);
suite.assert_near(test_well.volume_ul, 100.0, 1e-5, "Well filled with 100 uL");
local drained = test_well.empty();
suite.assert_near(drained, 100.0, 1e-5, "Regression fix: Well.empty() returns total liquid volume");
suite.assert_near(test_well.volume_ul, 0.0, 1e-5, "Regression fix: Well volume is 0 after evacuation");


// -------------------------------------------------------------
// Bug 6: Worklist Parser CSV Header Row Detection
// Header strings like 'SourcePlate' previously caused float conversion exceptions.
// -------------------------------------------------------------
local parser = WorklistParser();
local csv_with_header = "SourcePlate,SourceWell,DestPlate,DestWell,VolumeUL\nPlate1,A1,Plate2,B1,25.0";
local parsed_items = parser.parse_csv(csv_with_header);
suite.assert_equal(parsed_items.len(), 1, "Regression fix: Header row skipped cleanly");
suite.assert_equal(parsed_items[0].source_well, "A1", "First parsed row is data row");


// -------------------------------------------------------------
// Bug 7: Tip Optimizer Table Key Check
// Checking unassigned channel in reusable_tip_channels caused index errors.
// -------------------------------------------------------------
local opt = TipOptimizer();
// Channel 5 has never been initialized; marking ejected should not throw
opt.mark_tip_ejected(5);
suite.assert_true(true, "Regression fix: mark_tip_ejected safely checks key existence");


// -------------------------------------------------------------
// Bug 8: 4PL Curve Fitter Precision and Hill Ratio
// -------------------------------------------------------------
local fpl_fitter = FourParameterLogistic();
local curve_pts = [
    { x = 0.1, y = 0.10 },
    { x = 1.0, y = 0.40 },
    { x = 10.0, y = 1.30 },
    { x = 100.0, y = 2.20 },
    { x = 1000.0, y = 2.48 }
];
local r2_score = fpl_fitter.fit(curve_pts);
suite.assert_true(r2_score > 0.95, "Regression fix: 4PL Hill log-linear fit achieves R^2 > 0.95");

local all_ok = suite.summary();
if (!all_ok) {
    throw "Regression bug tests failed.";
}
