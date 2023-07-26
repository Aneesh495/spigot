// Spigot Multi-Phase Aspiration and Dispense Sequence Generator
// Coordinates surface detection, immersion depth, flow rate ramps, equilibration, and wall touch-off.

dofile("fluidics/liquid_classes.nut");
dofile("fluidics/poiseuille_model.nut");
dofile("fluidics/droplet_dynamics.nut");
dofile("fluidics/air_displacement.nut");
dofile("fluidics/pressure_lld.nut");
dofile("fluidics/capacitive_lld.nut");

class AspirationProfile {
    liquid_class = null; // LiquidClass
    plld = null; // PressureLLD
    clld = null; // CapacitiveLLD

    constructor(lclass = null) {
        liquid_class = (lclass != null) ? lclass : StandardAqueousClass();
        plld = PressureLLD();
        clld = CapacitiveLLD();
    }

    // Plans a complete aspiration cycle from a target well.
    // Returns execution summary table with timings, pressures, and target coordinates.
    function plan_aspiration(well, volume_ul, channel_idx = 0) {
        local req_vol = volume_ul.tofloat();
        if (!well.has_available_volume(req_vol)) {
            throw InsufficientVolumeError(well.id, req_vol, well.volume_ul, well.geometry.dead_volume_ul, channel_idx);
        }

        local meniscus_z = well.get_meniscus_z();
        local target_z = meniscus_z - liquid_class.immersion_depth_mm;
        local bottom_z = well.get_bottom_z();

        // Enforce safe clearance above bottom to avoid vacuum occlusion
        if (target_z < bottom_z + 0.5) {
            target_z = bottom_z + 0.5;
        }

        local flow_rate = liquid_class.aspiration_flow_rate_ul_s;
        local duration_s = req_vol / flow_rate;

        // Calculate expected Poiseuille backpressure
        local p_drop_mbar = PoiseuilleModel.calculate_pressure_drop_mbar(
            flow_rate,
            liquid_class.properties.dynamic_viscosity_pa_s,
            51.2, // Tip length mm
            4.0,  // Tip barrel diam mm
            0.5   // Tip orifice diam mm
        );

        return {
            operation = "ASPIRATE",
            well_id = well.id,
            volume_ul = req_vol,
            channel = channel_idx,
            detected_meniscus_z = meniscus_z,
            immersion_target_z = target_z,
            flow_rate_ul_s = flow_rate,
            duration_s = duration_s,
            equilibration_delay_s = liquid_class.delay_after_aspiration_s,
            expected_pressure_mbar = -p_drop_mbar,
            air_gap_ul = liquid_class.air_transport_gap_ul,
            pre_wet_cycles = liquid_class.pre_wetting_cycles
        };
    }

    // Plans a complete dispense cycle into a target well.
    function plan_dispense(well, volume_ul, channel_idx = 0) {
        local req_vol = volume_ul.tofloat();
        local meniscus_z = well.get_meniscus_z();
        local bottom_z = well.get_bottom_z();

        local target_z = 0.0;
        if (liquid_class.sub_surface_dispense) {
            // Sub-surface dispense: immerse tip 0.5 mm below current meniscus
            target_z = meniscus_z - 0.5;
            if (target_z < bottom_z + 0.5) target_z = bottom_z + 0.5;
        } else {
            // Air dispense: position tip 2.0 mm above current meniscus
            target_z = meniscus_z + 2.0;
            local top_z = well.position.z;
            if (target_z > top_z + 5.0) target_z = top_z + 5.0;
        }

        local flow_rate = liquid_class.dispense_flow_rate_ul_s;
        local duration_s = req_vol / flow_rate;

        local crit_drop_ul = DropletDynamics.calculate_critical_droplet_volume_ul(
            0.25, // Orifice radius mm
            liquid_class.properties.surface_tension_n_m,
            liquid_class.properties.density_kg_m3
        );
        local needs_touch_off = liquid_class.touch_off_enabled && DropletDynamics.requires_touch_off(req_vol, crit_drop_ul);

        return {
            operation = "DISPENSE",
            well_id = well.id,
            volume_ul = req_vol,
            channel = channel_idx,
            dispense_target_z = target_z,
            flow_rate_ul_s = flow_rate,
            duration_s = duration_s,
            equilibration_delay_s = liquid_class.delay_after_dispense_s,
            blowout_volume_ul = liquid_class.blowout_volume_ul,
            requires_touch_off = needs_touch_off,
            critical_droplet_ul = crit_drop_ul
        };
    }
}
