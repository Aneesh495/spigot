// Spigot Directed Acyclic Graph (DAG) Task Scheduler
// Provides dependency graph management, topological sorting, and cycle detection.

dofile("scheduler/task_node.nut");
dofile("core/errors.nut");

class TaskGraph {
    nodes = null; // Table: task_id -> TaskNode
    adj_list = null; // Table: task_id -> Array of dependent child task IDs
    rev_adj = null; // Table: task_id -> Array of parent prerequisite task IDs

    constructor() {
        nodes = {};
        adj_list = {};
        rev_adj = {};
    }

    function add_task(task_node) {
        nodes[task_node.id] <- task_node;
        if (!adj_list.rawin(task_node.id)) adj_list[task_node.id] <- [];
        if (!rev_adj.rawin(task_node.id)) rev_adj[task_node.id] <- [];
    }

    function add_dependency(child_task_id, parent_task_id) {
        if (!nodes.rawin(child_task_id) || !nodes.rawin(parent_task_id)) {
            throw "TaskNotFoundException: Both tasks must exist in graph to add dependency.";
        }
        nodes[child_task_id].add_dependency(parent_task_id);
        adj_list[parent_task_id].append(child_task_id);
        rev_adj[child_task_id].append(parent_task_id);
    }

    function get_task(task_id) {
        if (!nodes.rawin(task_id)) {
            throw "TaskNotFoundException: Task '" + task_id + "' not found in graph.";
        }
        return nodes[task_id];
    }

    function get_children(task_id) {
        return adj_list.rawin(task_id) ? adj_list[task_id] : [];
    }

    function get_parents(task_id) {
        return rev_adj.rawin(task_id) ? rev_adj[task_id] : [];
    }

    // Performs topological sort using Kahn's algorithm.
    // Throws DependencyCycleError if a cycle is detected.
    function topological_sort() {
        local in_degree = {};
        foreach (id, n in nodes) {
            in_degree[id] <- rev_adj[id].len();
        }

        local zero_in_queue = [];
        foreach (id, deg in in_degree) {
            if (deg == 0) {
                zero_in_queue.append(id);
            }
        }

        local sorted = [];
        while (zero_in_queue.len() > 0) {
            local curr_id = zero_in_queue.remove(0);
            sorted.append(nodes[curr_id]);

            local children = adj_list[curr_id];
            foreach (child_id in children) {
                in_degree[child_id]--;
                if (in_degree[child_id] == 0) {
                    zero_in_queue.append(child_id);
                }
            }
        }

        if (sorted.len() != nodes.len()) {
            throw DependencyCycleError("One or more cycles detected among task dependencies");
        }

        return sorted;
    }

    function get_root_tasks() {
        local roots = [];
        foreach (id, parents in rev_adj) {
            if (parents.len() == 0) {
                roots.append(nodes[id]);
            }
        }
        return roots;
    }

    function get_terminal_tasks() {
        local terminals = [];
        foreach (id, children in adj_list) {
            if (children.len() == 0) {
                terminals.append(nodes[id]);
            }
        }
        return terminals;
    }
}
