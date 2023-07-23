// Spigot Hagen-Poiseuille Viscous Flow Model
// Computes hydraulic resistance and pressure drop across conical tapered pipette tips.

dofile("core/units.nut");

class PoiseuilleModel {
    // Computes hydraulic resistance (Pa * s / m3) for a cylindrical bore.
    static function cylindrical_resistance(dynamic_visc_pa_s, length_m, radius_m) {
        if (radius_m <= 0.0) throw "InvalidRadiusException: Radius must be positive.";
        local r4 = radius_m * radius_m * radius_m * radius_m;
        return (8.0 * dynamic_visc_pa_s * length_m) / (PI * r4);
    }

    // Computes hydraulic resistance (Pa * s / m3) for a truncated conical tip (orifice r2 to barrel r1).
    static function conical_tip_resistance(dynamic_visc_pa_s, length_m, r1_barrel_m, r2_orifice_m) {
        if (r1_barrel_m <= 0.0 || r2_orifice_m <= 0.0) {
            throw "InvalidRadiusException: Radii must be positive.";
        }
        local r1 = r1_barrel_m;
        local r2 = r2_orifice_m;
        local numerator = r1 * r1 + r1 * r2 + r2 * r2;
        local denominator = 3.0 * (r1 * r1 * r1) * (r2 * r2 * r2);
        return ((8.0 * dynamic_visc_pa_s * length_m) / PI) * (numerator / denominator);
    }

    // Computes pressure drop in millibars (mbar) for given flow rate in uL/s.
    static function calculate_pressure_drop_mbar(flow_rate_ul_s, dynamic_visc_pa_s, length_mm, barrel_diam_mm, orifice_diam_mm) {
        local q_m3_s = ul_to_m3(flow_rate_ul_s);
        local len_m = mm_to_m(length_mm);
        local r1_m = mm_to_m(barrel_diam_mm * 0.5);
        local r2_m = mm_to_m(orifice_diam_mm * 0.5);

        local r_hyd = conical_tip_resistance(dynamic_visc_pa_s, len_m, r1_m, r2_m);
        local delta_p_pa = r_hyd * q_m3_s;
        return pa_to_mbar(delta_p_pa);
    }

    // Computes achievable flow rate in uL/s given an applied pressure differential in mbar.
    static function calculate_flow_rate_ul_s(delta_p_mbar, dynamic_visc_pa_s, length_mm, barrel_diam_mm, orifice_diam_mm) {
        local delta_p_pa = mbar_to_pa(delta_p_mbar);
        local len_m = mm_to_m(length_mm);
        local r1_m = mm_to_m(barrel_diam_mm * 0.5);
        local r2_m = mm_to_m(orifice_diam_mm * 0.5);

        local r_hyd = conical_tip_resistance(dynamic_visc_pa_s, len_m, r1_m, r2_m);
        local q_m3_s = delta_p_pa / r_hyd;
        return m3_to_ul(q_m3_s);
    }
}
