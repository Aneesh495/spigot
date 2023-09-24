// Spigot Base Assay Protocol and Pipetting Primitives
// Provides high-level transfer, distribute, consolidate, and mix operations with automated error handling.

dofile("deck/deck_layout.nut");
dofile("motion/gantry_kinematics.nut");
dofile("fluidics/aspiration_profile.nut");
dofile("scheduler/execution_engine.nut");
dofile("scheduler/tip_optimizer.nut");

class AssayProtocol {
    name = "BaseProtocol";
    description = "Abstract assay protocol";
    version = "1.0.0";

    deck = null; // DeckLayout
    gantry = null; // GantryKinematics
    asp_profile = null; // AspirationProfile
    tip_opt = null; // TipOptimizer
    task_graph = null; // TaskGraph
    engine = null; // ExecutionEngine

    transfers_executed = 0;
    tips_consumed = 0;
    total_volume_aspirated_ul = 0.0;
    total_volume_dispensed_ul = 0.0;

    constructor(proto_name, desc = "") {
        name = proto_name;
        description = desc;
        version = "1.0.0";

        deck = DeckLayout(proto_name + " Deck");
        gantry = GantryKinematics(deck);
        asp_profile = AspirationProfile(StandardAqueousClass());
        tip_opt = TipOptimizer();
        task_graph = TaskGraph();
        engine = ExecutionEngine(task_graph);

        transfers_executed = 0;
        tips_consumed = 0;
        total_volume_aspirated_ul = 0.0;
        total_volume_dispensed_ul = 0.0;
    }

    // High-level liquid transfer from source well to target well.
    function transfer(src_well, tgt_well, volume_ul, lclass = null, tip_rack = null, channel = 0, new_tip = false, touch_off = true) {
        local req_vol = volume_ul.tofloat();
        local active_lclass = (lclass != null) ? lclass : asp_profile.liquid_class;

        // Tip management
        local act = gantry.actuators[channel];
        if (new_tip || !act.has_tip) {
            if (act.has_tip) {
                eject_tip_to_waste(channel);
            }
            if (tip_rack != null) {
                pick_tip_from_rack(tip_rack, channel);
            }
        }

        // 1. Move to source well and aspirate
        local src_plan = asp_profile.plan_aspiration(src_well, req_vol, channel);
        gantry.move_channel_tcp_to(channel, src_well.position, 250.0);

        // Descend into liquid
        local asp_target = Vector3(src_well.position.x, src_well.position.y, src_plan.immersion_target_z);
        gantry.move_channel_tcp_to(channel, asp_target, 80.0);

        // Perform aspiration
        src_well.aspirate(req_vol);
        act.aspirate_stroke(req_vol);
        total_volume_aspirated_ul += req_vol;
        src_well.record_contact(act.has_tip ? "TIP_" + channel : "UNKNOWN");
        tip_opt.mark_tip_immersed(channel);

        // Retract to safe clearance
        gantry.move_channel_tcp_to(channel, src_well.position, 100.0);

        // 2. Move to target well and dispense
        local tgt_plan = asp_profile.plan_dispense(tgt_well, req_vol, channel);
        gantry.move_channel_tcp_to(channel, tgt_well.position, 250.0);

        local disp_target = Vector3(tgt_well.position.x, tgt_well.position.y, tgt_plan.dispense_target_z);
        gantry.move_channel_tcp_to(channel, disp_target, 80.0);

        // Perform dispense with blowout
        tgt_well.dispense(req_vol, src_well.liquid_class_name, src_well.solutes);
        act.dispense_stroke(req_vol, true);
        total_volume_dispensed_ul += req_vol;
        tgt_well.record_contact(act.has_tip ? "TIP_" + channel : "UNKNOWN");

        // Touch-off against well wall if required
        if (touch_off && tgt_plan.requires_touch_off) {
            local wall_offset_x = tgt_well.geometry.radius_mm * 0.7;
            local touch_pos = Vector3(disp_target.x + wall_offset_x, disp_target.y, disp_target.z);
            gantry.move_channel_tcp_to(channel, touch_pos, 50.0);
            gantry.move_channel_tcp_to(channel, disp_target, 50.0);
        }

        // Retract to safe clearance
        gantry.move_channel_tcp_to(channel, tgt_well.position, 100.0);
        transfers_executed++;

        return req_vol;
    }

    // Distributes a common source reagent to multiple destination wells using one continuous or multi-dispense tip.
    function distribute(src_well, tgt_wells_array, volume_per_well_ul, lclass = null, tip_rack = null, channel = 0) {
        local count = tgt_wells_array.len();
        local vol = volume_per_well_ul.tofloat();
        local total_req = vol * count;

        local act = gantry.actuators[channel];
        if (!act.has_tip && tip_rack != null) {
            pick_tip_from_rack(tip_rack, channel);
        }

        // If tip capacity allows, aspirate in one batch, otherwise aspirate individually
        local tip_cap = (act.loaded_tip_spec != null) ? act.loaded_tip_spec.max_volume_ul : 200.0;

        if (total_req <= tip_cap && count > 1) {
            // Batch distribute
            local src_plan = asp_profile.plan_aspiration(src_well, total_req, channel);
            gantry.move_channel_tcp_to(channel, src_well.position, 250.0);
            local asp_target = Vector3(src_well.position.x, src_well.position.y, src_plan.immersion_target_z);
            gantry.move_channel_tcp_to(channel, asp_target, 80.0);

            src_well.aspirate(total_req);
            act.aspirate_stroke(total_req);
            total_volume_aspirated_ul += total_req;
            gantry.move_channel_tcp_to(channel, src_well.position, 100.0);

            // Dispense into each target
            for (local i = 0; i < count; i++) {
                local tgt = tgt_wells_array[i];
                gantry.move_channel_tcp_to(channel, tgt.position, 250.0);
                local is_last = (i == count - 1);
                tgt.dispense(vol, src_well.liquid_class_name, src_well.solutes);
                act.dispense_stroke(vol, is_last);
                total_volume_dispensed_ul += vol;
                transfers_executed++;
            }
        } else {
            // Sequential transfers
            foreach (tgt in tgt_wells_array) {
                transfer(src_well, tgt, vol, lclass, tip_rack, channel, false, true);
            }
        }
    }

    // Mixes liquid in a target well by repeated aspiration and dispensing.
    function mix(target_well, mix_volume_ul, repetitions = 3, channel = 0) {
        local vol = mix_volume_ul.tofloat();
        local act = gantry.actuators[channel];
        if (!act.has_tip) {
            throw TipMissingError(channel, "Cannot mix: No tip attached to nozzle");
        }

        local meniscus_z = target_well.get_meniscus_z();
        local target_z = meniscus_z - 1.5;
        if (target_z < target_well.get_bottom_z() + 0.5) {
            target_z = target_well.get_bottom_z() + 0.5;
        }

        gantry.move_channel_tcp_to(channel, target_well.position, 250.0);
        local mix_target = Vector3(target_well.position.x, target_well.position.y, target_z);
        gantry.move_channel_tcp_to(channel, mix_target, 80.0);

        for (local r = 0; r < repetitions; r++) {
            target_well.aspirate(vol);
            act.aspirate_stroke(vol);
            target_well.dispense(vol);
            act.dispense_stroke(vol, false);
        }

        // Blowout at surface
        act.dispense_stroke(0.0, true);
        gantry.move_channel_tcp_to(channel, target_well.position, 100.0);
    }

    function pick_tip_from_rack(tip_rack, channel = 0) {
        local tip_well = tip_rack.find_next_tip();
        if (tip_well == null) {
            throw "TipExhaustionException: No unused tips remaining in tip rack '" + tip_rack.name + "'";
        }
        gantry.move_channel_tcp_to(channel, tip_well.position, 250.0);
        // Press downward to press-fit nozzle into tip collar
        gantry.move_linear(Vector3(tip_well.position.x, tip_well.position.y, tip_well.position.z - 8.0), 50.0);

        local spec = tip_rack.pick_tip(tip_well.id);
        gantry.actuators[channel].mount_tip(spec);
        tips_consumed++;

        // Retract gantry
        gantry.move_linear(tip_well.position, 150.0);
        return spec;
    }

    function eject_tip_to_waste(channel = 0) {
        local act = gantry.actuators[channel];
        if (!act.has_tip) return;

        local waste_pos = deck.waste_chute_pos;
        gantry.move_channel_tcp_to(channel, waste_pos, 300.0);
        act.eject_tip();
        tip_opt.mark_tip_ejected(channel);
    }
}
