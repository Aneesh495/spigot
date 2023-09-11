// Spigot Critical Path Method (CPM) Solver
// Computes Early/Late schedules, total slack, and identifies protocol critical paths.

dofile("scheduler/task_graph.nut");

class CPMSolver {
    task_graph = null;
    project_duration_s = 0.0;
    critical_path = null;

    constructor(graph) {
        task_graph = graph;
        project_duration_s = 0.0;
        critical_path = [];
    }

    // Solves the forward and backward passes of the Critical Path Method.
    function solve() {
        local sorted_nodes = task_graph.topological_sort();
        if (sorted_nodes.len() == 0) return 0.0;

        // 1. Forward Pass (Early Start and Early Finish)
        foreach (node in sorted_nodes) {
            local max_parent_ef = 0.0;
            local parents = task_graph.get_parents(node.id);
            foreach (p_id in parents) {
                local p_node = task_graph.get_task(p_id);
                if (p_node.early_finish > max_parent_ef) {
                    max_parent_ef = p_node.early_finish;
                }
            }
            node.early_start = max_parent_ef;
            node.early_finish = node.early_start + node.duration_s;
        }

        // Project duration is max early finish of terminal tasks
        local terminals = task_graph.get_terminal_tasks();
        project_duration_s = 0.0;
        foreach (t_node in terminals) {
            if (t_node.early_finish > project_duration_s) {
                project_duration_s = t_node.early_finish;
            }
        }

        // 2. Backward Pass (Late Start and Late Finish)
        // Reverse topological order
        for (local i = sorted_nodes.len() - 1; i >= 0; i--) {
            local node = sorted_nodes[i];
            local children = task_graph.get_children(node.id);
            if (children.len() == 0) {
                node.late_finish = project_duration_s;
            } else {
                local min_child_ls = 1e12;
                foreach (c_id in children) {
                    local c_node = task_graph.get_task(c_id);
                    if (c_node.late_start < min_child_ls) {
                        min_child_ls = c_node.late_start;
                    }
                }
                node.late_finish = min_child_ls;
            }
            node.late_start = node.late_finish - node.duration_s;
            node.total_slack = node.late_start - node.early_start;
        }

        // 3. Extract Critical Path
        critical_path = [];
        foreach (node in sorted_nodes) {
            if (node.is_critical()) {
                critical_path.append(node);
            }
        }

        return project_duration_s;
    }

    function get_critical_path() {
        return critical_path;
    }
}
