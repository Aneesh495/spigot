// Unit tests for Volume Accounting, Contamination Graphs, 4PL Regression, and Worklists

dofile("tests/assert.nut");
dofile("analysis/volume_accounting.nut");
dofile("analysis/contamination_graph.nut");
dofile("analysis/four_parameter_logistic.nut");
dofile("analysis/worklist_parser.nut");
dofile("analysis/audit_manifest.nut");
dofile("protocols/serial_dilution.nut");

local suite = TestSuite("Analysis and Validation Subsystem Test Suite");

// 1. Volume Accounting Test
local va = VolumeAccounting();
va.record_initial_volume(500.0);
va.record_aspiration(100.0);
va.record_dispense(99.85, 0.15); // 99.85 dispensed + 0.15 retained on tip = 100.0

suite.assert_near(va.calculate_discrepancy_ul(), 0.0, 1e-4, "Discrepancy is zero when fully accounted");
suite.assert_true(va.audit_conservation(0.01), "Volume conservation audit passes");

// Imbalance case
va.record_aspiration(50.0); // Aspirate 50 but never dispense or waste
suite.assert_near(va.calculate_discrepancy_ul(), 50.0, 1e-4, "Discrepancy detects missing 50 uL");

// 2. Contamination Graph Test
local cg = ContaminationGraph();
// Tip 1 aspirates Pure_Buffer, dispenses into Well A1
cg.record_interaction("TIP_1", "Res_Ch1", "ASPIRATE", "Pure_Buffer");
cg.record_interaction("TIP_1", "A1", "DISPENSE", "Pure_Buffer");
suite.assert_equal(cg.audit_carryover().len(), 0, "Clean transfer has zero violations");

// Dirty transfer: Same tip aspirates Concentrated_DNA then enters Res_Ch1!
cg.record_interaction("TIP_1", "Sample_Well", "ASPIRATE", "Concentrated_DNA");
cg.record_interaction("TIP_1", "Res_Ch1", "ASPIRATE", "Pure_Buffer"); // Contaminates pure buffer!
local violations = cg.audit_carryover();
suite.assert_true(violations.len() > 0, "Dirty aspiration detected");
suite.assert_equal(violations[0].type, "DIRTY_ASPIRATION", "Violation type is DIRTY_ASPIRATION");

// 3. Four-Parameter Logistic (4PL) Model Test
local fpl = FourParameterLogistic(0.05, 2.5, 10.0, 1.2);
// At x = 0, y = Bottom asymptote = 0.05
suite.assert_near(fpl.evaluate(0.0), 0.05, 1e-4, "Response at zero concentration is Bottom asymptote");

// At x = EC50 (10.0), y = (Bottom + Top) / 2 = (0.05 + 2.5) / 2 = 1.275
suite.assert_near(fpl.evaluate(10.0), 1.275, 1e-3, "Response at EC50 is midpoint between asymptotes");

// Test analytical inversion: x(y)
local inverted_conc = fpl.invert_concentration(1.275);
suite.assert_near(inverted_conc, 10.0, 1e-2, "Inverting midpoint response yields EC50 concentration");

// Test 4PL fitting
local cal_data = [
    { x = 0.1, y = 0.08 },
    { x = 1.0, y = 0.35 },
    { x = 10.0, y = 1.25 },
    { x = 50.0, y = 2.10 },
    { x = 200.0, y = 2.45 }
];
local fitter = FourParameterLogistic();
local r2 = fitter.fit(cal_data);
suite.assert_true(r2 > 0.90, "4PL fit achieves R^2 > 0.90 on calibration series");

// 4. Worklist Parser Test
local parser = WorklistParser(",");
local csv_sample = @"
# Plate cherry picking worklist
SourcePlate, SourceWell, DestPlate, DestWell, Volume, LiquidClass
PlateA, A1, PlateB, B1, 25.0, Standard_Aqueous
PlateA, A2, PlateB, B2, 50.0, Viscous_Glycerol50
";
local parsed_transfers = parser.parse_csv(csv_sample);
suite.assert_equal(parsed_transfers.len(), 2, "Parsed 2 valid transfer commands from CSV");
suite.assert_equal(parsed_transfers[0].source_plate, "PlateA", "First transfer source plate");
suite.assert_equal(parsed_transfers[0].source_well, "A1", "First transfer source well");
suite.assert_near(parsed_transfers[0].volume_ul, 25.0, 1e-4, "First transfer volume 25 uL");
suite.assert_equal(parsed_transfers[1].liquid_class, "Viscous_Glycerol50", "Second transfer liquid class");

// 5. Audit Manifest Test
local sd = SerialDilutionProtocol();
sd.run();
local manifest = AuditManifest("SerialDilutionRun");
manifest.complete(sd);

suite.assert_true(manifest.transfers_count > 0, "Manifest recorded transfers");
suite.assert_true(manifest.tips_picked_count > 0, "Manifest recorded tips picked");
local summary_text = manifest.generate_summary_text();
suite.assert_true(summary_text.len() > 50, "Summary text generated");

local success = suite.summary();
if (!success) {
    throw "Analysis tests failed.";
}
