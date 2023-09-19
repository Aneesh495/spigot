// Spigot Asynchronous Assay Execution Engine
// Coordinates task graph stepping, concurrency locks, state checkpoints, and event emission.

dofile("scheduler/task_graph.nut");
dofile("scheduler/resource_lock.nut");
dofile("scheduler/cpm_solver.nut");
dofile("core/events.nut");
dofile("core/logging.nut");
dofile("core/state.nut");

class ExecutionEngine {
    task_graph = null;
    lock_manager = null;
    event_dispatcher = null;
    state_store = null;
    logger = null;

    current_sim_time_s = 0.0;
    is_running = false;
    completed_task_ids = null;
    failed_task_ids = null;

    constructor(graph, events = null, state = null) {
        task_graph = graph;
        lock_manager = ResourceLockManager();
        event_dispatcher = (events != null) ? events : EventDispatcher();
        state_store = (state != null) ? state : StateStore();
        logger = Logger("ENGINE", LogLevel.INFO, false);

        current_sim_time_s = 0.0;
        is_running = false;
        completed_task_ids = {};
        failed_task_ids = {};
    }

    // Resolves all pending tasks whose prerequisites have fully completed.
    function get_ready_tasks() {
        local ready = [];
        foreach (id, node in task_graph.nodes) {
            if (node.status != TaskStatus.PENDING) continue;

            local all_deps_done = true;
            local parents = task_graph.get_parents(id);
            foreach (p_id in parents) {
                if (!completed_task_ids.rawin(p_id)) {
                    all_deps_done = false;
                    break;
                }
            }

            if (all_deps_done) {
                // Check resource availability
                local resources_free = true;
                foreach (res in node.required_resources) {
                    if (lock_manager.is_locked(res)) {
                        resources_free = false;
                        break;
                    }
                }
                if (resources_free) {
                    ready.append(node);
                }
            }
        }
        return ready;
    }

    // Executes the entire task graph to completion or stops on failure.
    function run_all() {
        is_running = true;
        current_sim_time_s = 0.0;
        completed_task_ids.clear();
        failed_task_ids.clear();

        event_dispatcher.dispatch("PROTOCOL_STARTED", { time = current_sim_time_s });

        local total_tasks = task_graph.nodes.len();
        while (completed_task_ids.len() < total_tasks) {
            local ready_tasks = get_ready_tasks();
            if (ready_tasks.len() == 0) {
                if (completed_task_ids.len() + failed_task_ids.len() >= total_tasks) {
                    break;
                }
                // Deadlock or unresolvable dependencies
                throw ResourceDeadlockError("ENGINE_STALL", "No ready tasks could acquire locks");
            }

            foreach (task in ready_tasks) {
                // Acquire locks
                foreach (res in task.required_resources) {
                    lock_manager.acquire(res, task.id);
                }

                task.status = TaskStatus.RUNNING;
                event_dispatcher.dispatch("TASK_STARTED", { task_id = task.id, name = task.name });

                try {
                    // Checkpoint state prior to step execution
                    local cp = state_store.save_checkpoint("task_" + task.id);

                    if (task.action_closure != null) {
                        local action_fn = task.action_closure;
                        action_fn();
                    }

                    // Advance simulated clock
                    current_sim_time_s += task.duration_s;
                    task.status = TaskStatus.COMPLETED;
                    completed_task_ids[task.id] <- true;

                    state_store.commit_checkpoint(cp);
                    event_dispatcher.dispatch("TASK_COMPLETED", { task_id = task.id, duration = task.duration_s });
                    lock_manager.release_all_for_task(task.id);
                } catch (err) {
                    lock_manager.release_all_for_task(task.id);
                    task.status = TaskStatus.FAILED;
                    failed_task_ids[task.id] <- true;
                    event_dispatcher.dispatch("TASK_FAILED", { task_id = task.id, error = err });
                    // Rollback state
                    state_store.rollback();
                    is_running = false;
                    throw err;
                }
            }
        }

        is_running = false;
        event_dispatcher.dispatch("PROTOCOL_COMPLETED", { total_time = current_sim_time_s, tasks = completed_task_ids.len() });
        return current_sim_time_s;
    }
}
