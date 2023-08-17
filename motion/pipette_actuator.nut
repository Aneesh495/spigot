// Spigot Pipette Plunger and Tip Ejection Actuator
// Models stepper motor lead-screw plunger displacement, pickup force, and pneumatic tip stripping.

dofile("core/errors.nut");

class PipetteActuator {
    channel_index = 0;
    plunger_pos_mm = 0.0;
    max_plunger_stroke_mm = 25.0;
    steps_per_mm = 3200.0;
    microliters_per_mm = 20.0; // 1 mm plunger stroke = 20 uL displaced air
    blowout_stroke_mm = 2.0;

    has_tip = false;
    loaded_tip_spec = null; // TipSpecification
    current_liquid_volume_ul = 0.0;

    constructor(channel = 0, ul_per_mm = 20.0) {
        channel_index = channel;
        plunger_pos_mm = 0.0;
        microliters_per_mm = ul_per_mm.tofloat();
        has_tip = false;
        loaded_tip_spec = null;
        current_liquid_volume_ul = 0.0;
    }

    // Mounts a disposable tip onto the nozzle with interference fit friction check.
    function mount_tip(tip_spec) {
        if (has_tip) {
            throw "TipAlreadyPresentException: Channel " + channel_index + " already has a tip attached.";
        }
        has_tip = true;
        loaded_tip_spec = tip_spec;
        current_liquid_volume_ul = 0.0;
    }

    // Ejects the disposable tip into the solid waste chute using the stripper collar.
    function eject_tip() {
        if (!has_tip) {
            return false;
        }
        has_tip = false;
        loaded_tip_spec = null;
        current_liquid_volume_ul = 0.0;
        plunger_pos_mm = 0.0;
        return true;
    }

    // Moves the plunger upward to aspirate liquid volume into the tip.
    function aspirate_stroke(volume_ul) {
        if (!has_tip) {
            throw TipMissingError(channel_index, "Cannot aspirate: No tip attached to nozzle");
        }
        local delta_mm = volume_ul.tofloat() / microliters_per_mm;
        if (plunger_pos_mm + delta_mm > max_plunger_stroke_mm) {
            throw "PlungerStrokeExceededException: Commanded volume exceeds max plunger travel.";
        }
        plunger_pos_mm += delta_mm;
        current_liquid_volume_ul += volume_ul;
        return plunger_pos_mm;
    }

    // Moves the plunger downward to dispense liquid volume out of the tip.
    function dispense_stroke(volume_ul, use_blowout = false) {
        if (!has_tip) {
            throw TipMissingError(channel_index, "Cannot dispense: No tip attached to nozzle");
        }
        local delta_mm = volume_ul.tofloat() / microliters_per_mm;
        plunger_pos_mm -= delta_mm;
        if (plunger_pos_mm < 0.0) {
            plunger_pos_mm = 0.0;
        }
        current_liquid_volume_ul -= volume_ul;
        if (current_liquid_volume_ul < 0.0) current_liquid_volume_ul = 0.0;

        if (use_blowout) {
            // Secondary blowout stroke below 0 mm to purge residual droplets
            plunger_pos_mm = -blowout_stroke_mm;
            // Return to 0 mm resting position
            plunger_pos_mm = 0.0;
        }
        return plunger_pos_mm;
    }

    // Returns effective tip length in mm below nozzle anchor.
    function get_effective_tip_length_mm() {
        if (!has_tip || loaded_tip_spec == null) {
            return 0.0;
        }
        return loaded_tip_spec.length_mm;
    }
}
