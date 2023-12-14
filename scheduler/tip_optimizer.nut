// Spigot Tip Reuse and Decontamination Optimizer
// Minimizes consumable tip waste by identifying safe reuse windows without cross-contamination.

class TipOptimizer {
    reusable_tip_channels = null; // Table: channel_idx -> { tip_spec = obj, current_purity = string, is_immersed = bool }

    constructor() {
        reusable_tip_channels = {};
    }

    // Evaluates whether a currently loaded tip can be reused for an upcoming transfer.
    function can_reuse_tip(channel_idx, incoming_reagent, dispense_mode_air = true) {
        if (!reusable_tip_channels.rawin(channel_idx)) {
            return false;
        }
        local tip_state = reusable_tip_channels[channel_idx];
        if (tip_state == null) return false;

        // If tip was immersed into a contaminated sample or mixed well, it cannot be reused
        if (tip_state.is_immersed) {
            return false;
        }

        // Pure diluent buffer (e.g. Water, PBS) dispensed via air dispense can be reused indefinitely
        if (tip_state.current_purity == incoming_reagent && dispense_mode_air) {
            return true;
        }

        return false;
    }

    // Registers a tip as loaded with a specific pure reagent.
    function register_tip_loaded(channel_idx, tip_spec, reagent_name) {
        reusable_tip_channels[channel_idx] <- {
            tip = tip_spec,
            current_purity = reagent_name,
            is_immersed = false,
            dispense_count = 0
        };
    }

    // Flags that the tip touched a liquid surface or was used for mixing.
    function mark_tip_immersed(channel_idx) {
        if (reusable_tip_channels.rawin(channel_idx) && reusable_tip_channels[channel_idx] != null) {
            reusable_tip_channels[channel_idx].is_immersed = true;
        }
    }

    // Discards tip state when ejected.
    function mark_tip_ejected(channel_idx) {
        if (reusable_tip_channels.rawin(channel_idx)) {
            reusable_tip_channels[channel_idx] = null;
        }
    }
}
