// Unit tests for physical units and dimensional conversions

dofile("tests/assert.nut");
dofile("core/units.nut");

local suite = TestSuite("Units and Dimensional Conversions Test Suite");

// Volume conversions
suite.assert_near(ul_to_ml(1000.0), 1.0, 1e-6, "1000 uL == 1.0 mL");
suite.assert_near(ml_to_ul(2.5), 2500.0, 1e-6, "2.5 mL == 2500 uL");
suite.assert_near(ul_to_nl(5.0), 5000.0, 1e-6, "5 uL == 5000 nL");
suite.assert_near(nl_to_ul(7500.0), 7.5, 1e-6, "7500 nL == 7.5 uL");
suite.assert_near(l_to_ul(0.001), 1000.0, 1e-3, "0.001 L == 1000 uL");
suite.assert_near(ul_to_m3(1e6), 0.001, 1e-7, "1e6 uL == 0.001 m3");
suite.assert_near(m3_to_ul(0.001), 1e6, 0.1, "0.001 m3 == 1e6 uL");

// Distance conversions
suite.assert_near(mm_to_m(1500.0), 1.5, 1e-6, "1500 mm == 1.5 m");
suite.assert_near(m_to_mm(0.25), 250.0, 1e-6, "0.25 m == 250 mm");
suite.assert_near(um_to_mm(9000.0), 9.0, 1e-6, "9000 um == 9.0 mm");
suite.assert_near(mm_to_um(4.5), 4500.0, 1e-6, "4.5 mm == 4500 um");
suite.assert_near(in_to_mm(1.0), 25.4, 1e-6, "1 inch == 25.4 mm");
suite.assert_near(mm_to_in(50.8), 2.0, 1e-6, "50.8 mm == 2 inches");

// Pressure conversions
suite.assert_near(mbar_to_pa(10.0), 1000.0, 1e-6, "10 mbar == 1000 Pa");
suite.assert_near(pa_to_mbar(500.0), 5.0, 1e-6, "500 Pa == 5.0 mbar");
suite.assert_near(atm_to_pa(1.0), 101325.0, 1e-3, "1 atm == 101325 Pa");

// Viscosity conversions
suite.assert_near(cp_to_pa_s(1.0), 0.001, 1e-7, "1 cP == 0.001 Pa*s");
suite.assert_near(pa_s_to_cp(0.05), 50.0, 1e-5, "0.05 Pa*s == 50 cP");

// Time conversions
suite.assert_near(s_to_ms(1.5), 1500.0, 1e-6, "1.5 s == 1500 ms");
suite.assert_near(ms_to_s(250.0), 0.25, 1e-6, "250 ms == 0.25 s");
suite.assert_near(min_to_s(5.0), 300.0, 1e-6, "5 min == 300 s");
suite.assert_near(hr_to_s(1.5), 5400.0, 1e-6, "1.5 hr == 5400 s");

// Angle conversions
suite.assert_near(deg_to_rad(180.0), PI, 1e-6, "180 deg == PI rad");
suite.assert_near(rad_to_deg(PI / 2.0), 90.0, 1e-6, "PI/2 rad == 90 deg");

// Temperature conversions
suite.assert_near(c_to_k(20.0), 293.15, 1e-4, "20 C == 293.15 K");
suite.assert_near(k_to_c(373.15), 100.0, 1e-4, "373.15 K == 100 C");

local success = suite.summary();
if (!success) {
    throw "Units tests failed.";
}
