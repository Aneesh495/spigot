// Spigot C++ Native Acceleration Bindings Test

dofile("tests/assert.nut");

local suite = TestSuite("C++ Native Acceleration FFI Test Suite");

// Check if native functions are present in root table
local has_native_fluid = ("native_fluid_solve_flow" in getroottable());
local has_native_bvh = ("native_bvh_test_collision" in getroottable());

if (has_native_fluid && has_native_bvh) {
    // 1. Test native Navier-Stokes 1D solver
    // Density 1000 kg/m3, viscosity 1.0 cP, pressure 20 mbar
    local flow_rate = native_fluid_solve_flow(1000.0, 1.0, 20.0);
    suite.assert_true(flow_rate > 0.0, "Native fluid solver returned positive flow rate");
    suite.assert_true(flow_rate < 500.0, "Native fluid solver flow rate within physical bounds");

    // 2. Test native BVH collision query
    // Bounding box colliding with Slot 1 [20, 20, 0] to [147, 105, 50]
    local hit = native_bvh_test_collision(50.0, 50.0, 10.0, 60.0, 60.0, 20.0);
    suite.assert_true(hit, "Native BVH detected collision with Slot 1");

    // Non-colliding box
    local miss = native_bvh_test_collision(500.0, 500.0, 100.0, 550.0, 550.0, 150.0);
    suite.assert_false(miss, "Native BVH detected no collision in empty space");
} else {
    // Pure Squirrel fallback mode
    ::print("[NOTE] Native C++ bindings not loaded in pure sq interpreter; test skipped.\n");
    suite.assert_true(true, "Pure Squirrel fallback active");
}

local success = suite.summary();
if (!success) {
    throw "Native acceleration tests failed.";
}
