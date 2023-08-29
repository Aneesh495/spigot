// Spigot Resource Lock Subsystem
// Manages exclusive mutex locks on gantry, deck slots, and active accessories during execution.

dofile("core/errors.nut");

class ResourceLockManager {
    locks = null; // Table: resource_name -> owning_task_id or null

    constructor() {
        locks = {};
    }

    function register_resource(resource_name) {
        if (!locks.rawin(resource_name)) {
            locks[resource_name] <- null;
        }
    }

    function is_locked(resource_name) {
        if (!locks.rawin(resource_name)) return false;
        return locks[resource_name] != null;
    }

    function get_owner(resource_name) {
        if (!locks.rawin(resource_name)) return null;
        return locks[resource_name];
    }

    // Attempts to acquire exclusive lock on a resource for a task.
    function acquire(resource_name, task_id) {
        register_resource(resource_name);
        if (locks[resource_name] != null && locks[resource_name] != task_id) {
            return false;
        }
        locks[resource_name] = task_id;
        return true;
    }

    // Releases a previously acquired lock.
    function release(resource_name, task_id) {
        if (!locks.rawin(resource_name)) return;
        if (locks[resource_name] == task_id) {
            locks[resource_name] = null;
        }
    }

    // Releases all locks owned by a specific task.
    function release_all_for_task(task_id) {
        foreach (res, owner in locks) {
            if (owner == task_id) {
                locks[res] = null;
            }
        }
    }
}
