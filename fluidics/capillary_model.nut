// Spigot Young-Laplace Capillary and Meniscus Model
// Models capillary rise, meniscus depression, and surface curvature at micro-scale boundaries.

dofile("core/units.nut");

class CapillaryModel {
    // Computes Young-Laplace capillary pressure jump (Pa): DeltaP = (2 * gamma * cos(theta)) / r
    static function calculate_capillary_pressure_pa(surface_tension_n_m, contact_angle_deg, radius_m) {
        if (radius_m <= 0.0) throw "InvalidRadiusException: Radius must be positive.";
        local theta_rad = deg_to_rad(contact_angle_deg);
        return (2.0 * surface_tension_n_m * cos(theta_rad)) / radius_m;
    }

    // Computes Jurin's capillary rise height (mm): h = (2 * gamma * cos(theta)) / (rho * g * r)
    static function calculate_capillary_rise_mm(surface_tension_n_m, density_kg_m3, contact_angle_deg, radius_mm) {
        local r_m = mm_to_m(radius_mm);
        if (r_m <= 0.0 || density_kg_m3 <= 0.0) return 0.0;
        local theta_rad = deg_to_rad(contact_angle_deg);
        local h_m = (2.0 * surface_tension_n_m * cos(theta_rad)) / (density_kg_m3 * GRAVITY_M_S2 * r_m);
        return m_to_mm(h_m);
    }

    // Computes the spherical cap volume of the liquid meniscus inside a cylindrical well or tip (uL).
    static function calculate_meniscus_volume_ul(radius_mm, contact_angle_deg) {
        local theta_rad = deg_to_rad(contact_angle_deg);
        local cos_th = cos(theta_rad);
        if (abs(cos_th) < 1e-5) return 0.0;
        // Spherical cap radius R_c = r / cos(theta)
        local r_c = radius_mm / cos_th;
        local h_cap = r_c - (radius_mm * (sin(theta_rad) / cos_th));
        // Cap volume: V = (1/6) * pi * h * (3*r^2 + h^2)
        local vol_mm3 = (1.0 / 6.0) * PI * h_cap * (3.0 * radius_mm * radius_mm + h_cap * h_cap);
        return abs(vol_mm3);
    }
}
