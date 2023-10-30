// Spigot Four-Parameter Logistic (4PL) Regression Model
// Fits sigmoidal ELISA standard curves and dose-response pharmacology assays.

dofile("core/math.nut");

class FourParameterLogistic {
    a_bottom = 0.05; // Minimum response asymptote
    d_top = 2.50; // Maximum response asymptote
    c_ec50 = 1.00; // Inflection point (EC50)
    b_hill_slope = 1.00; // Hill slope
    r_squared = 0.00;

    constructor(bottom = 0.05, top = 2.5, ec50 = 1.0, slope = 1.0) {
        a_bottom = bottom.tofloat();
        d_top = top.tofloat();
        c_ec50 = ec50.tofloat();
        b_hill_slope = slope.tofloat();
        r_squared = 0.0;
    }

    // Evaluates expected response y (optical density) given concentration x:
    // y = D + (A - D) / (1 + (x / C)^B)
    function evaluate(x_conc) {
        local x = x_conc.tofloat();
        if (x <= 0.0) return a_bottom;

        local ratio = x / c_ec50;
        local denom = 1.0 + pow(ratio, b_hill_slope);
        return d_top + (a_bottom - d_top) / denom;
    }

    // Inverts the 4PL curve to solve for unknown concentration x given optical density y:
    // x = C * ((A - D) / (y - D) - 1)^(1 / B)
    function invert_concentration(y_response) {
        local y = y_response.tofloat();
        // Clamp to asymptotes
        if (y <= a_bottom + 1e-4) return 0.0;
        if (y >= d_top - 1e-4) return c_ec50 * 100.0;

        local factor = (a_bottom - d_top) / (y - d_top) - 1.0;
        if (factor <= 0.0) return 0.0;
        return c_ec50 * pow(factor, 1.0 / b_hill_slope);
    }

    // Fits 4PL parameters to calibration data points [{ x = float, y = float }, ...]
    // Uses the closed-form Hill linear transform on log-log coordinates.
    function fit(data_points) {
        local n = data_points.len();
        if (n < 4) {
            throw "InsufficientDataPointsException: At least 4 calibration points required to fit 4PL.";
        }

        local min_y = 1e9;
        local max_y = -1e9;
        local sum_y = 0.0;
        foreach (pt in data_points) {
            if (pt.y < min_y) min_y = pt.y;
            if (pt.y > max_y) max_y = pt.y;
            sum_y += pt.y;
        }

        // Slightly expand asymptotes to avoid log(0) singularity
        local margin = (max_y - min_y) * 0.02;
        a_bottom = min_y - margin;
        d_top = max_y + margin;
        local mean_y = sum_y / n;

        // Perform linear regression on log-transformed Hill coordinates:
        // Y' = ln((a - y) / (y - d)) = B * ln(x) - B * ln(C)
        local sum_x_prime = 0.0;
        local sum_y_prime = 0.0;
        local sum_xy = 0.0;
        local sum_xx = 0.0;
        local valid_pts = 0;

        foreach (pt in data_points) {
            if (pt.x <= 0.0) continue;
            local num = pt.y - a_bottom;
            local den = d_top - pt.y;
            if (den <= 0.0 || num <= 0.0) continue;
            local ratio = num / den;

            local x_prime = log(pt.x);
            local y_prime = log(ratio);

            sum_x_prime += x_prime;
            sum_y_prime += y_prime;
            sum_xy += x_prime * y_prime;
            sum_xx += x_prime * x_prime;
            valid_pts++;
        }

                if (valid_pts >= 2) {
            local denom = (valid_pts * sum_xx) - (sum_x_prime * sum_x_prime);
            if (fabs(denom) > 1e-6) {
                b_hill_slope = ((valid_pts * sum_xy) - (sum_x_prime * sum_y_prime)) / denom;
                local intercept = (sum_y_prime - (b_hill_slope * sum_x_prime)) / valid_pts;
                if (fabs(b_hill_slope) > 1e-5) {
                    c_ec50 = exp(-intercept / b_hill_slope);
                }
            }
        }

        if (b_hill_slope < 0.1) b_hill_slope = 1.0;
        if (c_ec50 <= 0.0) c_ec50 = 1.0;

        // Compute R^2 coefficient of determination
        local ss_tot = 0.0;
        local ss_res = 0.0;
        foreach (pt in data_points) {
            local y_pred = evaluate(pt.x);
            ss_res += (pt.y - y_pred) * (pt.y - y_pred);
            ss_tot += (pt.y - mean_y) * (pt.y - mean_y);
        }

        r_squared = (ss_tot > 1e-6) ? (1.0 - (ss_res / ss_tot)) : 1.0;
        if (r_squared < 0.0) r_squared = 0.0;
        return r_squared;
    }
}
