// Spigot Droplet Dynamics and Pendant Drop Physics
// Models Rayleigh-Plateau instability, Tate's law critical detachment volume, and wall touch-off.

dofile("core/units.nut");

class DropletDynamics {
    // Harkins-Brown correction factor psi(r / V^(1/3))
    // Tabulated empirical approximation for pendant droplet detachment.
    static function harkins_brown_factor(r_over_v13) {
        local x = r_over_v13;
        if (x < 0.3) return 0.60;
        if (x > 1.2) return 0.65;
        // Polynomial fit to Harkins-Brown empirical curve: psi ~= 0.725 - 0.22*x + 0.15*x^2
        return 0.725 - (0.22 * x) + (0.15 * x * x);
    }

    // Computes critical droplet volume in uL before gravitational detachment occurs.
    static function calculate_critical_droplet_volume_ul(orifice_radius_mm, surface_tension_n_m, density_kg_m3) {
        local r_m = mm_to_m(orifice_radius_mm);
        if (r_m <= 0.0 || density_kg_m3 <= 0.0) return 0.0;

        // Uncorrected Tate volume: V0 = (2 * pi * r * gamma) / (rho * g)
        local v0_m3 = (2.0 * PI * r_m * surface_tension_n_m) / (density_kg_m3 * GRAVITY_M_S2);
        local v0_13 = pow(v0_m3, 1.0 / 3.0);
        local r_ratio = r_m / v0_13;
        local psi = harkins_brown_factor(r_ratio);

        local actual_v_m3 = v0_m3 * psi;
        return m3_to_ul(actual_v_m3);
    }

    // Evaluates whether a pendant droplet formed at tip orifice requires wall touch-off.
    static function requires_touch_off(dispense_volume_ul, critical_droplet_ul) {
        // Sub-microliter or low-volume dispenses smaller than critical droplet volume will hang as droplets
        return dispense_volume_ul < (critical_droplet_ul * 1.5);
    }

    // Computes capillary pull-off force (N) when touching a well wall at contact angle theta.
    static function calculate_wall_touch_off_force_n(orifice_radius_mm, surface_tension_n_m, contact_angle_deg) {
        local r_m = mm_to_m(orifice_radius_mm);
        local theta_rad = deg_to_rad(contact_angle_deg);
        return 2.0 * PI * r_m * surface_tension_n_m * cos(theta_rad);
    }
}
