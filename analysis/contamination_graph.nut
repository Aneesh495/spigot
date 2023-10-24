// Spigot Cross-Contamination Directed Graph Detector
// Traces tip-reagent bipartite paths to guarantee zero carryover into negative controls or pure reagents.

dofile("core/errors.nut");

class ContaminationGraph {
    edges = null; // Array of { tip = string, well = string, type = "ASPIRATE"|"DISPENSE", reagent = string, time = int }
    violations = null; // Array of detected violation records

    constructor() {
        edges = [];
        violations = [];
    }

    function record_interaction(tip_id, well_id, interaction_type, reagent_name) {
        edges.append({
            tip = tip_id,
            well = well_id,
            type = interaction_type,
            reagent = reagent_name,
            timestamp = time()
        });
    }

    // Analyzes interaction history for cross-contamination events:
    // A violation occurs if a tip aspirated reagent A, and subsequently entered well B containing reagent B (where A != B),
    // without an intervening tip change or wash cycle!
    function audit_carryover() {
        violations = [];
        local tip_carried_reagent = {}; // tip_id -> reagent_name

        foreach (edge in edges) {
            local tip = edge.tip;
            if (edge.type == "ASPIRATE") {
                if (tip_carried_reagent.rawin(tip) && tip_carried_reagent[tip] != null) {
                    local prev_reagent = tip_carried_reagent[tip];
                    if (prev_reagent != edge.reagent) {
                        violations.append({
                            tip = tip,
                            source_well = edge.well,
                            carrier_reagent = prev_reagent,
                            contaminated_reagent = edge.reagent,
                            type = "DIRTY_ASPIRATION"
                        });
                    }
                } else {
                    tip_carried_reagent[tip] <- edge.reagent;
                }
            } else if (edge.type == "DISPENSE") {
                // Tip enters well to dispense
                if (tip_carried_reagent.rawin(tip) && tip_carried_reagent[tip] != null) {
                    local carried = tip_carried_reagent[tip];
                    if (carried != edge.reagent && edge.reagent != "EMPTY") {
                        // Potential carryover into target well
                        violations.append({
                            tip = tip,
                            target_well = edge.well,
                            carried_reagent = carried,
                            target_reagent = edge.reagent,
                            type = "CARRYOVER_DISPENSE"
                        });
                    }
                }
            }
        }

        return violations;
    }

    function has_violations() {
        return violations.len() > 0;
    }

    function get_violation_count() {
        return violations.len();
    }
}
