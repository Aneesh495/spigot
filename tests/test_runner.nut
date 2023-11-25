// Spigot Central Test Runner
// Dispatches and aggregates all unit, integration, and structural test suites.

local start_clock = clock();

::print("\n=======================================================\n");
::print("       SPIGOT AUTOMATED TEST RUNNER (SQUIRREL 3.2)     \n");
::print("=======================================================\n\n");

local test_suites = [
    "tests/test_math.nut",
    "tests/test_units.nut",
    "tests/test_errors.nut",
    "tests/test_state.nut",
    "tests/test_deck.nut",
    "tests/test_fluidics.nut",
    "tests/test_motion.nut",
    "tests/test_scheduler.nut",
    "tests/test_protocols.nut",
    "tests/test_analysis.nut"
];

local all_passed = true;
local suites_run = 0;

foreach (test_file in test_suites) {
    ::print(">> Running suite: " + test_file + " ...\n");
    try {
        dofile(test_file);
        suites_run++;
    } catch (err) {
        ::print("[ERROR] Suite '" + test_file + "' failed with error: " + err + "\n");
        all_passed = false;
        break;
    }
}

local elapsed = (clock() - start_clock).tofloat();

::print("\n=======================================================\n");
if (all_passed) {
    ::print("  ALL " + suites_run + " TEST SUITES PASSED SUCCESSFULLY!\n");
    ::print("  Total Execution Time: " + elapsed + " seconds\n");
    ::print("  Status: ZERO REGRESSIONS (Smooth as butter)\n");
} else {
    ::print("  TEST SUITE RUN FAILED!\n");
}
::print("=======================================================\n\n");

if (!all_passed) {
    throw "SpigotTestSuiteFailure: One or more suites failed.";
}
