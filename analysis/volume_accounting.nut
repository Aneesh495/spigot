// Spigot Volume Conservation and Mass Balance Accounting
// Audits strict volumetric conservation across source wells, target wells, waste, and tip retention.

dofile("core/errors.nut");

class VolumeAccounting {
    initial_inventory_ul = 0.0;
    source_aspirated_ul = 0.0;
    target_dispensed_ul = 0.0;
    waste_volume_ul = 0.0;
    tip_retention_loss_ul = 0.0;
    evaporation_loss_ul = 0.0;

    constructor() {
        reset();
    }

    function reset() {
        initial_inventory_ul = 0.0;
        source_aspirated_ul = 0.0;
        target_dispensed_ul = 0.0;
        waste_volume_ul = 0.0;
        tip_retention_loss_ul = 0.0;
        evaporation_loss_ul = 0.0;
    }

    function record_initial_volume(vol_ul) {
        initial_inventory_ul += vol_ul.tofloat();
    }

    function record_aspiration(vol_ul) {
        source_aspirated_ul += vol_ul.tofloat();
    }

    function record_dispense(vol_ul, tip_retention = 0.15) {
        target_dispensed_ul += vol_ul.tofloat();
        tip_retention_loss_ul += tip_retention.tofloat();
    }

    function record_waste(vol_ul) {
        waste_volume_ul += vol_ul.tofloat();
    }

    function record_evaporation(vol_ul) {
        evaporation_loss_ul += vol_ul.tofloat();
    }

    // Computes volumetric balance discrepancy:
    // Discrepancy = SourceAspirated - (TargetDispensed + Waste + TipRetention + Evaporation)
    function calculate_discrepancy_ul() {
        local accounted_output = target_dispensed_ul + waste_volume_ul + tip_retention_loss_ul + evaporation_loss_ul;
        return abs(source_aspirated_ul - accounted_output);
    }

    // Verifies that mass conservation holds within specified tolerance.
    function audit_conservation(tolerance_ul = 0.5) {
        local disc = calculate_discrepancy_ul();
        if (disc > tolerance_ul) {
            throw "VolumeConservationException: Volume imbalance of " + disc + " uL exceeds tolerance " + tolerance_ul + " uL";
        }
        return true;
    }

    function get_summary() {
        return {
            initial_inventory = initial_inventory_ul,
            aspirated = source_aspirated_ul,
            dispensed = target_dispensed_ul,
            waste = waste_volume_ul,
            tip_retention = tip_retention_loss_ul,
            evaporation = evaporation_loss_ul,
            discrepancy = calculate_discrepancy_ul()
        };
    }
}
