// Spigot Execution Audit Manifest Generator
// Compiles full run provenance, consumable consumption metrics, mass balance, and JSON reports.

class AuditManifest {
    protocol_name = "";
    start_time = 0;
    end_time = 0;
    status = "SUCCESS";

    transfers_count = 0;
    tips_picked_count = 0;
    tips_ejected_count = 0;
    total_aspirated_ul = 0.0;
    total_dispensed_ul = 0.0;
    volume_discrepancy_ul = 0.0;

    well_records = null; // Array of well status snapshots

    constructor(proto_name = "Assay") {
        protocol_name = proto_name;
        start_time = time();
        end_time = 0;
        status = "SUCCESS";
        well_records = [];
    }

    function complete(protocol_instance, vol_accounting = null) {
        end_time = time();
        transfers_count = protocol_instance.transfers_executed;
        tips_picked_count = protocol_instance.tips_consumed;
        tips_ejected_count = protocol_instance.tips_consumed;
        total_aspirated_ul = protocol_instance.total_volume_aspirated_ul;
        total_dispensed_ul = protocol_instance.total_volume_dispensed_ul;

        if (vol_accounting != null) {
            volume_discrepancy_ul = vol_accounting.calculate_discrepancy_ul();
        }

        // Record all occupied slots and wells
        well_records = [];
        local occupied = protocol_instance.deck.get_occupied_slots();
        foreach (slot in occupied) {
            local lw = slot.installed_labware;
            foreach (w in lw.well_list) {
                if (w.volume_ul > 0.0) {
                    well_records.append({
                        slot = slot.slot_id,
                        labware = lw.name,
                        well = w.id,
                        volume_ul = w.volume_ul,
                        liquid_class = w.liquid_class_name
                    });
                }
            }
        }
    }

    // Generates human-readable summary string.
    function generate_summary_text() {
        local duration_s = end_time - start_time;
        local out = "=== SPIGOT EXECUTION AUDIT MANIFEST ===\n";
        out += "Protocol: " + protocol_name + "\n";
        out += "Status:   " + status + "\n";
        out += "Wall Time: " + duration_s + " seconds\n";
        out += "Transfers Executed: " + transfers_count + "\n";
        out += "Tips Consumed:      " + tips_picked_count + "\n";
        out += "Total Aspirated:    " + total_aspirated_ul + " uL\n";
        out += "Total Dispensed:    " + total_dispensed_ul + " uL\n";
        out += "Active Liquid Wells: " + well_records.len() + "\n";
        out += "=======================================\n";
        return out;
    }
}
