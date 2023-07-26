// Spigot Capacitive Liquid Level Detection (cLLD)
// Simulates dielectric capacitance shift when conductive conductive tip touches ionic liquid surface.

class CapacitiveLLD {
    baseline_capacitance_pf = 2.4;
    detection_threshold_pf = 6.0; // Jump threshold in picofarads
    noise_amplitude_pf = 0.2;

    constructor(baseline = 2.4, threshold = 6.0) {
        baseline_capacitance_pf = baseline.tofloat();
        detection_threshold_pf = threshold.tofloat();
    }

    // Evaluates whether tip capacitance indicates liquid contact.
    function evaluate_touch(tip_z, true_meniscus_z, is_conductive_liquid = true) {
        if (!is_conductive_liquid) {
            // Non-polar organic solvents (e.g. hexane, pure chloroform) do not trip cLLD
            return false;
        }

        if (tip_z <= true_meniscus_z + 0.1) {
            // Tip has made electrical contact with aqueous electrolyte solution
            local signal = baseline_capacitance_pf + 15.0;
            return (signal - baseline_capacitance_pf) >= detection_threshold_pf;
        }
        return false;
    }
}
