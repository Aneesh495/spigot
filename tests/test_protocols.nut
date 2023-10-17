// Unit and Integration tests for Spigot Assay Protocols

dofile("tests/assert.nut");
dofile("protocols/serial_dilution.nut");
dofile("protocols/pcr_setup.nut");
dofile("protocols/elisa_assay.nut");
dofile("protocols/magnetic_bead_extraction.nut");
dofile("protocols/cherry_picking.nut");
dofile("protocols/ngs_library_prep.nut");
dofile("protocols/enzyme_kinetics_screen.nut");

local suite = TestSuite("Assay Protocols Integration Test Suite");

// 1. Serial Dilution Assay Test
local sd = SerialDilutionProtocol();
sd.run();
local profile = sd.get_concentration_profile();
suite.assert_equal(profile.len(), 12, "Serial dilution produced 12 well measurements");

// Check 2-fold dilution gradient
suite.assert_near(profile[0].concentration_um, 100.0, 1e-4, "Well A1 initial concentration 100 uM");
suite.assert_near(profile[1].concentration_um, 50.0, 1e-4, "Well A2 diluted to 50 uM (1:2)");
suite.assert_near(profile[2].concentration_um, 25.0, 1e-4, "Well A3 diluted to 25 uM (1:4)");
suite.assert_near(profile[3].concentration_um, 12.5, 1e-4, "Well A4 diluted to 12.5 uM (1:8)");
suite.assert_near(profile[11].concentration_um, 0.0, 1e-4, "Well A12 negative control has 0 uM compound");

// Check volume normalization: all active wells A1..A11 should have exactly 100 uL
for (local c = 0; c < 11; c++) {
    suite.assert_near(profile[c].volume_ul, 100.0, 1e-4, "Well " + profile[c].well + " normalized to 100 uL");
}

// 2. qPCR Setup Protocol Test
local pcr = PCRSetupProtocol();
pcr.run_row("A");
local pcr_plate = pcr.pcr_plate;

// Total reaction volume: 15 uL master mix + 2 uL primer + 5 uL template = 22 uL
local sample_well = pcr_plate.get_well("A1");
suite.assert_near(sample_well.volume_ul, 22.0, 1e-4, "qPCR reaction volume is 22 uL");
suite.assert_true(sample_well.solutes.rawin("taq"), "Sample contains Taq polymerase");
suite.assert_true(sample_well.solutes.rawin("dna_ng_ul"), "Sample contains DNA template");

// Check NTC well A11
local ntc_well = pcr_plate.get_well("A11");
suite.assert_near(ntc_well.volume_ul, 22.0, 1e-4, "NTC well volume is 22 uL");
suite.assert_false(ntc_well.solutes.rawin("dna_ng_ul"), "NTC well contains no DNA template");

// 3. ELISA Assay Protocol Test
local elisa = ELISAAssayProtocol();
local elisa_results = elisa.run();
suite.assert_true(elisa_results.rawin("A1"), "ELISA results contain A1 absorbance");
// Well A1 had highest antigen, should have highest absorbance
suite.assert_true(elisa_results["A1"] > elisa_results["A8"], "A1 absorbance > A8 absorbance (concentration gradient)");

// 4. Magnetic Bead Extraction Protocol Test
local beads = MagneticBeadExtractionProtocol();
beads.run_well("A1");
local elut_well = beads.elution_plate.get_well("A1");
suite.assert_near(elut_well.volume_ul, 25.0, 1e-4, "Purified eluate volume is 25 uL");
suite.assert_true(elut_well.solutes.rawin("purified_dna_ng"), "Eluate contains purified DNA");
suite.assert_near(elut_well.solutes["purified_dna_ng"], 420.0, 1e-4, "DNA yield is 420 ng");

// 5. Cherry-Picking Protocol Test
local cherry = CherryPickingProtocol();
local count = cherry.run();
suite.assert_equal(count, 4, "4 cherry-pick transfers executed");
local tgt_a1 = cherry.dest_plate.get_well("A1");
suite.assert_near(tgt_a1.volume_ul, 20.0, 1e-4, "Cherry-picked well A1 volume is 20 uL");

// 6. NGS Library Prep Protocol Test
local ngs = NGSLibraryPrepProtocol();
ngs.run_reaction("A1");
local ngs_well = ngs.sample_plate.get_well("A1");
// Initial 50 + 10 + 5 + 15 = 80 uL
suite.assert_near(ngs_well.volume_ul, 80.0, 1e-4, "NGS reaction volume is 80 uL");
suite.assert_true(ngs_well.solutes.rawin("ngs_library_yield_ng"), "Reaction produced NGS library yield");

// 7. Enzyme Kinetics Screen Protocol Test
local kinetics = EnzymeKineticsScreenProtocol();
local kin_results = kinetics.run_screen();
suite.assert_true(kin_results.rawin("A1"), "Kinetics results contain A1");
// A8 had highest substrate concentration (800 uM vs 0 uM in A1)
suite.assert_true(kin_results["A8"] > kin_results["A1"], "A8 (800 uM substrate) produces higher product absorbance than A1 (0 uM)");

local success = suite.summary();
if (!success) {
    throw "Protocols tests failed.";
}
