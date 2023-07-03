// Spigot State Snapshot and Rollback Engine
// Provides transactional checkpoints, deep table cloning, and rollback support for error recovery.

function deep_clone_table(source) {
    local copy_tbl = {};
    foreach (k, v in source) {
        local t = typeof v;
        if (t == "table") {
            copy_tbl[k] <- deep_clone_table(v);
        } else if (t == "array") {
            copy_tbl[k] <- deep_clone_array(v);
        } else {
            copy_tbl[k] <- v;
        }
    }
    return copy_tbl;
}

function deep_clone_array(source) {
    local copy_arr = [];
    foreach (v in source) {
        local t = typeof v;
        if (t == "table") {
            copy_arr.append(deep_clone_table(v));
        } else if (t == "array") {
            copy_arr.append(deep_clone_array(v));
        } else {
            copy_arr.append(v);
        }
    }
    return copy_arr;
}

class StateStore {
    current_state = null;
    checkpoints = null;
    max_checkpoints = 50;

    constructor(initial_state = null) {
        current_state = (initial_state != null) ? deep_clone_table(initial_state) : {};
        checkpoints = [];
    }

    function set_value(key, value) {
        current_state[key] <- value;
    }

    function get_value(key, default_val = null) {
        if (current_state.rawin(key)) {
            return current_state[key];
        }
        return default_val;
    }

    function has_key(key) {
        return current_state.rawin(key);
    }

    // Creates a named restore point.
    function save_checkpoint(label = "auto") {
        local snapshot = {
            label = label,
            timestamp = time(),
            state = deep_clone_table(current_state)
        };
        if (checkpoints.len() >= max_checkpoints) {
            checkpoints.remove(0);
        }
        checkpoints.append(snapshot);
        return checkpoints.len() - 1;
    }

    // Restores the most recent checkpoint or a specific indexed checkpoint.
    function rollback(checkpoint_index = -1) {
        if (checkpoints.len() == 0) {
            throw "StateRollbackException: No checkpoints available to restore.";
        }
        local idx = checkpoint_index;
        if (idx < 0) {
            idx = checkpoints.len() - 1;
        }
        if (idx >= checkpoints.len()) {
            throw "StateRollbackException: Checkpoint index out of bounds.";
        }
        current_state = deep_clone_table(checkpoints[idx].state);
    }

    // Removes checkpoints after a specified index.
    function commit_checkpoint(checkpoint_index = -1) {
        if (checkpoints.len() == 0) return;
        local idx = (checkpoint_index < 0) ? (checkpoints.len() - 1) : checkpoint_index;
        while (checkpoints.len() > idx) {
            checkpoints.pop();
        }
    }

    function get_checkpoint_count() {
        return checkpoints.len();
    }
}
