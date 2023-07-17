// Spigot Liquid Physical Properties
// Models density, viscosity, surface tension, vapor pressure, and dimensionless fluid numbers.

dofile("core/units.nut");

class LiquidProperties {
    name = "Water";
    density_kg_m3 = 1000.0;
    dynamic_viscosity_pa_s = 0.001002; // 1.002 cP
    surface_tension_n_m = 0.0728; // 72.8 mN/m
    contact_angle_deg = 45.0; // Contact angle on polypropylene tip
    vapor_pressure_kpa = 2.34; // At 20 C
    foaming_factor = 0.0; // 0.0 (none) to 1.0 (extreme foam risk)

    constructor(p_name, density = 1000.0, visc_cp = 1.002, surf_tens = 0.0728, contact_ang = 45.0, vapor_p = 2.34, foam = 0.0) {
        name = p_name;
        density_kg_m3 = density.tofloat();
        dynamic_viscosity_pa_s = cp_to_pa_s(visc_cp);
        surface_tension_n_m = surf_tens.tofloat();
        contact_angle_deg = contact_ang.tofloat();
        vapor_pressure_kpa = vapor_p.tofloat();
        foaming_factor = foam.tofloat();
    }

    // Kinematic viscosity nu = mu / rho (m2/s)
    function kinematic_viscosity() {
        return dynamic_viscosity_pa_s / density_kg_m3;
    }

    // Reynolds number: Re = (rho * v * D) / mu (characterizes laminar vs turbulent flow)
    function reynolds_number(velocity_m_s, diameter_m) {
        return (density_kg_m3 * velocity_m_s * diameter_m) / dynamic_viscosity_pa_s;
    }

    // Ohnesorge number: Oh = mu / sqrt(rho * gamma * D) (characterizes droplet formation)
    function ohnesorge_number(diameter_m) {
        local denom = sqrt(density_kg_m3 * surface_tension_n_m * diameter_m);
        return dynamic_viscosity_pa_s / denom;
    }

    // Capillary number: Ca = (mu * v) / gamma (viscous vs surface tension forces)
    function capillary_number(velocity_m_s) {
        return (dynamic_viscosity_pa_s * velocity_m_s) / surface_tension_n_m;
    }

    // Weber number: We = (rho * v^2 * D) / gamma (inertia vs surface tension)
    function weber_number(velocity_m_s, diameter_m) {
        return (density_kg_m3 * velocity_m_s * velocity_m_s * diameter_m) / surface_tension_n_m;
    }

    function tostring() {
        return "LiquidProperties(" + name + ": rho=" + density_kg_m3 + " kg/m3, mu=" + pa_s_to_cp(dynamic_viscosity_pa_s) + " cP, gamma=" + (surface_tension_n_m * 1000.0) + " mN/m)";
    }
}
