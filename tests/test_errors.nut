// Unit tests for Spigot exception hierarchy and error metadata

dofile("tests/assert.nut");
dofile("core/errors.nut");

local suite = TestSuite("Error Hierarchy and Exception Metadata Test Suite");

// Base error
local base_err = SpigotError("Generic failure", "ERR_TEST", "CORE");
suite.assert_equal(base_err.subsystem, "CORE", "Subsystem is CORE");
suite.assert_equal(base_err.error_code, "ERR_TEST", "Error code matches");
suite.assert_equal(base_err.message, "Generic failure", "Message matches");

// Deck error
local slot_err = InvalidSlotError(14);
suite.assert_equal(slot_err.subsystem, "DECK", "Deck error subsystem");
suite.assert_equal(slot_err.slot_id, 14, "Deck error slot ID");
suite.assert_equal(slot_err.error_code, "ERR_INVALID_SLOT", "Slot error code");

// Fluidics error: Insufficient volume
local vol_err = InsufficientVolumeError("A1", 100.0, 45.0, 10.0, 0);
suite.assert_equal(vol_err.subsystem, "FLUIDICS", "Fluidics subsystem");
suite.assert_equal(vol_err.well_id, "A1", "Well ID");
suite.assert_near(vol_err.requested_ul, 100.0, 1e-6, "Requested volume");
suite.assert_near(vol_err.available_ul, 45.0, 1e-6, "Available volume");
suite.assert_near(vol_err.dead_volume_ul, 10.0, 1e-6, "Dead volume");

// Fluidics error: Clot detection
local clot_err = ClotDetectedError(3, "B6", -85.0, -50.0);
suite.assert_equal(clot_err.channel_index, 3, "Channel index");
suite.assert_near(clot_err.pressure_mbar, -85.0, 1e-6, "Occlusion pressure");
suite.assert_near(clot_err.threshold_mbar, -50.0, 1e-6, "Occlusion threshold");

// Motion error: Axis limit
local lim_err = AxisLimitError("Z", 350.0, 0.0, 300.0);
suite.assert_equal(lim_err.axis, "Z", "Axis name");
suite.assert_near(lim_err.commanded_pos, 350.0, 1e-6, "Commanded position");
suite.assert_near(lim_err.limit_max, 300.0, 1e-6, "Maximum limit");

// Catching polymorphic exceptions
local caught = false;
try {
    throw WellOverfillError("C3", 200.0, 250.0, 1);
} catch (e) {
    caught = true;
    suite.assert_true(e instanceof WellOverfillError, "Caught instance of WellOverfillError");
    suite.assert_true(e instanceof FluidicsError, "Inherits from FluidicsError");
    suite.assert_true(e instanceof SpigotError, "Inherits from SpigotError");
}
suite.assert_true(caught, "Exception was caught properly");

local success = suite.summary();
if (!success) {
    throw "Error tests failed.";
}
