// Unit tests for Scheduler, DAG Topological Sort, CPM, and Execution Engine

dofile("tests/assert.nut");
dofile("scheduler/resource_lock.nut");
dofile("scheduler/task_node.nut");
dofile("scheduler/task_graph.nut");
dofile("scheduler/cpm_solver.nut");
dofile("scheduler/tip_optimizer.nut");
dofile("scheduler/execution_engine.nut");

local suite = TestSuite("Scheduler and Task Graph Subsystem Test Suite");

// 1. ResourceLockManager
local rlm = ResourceLockManager();
suite.assert_true(rlm.acquire("GANTRY", "task_1"), "Task 1 acquires GANTRY");
suite.assert_false(rlm.acquire("GANTRY", "task_2"), "Task 2 fails to acquire locked GANTRY");
rlm.release("GANTRY", "task_1");
suite.assert_true(rlm.acquire("GANTRY", "task_2"), "Task 2 acquires GANTRY after release");
rlm.release_all_for_task("task_2");
suite.assert_false(rlm.is_locked("GANTRY"), "GANTRY unlocked after release_all");

// 2. TaskGraph and Topological Sort
local graph = TaskGraph();
local t1 = TaskNode("T1", "Mount Tips", 3.0, ["GANTRY"]);
local t2 = TaskNode("T2", "Aspirate Master Mix", 5.0, ["GANTRY", "SLOT_1"]);
local t3 = TaskNode("T3", "Dispense into Plate", 6.0, ["GANTRY", "SLOT_2"]);
local t4 = TaskNode("T4", "Thermal Incubation", 60.0, ["SHAKER"]);

graph.add_task(t1);
graph.add_task(t2);
graph.add_task(t3);
graph.add_task(t4);

graph.add_dependency("T2", "T1"); // T2 depends on T1
graph.add_dependency("T3", "T2"); // T3 depends on T2
graph.add_dependency("T4", "T3"); // T4 depends on T3

local sorted = graph.topological_sort();
suite.assert_equal(sorted.len(), 4, "Topological sort returns 4 tasks");
suite.assert_equal(sorted[0].id, "T1", "First task is T1");
suite.assert_equal(sorted[1].id, "T2", "Second task is T2");
suite.assert_equal(sorted[2].id, "T3", "Third task is T3");
suite.assert_equal(sorted[3].id, "T4", "Fourth task is T4");

// 3. Cycle Detection
local cyclic_graph = TaskGraph();
cyclic_graph.add_task(TaskNode("C1", "Step 1", 2.0));
cyclic_graph.add_task(TaskNode("C2", "Step 2", 2.0));
cyclic_graph.add_task(TaskNode("C3", "Step 3", 2.0));
cyclic_graph.add_dependency("C2", "C1");
cyclic_graph.add_dependency("C3", "C2");
cyclic_graph.add_dependency("C1", "C3"); // Creates cycle C1 -> C2 -> C3 -> C1!

local caught_cycle = false;
try {
    cyclic_graph.topological_sort();
} catch (e) {
    caught_cycle = true;
    suite.assert_true(e instanceof DependencyCycleError, "DependencyCycleError thrown on cycle");
}
suite.assert_true(caught_cycle, "Cyclic dependency detected and aborted");

// 4. Critical Path Method (CPM)
local cpm = CPMSolver(graph);
local proj_dur = cpm.solve();
// Sequential path: 3.0 + 5.0 + 6.0 + 60.0 = 74.0 s
suite.assert_near(proj_dur, 74.0, 1e-4, "CPM total duration is 74.0 s");

local crit = cpm.get_critical_path();
suite.assert_equal(crit.len(), 4, "All tasks on linear chain are on critical path");
suite.assert_near(t1.total_slack, 0.0, 1e-4, "T1 has zero slack");
suite.assert_near(t4.total_slack, 0.0, 1e-4, "T4 has zero slack");

// 5. TipOptimizer
local opt = TipOptimizer();
local tip_spec = { length = 51.2, volume = 200.0 };
opt.register_tip_loaded(0, tip_spec, "Water");

suite.assert_true(opt.can_reuse_tip(0, "Water", true), "Air dispense of pure Water can be reused");
suite.assert_false(opt.can_reuse_tip(0, "PBS", true), "Different reagent cannot reuse tip");

opt.mark_tip_immersed(0);
suite.assert_false(opt.can_reuse_tip(0, "Water", true), "Immersed tip cannot be reused for Water");

// 6. ExecutionEngine
local exec_graph = TaskGraph();
local counter = 0;

local step1 = TaskNode("S1", "Initialize Deck", 1.0, [], function() { counter += 10; });
local step2 = TaskNode("S2", "Transfer Reagents", 2.0, ["GANTRY"], function() { counter += 20; });
exec_graph.add_task(step1);
exec_graph.add_task(step2);
exec_graph.add_dependency("S2", "S1");

local engine = ExecutionEngine(exec_graph);
local total_time = engine.run_all();

suite.assert_equal(counter, 30, "Both task closures executed successfully");
suite.assert_near(total_time, 3.0, 1e-4, "Engine simulated time is 3.0 s");

local success = suite.summary();
if (!success) {
    throw "Scheduler tests failed.";
}
