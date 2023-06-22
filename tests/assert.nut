// Spigot Test Assertion Framework
// Provides lightweight unit test assertions, counters, and reporting for Squirrel test runners.

class TestSuite {
    name = "";
    passed = 0;
    failed = 0;
    failures = null;

    constructor(suite_name) {
        name = suite_name;
        passed = 0;
        failed = 0;
        failures = [];
    }

    function assert_true(condition, message = "Expected condition to be true") {
        if (condition) {
            passed++;
        } else {
            failed++;
            local fail_msg = "[FAIL] " + name + ": " + message;
            failures.append(fail_msg);
            ::print(fail_msg + "\n");
        }
    }

    function assert_false(condition, message = "Expected condition to be false") {
        assert_true(!condition, message);
    }

    function assert_equal(actual, expected, message = "") {
        local desc = (message == "") ? ("Expected " + expected + ", got " + actual) : message;
        assert_true(actual == expected, desc);
    }

    function assert_near(actual, expected, tolerance = 1e-5, message = "") {
        local diff = abs(actual - expected);
        local desc = (message == "") ? ("Expected ~" + expected + ", got " + actual + " (diff=" + diff + ")") : message;
        assert_true(diff <= tolerance, desc);
    }

    function summary() {
        local total = passed + failed;
        local status = (failed == 0) ? "[PASS]" : "[FAIL]";
        ::print(status + " " + name + ": " + passed + "/" + total + " assertions passed.\n");
        return failed == 0;
    }
}
