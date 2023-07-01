// Spigot Core Exception Hierarchy
// Defines domain-specific structured error types for runtime validation and recovery policies.

class SpigotError {
    message = "";
    error_code = "ERR_GENERIC";
    subsystem = "CORE";
    timestamp = 0;
    context = null;

    constructor(msg, code = "ERR_GENERIC", sub = "CORE", ctx = null) {
        message = msg;
        error_code = code;
        subsystem = sub;
        timestamp = time();
        context = (ctx != null) ? ctx : {};
    }

    function tostring() {
        return "[" + subsystem + ":" + error_code + "] " + message;
    }
}

// Deck subsystem exceptions
class DeckError extends SpigotError {
    slot_id = -1;
    labware_id = "";

    constructor(msg, code = "ERR_DECK", slot = -1, lw_id = "", ctx = null) {
        base.constructor(msg, code, "DECK", ctx);
        slot_id = slot;
        labware_id = lw_id;
    }
}

class InvalidSlotError extends DeckError {
    constructor(slot, msg = "Slot index is out of bounds or unmapped") {
        base.constructor(msg + " (slot=" + slot + ")", "ERR_INVALID_SLOT", slot, "");
    }
}

class LabwareCollisionError extends DeckError {
    constructor(slot, lw_id, msg = "Labware placement causes physical collision or slot conflict") {
        base.constructor(msg + " (slot=" + slot + ", labware=" + lw_id + ")", "ERR_LABWARE_COLLISION", slot, lw_id);
    }
}

// Fluidics subsystem exceptions
class FluidicsError extends SpigotError {
    channel_index = 0;
    well_id = "";

    constructor(msg, code = "ERR_FLUIDICS", ch = 0, well = "", ctx = null) {
        base.constructor(msg, code, "FLUIDICS", ctx);
        channel_index = ch;
        well_id = well;
    }
}

class InsufficientVolumeError extends FluidicsError {
    requested_ul = 0.0;
    available_ul = 0.0;
    dead_volume_ul = 0.0;

    constructor(well, req, avail, dead, ch = 0) {
        base.constructor(
            "Insufficient volume in well " + well + ": requested " + req + " uL, available " + avail + " uL (dead volume " + dead + " uL)",
            "ERR_INSUFFICIENT_VOLUME",
            ch,
            well,
            { requested = req, available = avail, dead_volume = dead }
        );
        requested_ul = req.tofloat();
        available_ul = avail.tofloat();
        dead_volume_ul = dead.tofloat();
    }
}

class WellOverfillError extends FluidicsError {
    max_capacity_ul = 0.0;
    attempted_ul = 0.0;

    constructor(well, max_cap, attempted, ch = 0) {
        base.constructor(
            "Overfill in well " + well + ": max capacity " + max_cap + " uL exceeded by attempt " + attempted + " uL",
            "ERR_WELL_OVERFILL",
            ch,
            well,
            { max_capacity = max_cap, attempted = attempted }
        );
        max_capacity_ul = max_cap.tofloat();
        attempted_ul = attempted.tofloat();
    }
}

class TipMissingError extends FluidicsError {
    constructor(ch = 0, msg = "Pipetting operation attempted without tip loaded on channel") {
        base.constructor(msg + " (channel=" + ch + ")", "ERR_TIP_MISSING", ch, "");
    }
}

class ClotDetectedError extends FluidicsError {
    pressure_mbar = 0.0;
    threshold_mbar = 0.0;

    constructor(ch, well, pressure, threshold) {
        base.constructor(
            "Aspiration occlusion / clot detected on channel " + ch + " in well " + well + ": pressure " + pressure + " mbar below threshold " + threshold + " mbar",
            "ERR_CLOT_DETECTED",
            ch,
            well,
            { pressure = pressure, threshold = threshold }
        );
        pressure_mbar = pressure.tofloat();
        threshold_mbar = threshold.tofloat();
    }
}

class AirDrawError extends FluidicsError {
    constructor(ch, well, msg = "Aspiration drew air instead of liquid; surface tracking failed") {
        base.constructor(msg + " (channel=" + ch + ", well=" + well + ")", "ERR_AIR_DRAW", ch, well);
    }
}

class CrossContaminationError extends FluidicsError {
    source_reagent = "";
    target_reagent = "";

    constructor(ch, well, src, tgt) {
        base.constructor(
            "Cross-contamination hazard on channel " + ch + " entering well " + well + ": tip carries " + src + ", well contains " + tgt,
            "ERR_CROSS_CONTAMINATION",
            ch,
            well,
            { source_reagent = src, target_reagent = tgt }
        );
        source_reagent = src;
        target_reagent = tgt;
    }
}

// Motion and Kinematics exceptions
class MotionError extends SpigotError {
    axis = "";
    commanded_pos = 0.0;

    constructor(msg, code = "ERR_MOTION", ax = "", pos = 0.0, ctx = null) {
        base.constructor(msg, code, "MOTION", ctx);
        axis = ax;
        commanded_pos = pos.tofloat();
    }
}

class AxisLimitError extends MotionError {
    limit_min = 0.0;
    limit_max = 0.0;

    constructor(ax, commanded, min_lim, max_lim) {
        base.constructor(
            "Axis " + ax + " limit violation: commanded " + commanded + " mm is outside range [" + min_lim + ", " + max_lim + "] mm",
            "ERR_AXIS_LIMIT",
            ax,
            commanded,
            { min = min_lim, max = max_lim }
        );
        limit_min = min_lim.tofloat();
        limit_max = max_lim.tofloat();
    }
}

class GantryCollisionError extends MotionError {
    obstacle_name = "";

    constructor(pos_desc, obstacle) {
        base.constructor(
            "Gantry path intersects physical obstacle '" + obstacle + "' at position " + pos_desc,
            "ERR_GANTRY_COLLISION",
            "XYZ",
            0.0,
            { obstacle = obstacle }
        );
        obstacle_name = obstacle;
    }
}

// Scheduler exceptions
class SchedulerError extends SpigotError {
    task_id = "";

    constructor(msg, code = "ERR_SCHEDULER", tid = "", ctx = null) {
        base.constructor(msg, code, "SCHEDULER", ctx);
        task_id = tid;
    }
}

class DependencyCycleError extends SchedulerError {
    constructor(cycle_desc) {
        base.constructor(
            "Cyclic dependency detected in task graph: " + cycle_desc,
            "ERR_DEPENDENCY_CYCLE",
            "",
            { cycle = cycle_desc }
        );
    }
}

class ResourceDeadlockError extends SchedulerError {
    constructor(res_name, tasks_desc) {
        base.constructor(
            "Resource lock conflict or deadlock on '" + res_name + "' with tasks: " + tasks_desc,
            "ERR_RESOURCE_DEADLOCK",
            "",
            { resource = res_name, tasks = tasks_desc }
        );
    }
}
