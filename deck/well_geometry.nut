// Spigot Analytical Well Geometry Library
// Computes height-volume piecewise integrals, meniscus curvatures, and surface area profiles.

::WellShapeType <- {
    FLAT_CYLINDER       = 0,
    V_CONICAL           = 1,
    U_ROUND             = 2,
    COMPOSITE_CONICAL   = 3,
    COMPOSITE_ROUND     = 4,
    PYRAMIDAL_TROUGH    = 5
};

class WellGeometry {
    shape_type = 0;
    total_depth_mm = 0.0;
    diameter_mm = 0.0;
    radius_mm = 0.0;
    bottom_height_mm = 0.0; // Height of bottom section for composite wells
    max_volume_ul = 0.0;
    dead_volume_ul = 0.0;

    constructor(type, depth, diam, bottom_h = 0.0, dead_vol = 2.0) {
        shape_type = type;
        total_depth_mm = depth.tofloat();
        diameter_mm = diam.tofloat();
        radius_mm = diameter_mm * 0.5;
        bottom_height_mm = bottom_h.tofloat();
        dead_volume_ul = dead_vol.tofloat();
        max_volume_ul = calculate_volume_at_height(total_depth_mm);
    }

    // Computes liquid volume in microliters given liquid height above the well bottom.
    function calculate_volume_at_height(h) {
        local height = h.tofloat();
        if (height <= 0.0) return 0.0;
        if (height > total_depth_mm) height = total_depth_mm;

        local r = radius_mm;

        switch (shape_type) {
            case WellShapeType.FLAT_CYLINDER: {
                // V = pi * r^2 * h (in mm3 == uL, since 1 mm3 = 1 uL!)
                return PI * r * r * height;
            }

            case WellShapeType.V_CONICAL: {
                // V = (1/3) * pi * (r * h / H)^2 * h
                local current_r = (height / total_depth_mm) * r;
                return (1.0 / 3.0) * PI * current_r * current_r * height;
            }

            case WellShapeType.U_ROUND: {
                // Spherical cap: V = (1/3) * pi * h^2 * (3*r - h)
                if (height < r) {
                    return (1.0 / 3.0) * PI * height * height * (3.0 * r - height);
                } else {
                    local hemisphere_vol = (2.0 / 3.0) * PI * r * r * r;
                    local cyl_height = height - r;
                    return hemisphere_vol + (PI * r * r * cyl_height);
                }
            }

            case WellShapeType.COMPOSITE_CONICAL: {
                local h_bot = bottom_height_mm;
                if (height <= h_bot) {
                    local cur_r = (height / h_bot) * r;
                    return (1.0 / 3.0) * PI * cur_r * cur_r * height;
                } else {
                    local bot_vol = (1.0 / 3.0) * PI * r * r * h_bot;
                    local cyl_vol = PI * r * r * (height - h_bot);
                    return bot_vol + cyl_vol;
                }
            }

            case WellShapeType.COMPOSITE_ROUND: {
                local h_bot = (bottom_height_mm > 0.0) ? bottom_height_mm : r;
                if (height <= h_bot) {
                    return (1.0 / 3.0) * PI * height * height * (3.0 * h_bot - height);
                } else {
                    local bot_vol = (2.0 / 3.0) * PI * h_bot * h_bot * h_bot;
                    local cyl_vol = PI * r * r * (height - h_bot);
                    return bot_vol + cyl_vol;
                }
            }

            case WellShapeType.PYRAMIDAL_TROUGH: {
                // V = (1/3) * L * W * h
                // Approximated for reagent troughs
                return PI * r * r * height * 0.9;
            }

            default:
                return PI * r * r * height;
        }
    }

    // Computes liquid height in millimeters given liquid volume in microliters.
    function calculate_height_at_volume(vol_ul) {
        local vol = vol_ul.tofloat();
        if (vol <= 0.0) return 0.0;
        if (vol >= max_volume_ul) return total_depth_mm;

        local r = radius_mm;

        switch (shape_type) {
            case WellShapeType.FLAT_CYLINDER: {
                // h = V / (pi * r^2)
                return vol / (PI * r * r);
            }

            case WellShapeType.V_CONICAL: {
                // V = (1/3) * pi * (r / H)^2 * h^3 => h = (3 * V * H^2 / (pi * r^2))^(1/3)
                local factor = (3.0 * vol * total_depth_mm * total_depth_mm) / (PI * r * r);
                return pow(factor, 1.0 / 3.0);
            }

            case WellShapeType.COMPOSITE_CONICAL: {
                local h_bot = bottom_height_mm;
                local bot_vol = (1.0 / 3.0) * PI * r * r * h_bot;
                if (vol <= bot_vol) {
                    local factor = (3.0 * vol * h_bot * h_bot) / (PI * r * r);
                    return pow(factor, 1.0 / 3.0);
                } else {
                    local excess_vol = vol - bot_vol;
                    local cyl_h = excess_vol / (PI * r * r);
                    return h_bot + cyl_h;
                }
            }

            default: {
                // Newton-Raphson numerical inversion for arbitrary profiles
                local guess_h = (vol / max_volume_ul) * total_depth_mm;
                for (local iter = 0; iter < 10; iter++) {
                    local f = calculate_volume_at_height(guess_h) - vol;
                    local df = calculate_cross_sectional_area(guess_h);
                    if (df < 1e-6) break;
                    local step = f / df;
                    guess_h -= step;
                    if (guess_h < 0.0) guess_h = 0.0;
                    if (guess_h > total_depth_mm) guess_h = total_depth_mm;
                    if (abs(step) < 1e-5) break;
                }
                return guess_h;
            }
        }
    }

    // Computes cross-sectional surface area in mm2 at a given height above bottom.
    function calculate_cross_sectional_area(h) {
        local height = h.tofloat();
        if (height <= 0.0) return 0.0;
        local r = radius_mm;

        switch (shape_type) {
            case WellShapeType.FLAT_CYLINDER:
                return PI * r * r;

            case WellShapeType.V_CONICAL: {
                local cur_r = (height / total_depth_mm) * r;
                return PI * cur_r * cur_r;
            }

            case WellShapeType.COMPOSITE_CONICAL: {
                if (height <= bottom_height_mm) {
                    local cur_r = (height / bottom_height_mm) * r;
                    return PI * cur_r * cur_r;
                }
                return PI * r * r;
            }

            default:
                return PI * r * r;
        }
    }
}
