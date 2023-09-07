// Spigot Task Node Model
// Encapsulates a discrete protocol step, duration estimates, and resource requirements.

::TaskStatus <- {
    PENDING   = 0,
    READY     = 1,
    RUNNING   = 2,
    COMPLETED = 3,
    FAILED    = 4
};

class TaskNode {
    id = "";
    name = "";
    duration_s = 0.0;
    required_resources = null; // Array of strings (e.g. ["GANTRY", "SLOT_1"])
    dependencies = null; // Array of parent task IDs that must complete first
    status = 0;
    action_closure = null; // Squirrel function to execute

    // CPM scheduling properties
    early_start = 0.0;
    early_finish = 0.0;
    late_start = 0.0;
    late_finish = 0.0;
    total_slack = 0.0;

    constructor(t_id, t_name, est_duration = 5.0, resources = null, closure = null) {
        id = t_id;
        name = t_name;
        duration_s = est_duration.tofloat();
        required_resources = (resources != null) ? resources : [];
        dependencies = [];
        status = TaskStatus.PENDING;
        action_closure = closure;

        early_start = 0.0;
        early_finish = 0.0;
        late_start = 0.0;
        late_finish = 0.0;
        total_slack = 0.0;
    }

    function add_dependency(parent_task_id) {
        foreach (dep in dependencies) {
            if (dep == parent_task_id) return;
        }
        dependencies.append(parent_task_id);
    }

    function is_critical() {
        return abs(total_slack) < 1e-4;
    }

    function tostring() {
        return "TaskNode(" + id + ": '" + name + "', dur=" + duration_s + "s, status=" + status + ")";
    }
}
