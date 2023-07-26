// Spigot Pressure-Based Liquid Level Detection (pLLD) and Clot Monitoring
// Simulates orifice backpressure transients, surface touch detection, and aspiration occlusions.

dofile("core/errors.nut");

class PressureLLD {
    sampling_rate_hz = 1000.0;
    surface_threshold_mbar_per_s = 45.0; // dP/dt threshold for surface touch
    clot_negative_limit_mbar = -60.0; // Negative pressure redline indicating tip clog
    air_draw_threshold_mbar = -2.0; // If aspiration pressure doesn't drop below this, air was drawn

    constructor(threshold_rate = 45.0, clot_limit = -60.0) {
        surface_threshold_mbar_per_s = threshold_rate.tofloat();
        clot_negative_limit_mbar = clot_limit.tofloat();
    }

    // Simulates pressure waveform during downward tip transit towards liquid surface.
    // Returns a table { detected = bool, surface_z = float, pressure_history = array }
    function simulate_descent_search(tip_z_start, descent_speed_mm_s, true_meniscus_z, dt_s = 0.002) {
        local current_z = tip_z_start.tofloat();
        local history = [];
        local detected = false;
        local detected_z = 0.0;
        local baseline_pressure = 2.5; // Slight positive backpressure from search air flow (mbar)
        local prev_p = baseline_pressure;

        while (current_z > true_meniscus_z - 5.0) {
            current_z -= descent_speed_mm_s * dt_s;
            local current_p = baseline_pressure;

            // When tip enters liquid, backpressure jumps due to meniscus immersion
            if (current_z <= true_meniscus_z) {
                local immersion_mm = true_meniscus_z - current_z;
                // Immersion adds hydrodynamic backpressure + hydrostatic head
                current_p = baseline_pressure + (immersion_mm * 12.0);
            }

            local dp_dt = (current_p - prev_p) / dt_s;
            history.append({ z = current_z, p = current_p, dp_dt = dp_dt });

            if (!detected && dp_dt >= surface_threshold_mbar_per_s) {
                detected = true;
                detected_z = current_z;
                break;
            }
            prev_p = current_p;
        }

        return {
            detected = detected,
            surface_z = detected_z,
            history_len = history.len()
        };
    }

    // Inspects aspiration pressure profile to verify normal laminar flow or flag clot/air errors.
    function inspect_aspiration_pressure(measured_p_mbar, well_id, channel_idx = 0) {
        if (measured_p_mbar < clot_negative_limit_mbar) {
            throw ClotDetectedError(channel_idx, well_id, measured_p_mbar, clot_negative_limit_mbar);
        }
        if (measured_p_mbar > air_draw_threshold_mbar) {
            throw AirDrawError(channel_idx, well_id, "Measured aspiration pressure was near ambient; tip drew air");
        }
        return true;
    }
}
