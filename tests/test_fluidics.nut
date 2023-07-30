// Unit tests for Fluidics physical models, liquid classes, and aspiration profiles

dofile("tests/assert.nut");
dofile("fluidics/liquid_classes.nut");
dofile("fluidics/poiseuille_model.nut");
dofile("fluidics/capillary_model.nut");
dofile("fluidics/droplet_dynamics.nut");
dofile("fluidics/air_displacement.nut");
dofile("fluidics/pressure_lld.nut");
dofile("fluidics/capacitive_lld.nut");
dofile("fluidics/aspiration_profile.nut");
dofile("deck/plate.nut");

local suite = TestSuite("Fluid Dynamics and Liquid Physics Test Suite");

// 1. Liquid properties and dimensionless numbers
local water_props = LiquidProperties("Test_Water", 1000.0, 1.0, 0.0728, 45.0, 2.34);
local re = water_props.reynolds_number(0.1, 0.001); // v=0.1 m/s, D=1 mm => Re = 1000 * 0.1 * 0.001 / 0.001 = 100.0
suite.assert_near(re, 100.0, 1e-4, "Water Reynolds number at 0.1 m/s is 100.0 (laminar)");

local ca = water_props.capillary_number(0.05); // Ca = mu * v / gamma
suite.assert_near(ca, (0.001 * 0.05) / 0.0728, 1e-5, "Water Capillary number");

// 2. Hagen-Poiseuille viscous resistance
// Conical tip: L=50 mm, r1=2.0 mm (barrel), r2=0.25 mm (orifice), mu=0.001 Pa*s
local p_drop_mbar = PoiseuilleModel.calculate_pressure_drop_mbar(50.0, 0.001, 50.0, 4.0, 0.5);
suite.assert_true(p_drop_mbar > 0.0, "Poiseuille pressure drop is positive");
suite.assert_true(p_drop_mbar < 50.0, "Water pressure drop at 50 uL/s is reasonable (<50 mbar)");

// Viscous fluid (Glycerol 80%, mu=60 cP) should have 60x higher pressure drop!
local p_drop_visc = PoiseuilleModel.calculate_pressure_drop_mbar(50.0, 0.060, 50.0, 4.0, 0.5);
suite.assert_near(p_drop_visc / p_drop_mbar, 60.0, 1e-3, "Viscous pressure drop scales linearly with viscosity");

// 3. Capillary rise and Young-Laplace
local cap_rise_mm = CapillaryModel.calculate_capillary_rise_mm(0.0728, 1000.0, 0.0, 0.5);
// Jurin's law: h = 2 * 0.0728 / (1000 * 9.80665 * 0.0005) ~= 0.02969 m ~= 29.69 mm
suite.assert_near(cap_rise_mm, 29.69, 0.1, "Capillary rise in 0.5 mm radius glass tube");

// 4. Droplet dynamics
local crit_drop_ul = DropletDynamics.calculate_critical_droplet_volume_ul(0.25, 0.0728, 1000.0);
suite.assert_true(crit_drop_ul > 1.0 && crit_drop_ul < 20.0, "Water critical pendant drop volume is in physical range [1, 20] uL");

local needs_touch = DropletDynamics.requires_touch_off(0.5, crit_drop_ul);
suite.assert_true(needs_touch, "0.5 uL dispense requires wall touch-off");

local no_touch = DropletDynamics.requires_touch_off(50.0, crit_drop_ul);
suite.assert_false(no_touch, "50 uL bulk dispense does not require touch-off");

// 5. Boyle's law air cushion expansion
local delta_v_exp = AirDisplacementModel.calculate_air_expansion_ul(100.0, 10.0);
suite.assert_true(delta_v_exp > 0.0, "Air expands under negative pressure");
suite.assert_near(delta_v_exp, 100.0 * (10.0 / (1013.25 - 10.0)), 1e-4, "Boyle isothermal expansion formula");

// Hydrostatic head
local head_mbar = AirDisplacementModel.calculate_hydrostatic_head_mbar(20.0, 1000.0);
suite.assert_near(head_mbar, 1000.0 * 9.80665 * 0.020 * 0.01, 1e-4, "Hydrostatic head for 20 mm water column");

// 6. Pressure LLD and clot detection
local plld = PressureLLD();
local sim_res = plld.simulate_descent_search(50.0, 10.0, 25.0, 0.002);
suite.assert_true(sim_res.detected, "pLLD detected liquid surface");
suite.assert_near(sim_res.surface_z, 25.0, 0.2, "Detected surface Z is close to true meniscus");

// Test clot detection exception
local caught_clot = false;
try {
    plld.inspect_aspiration_pressure(-85.0, "A1", 0);
} catch (e) {
    caught_clot = true;
    suite.assert_true(e instanceof ClotDetectedError, "Caught ClotDetectedError");
}
suite.assert_true(caught_clot, "Clot detected on severe negative pressure");

// 7. Aspiration profiling
local plate = Plate96WellFlat("test_plate");
local w = plate.get_well("A1");
w.dispense(200.0, "Standard_Aqueous");

local aqueous_profile = AspirationProfile(StandardAqueousClass());
local asp_plan = aqueous_profile.plan_aspiration(w, 50.0, 0);
suite.assert_equal(asp_plan.operation, "ASPIRATE", "Operation is ASPIRATE");
suite.assert_near(asp_plan.volume_ul, 50.0, 1e-4, "Volume is 50 uL");
suite.assert_near(asp_plan.flow_rate_ul_s, 50.0, 1e-4, "Aqueous flow rate 50 uL/s");

local disp_plan = aqueous_profile.plan_dispense(w, 50.0, 0);
suite.assert_equal(disp_plan.operation, "DISPENSE", "Operation is DISPENSE");
suite.assert_true(disp_plan.duration_s > 0.0, "Dispense duration is positive");

local success = suite.summary();
if (!success) {
    throw "Fluidics tests failed.";
}
