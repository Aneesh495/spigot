// Unit tests for logging, event dispatching, and state checkpointing

dofile("tests/assert.nut");
dofile("core/logging.nut");
dofile("core/events.nut");
dofile("core/state.nut");

local suite = TestSuite("Core Infrastructure (Logging, Events, State) Test Suite");

// 1. Logger tests
local log = Logger("TEST", LogLevel.DEBUG, false);
log.debug("Debug message");
log.info("Info message");
log.warn("Warning message");
log.error("Error message");

suite.assert_equal(log.get_buffer_count(), 4, "Logger recorded 4 entries");
local last_entry = log.get_last_entry();
suite.assert_equal(last_entry.level_name, "ERROR", "Last entry is ERROR");
suite.assert_equal(last_entry.subsystem, "TEST", "Subsystem is TEST");

// Test level filtering
log.set_level(LogLevel.WARN);
log.info("This info message should be ignored");
suite.assert_equal(log.get_buffer_count(), 4, "Buffer count unchanged after filtered log");

// 2. EventDispatcher tests
local dispatcher = EventDispatcher();
local received_events = [];

function test_handler(event) {
    received_events.append(event);
}

dispatcher.subscribe("TEST_EVENT", test_handler);
dispatcher.dispatch("TEST_EVENT", { value = 42, text = "sample" });
dispatcher.dispatch("OTHER_EVENT", { flag = true });

suite.assert_equal(received_events.len(), 1, "Handler received 1 subscribed event");
suite.assert_equal(received_events[0].data.value, 42, "Event payload preserved");
suite.assert_equal(dispatcher.get_event_count(), 2, "Total event history is 2");
suite.assert_equal(dispatcher.get_event_count("TEST_EVENT"), 1, "History for TEST_EVENT is 1");

// Test unsubscribe
dispatcher.unsubscribe("TEST_EVENT", test_handler);
dispatcher.dispatch("TEST_EVENT", { value = 99 });
suite.assert_equal(received_events.len(), 1, "Unsubscribed handler did not receive second event");

// 3. StateStore tests
local store = StateStore({ step = 0, count = 10, items = ["a", "b"] });
suite.assert_equal(store.get_value("step"), 0, "Initial step is 0");

local cp0 = store.save_checkpoint("initial");
store.set_value("step", 1);
store.set_value("count", 25);
suite.assert_equal(store.get_value("step"), 1, "Updated step is 1");
suite.assert_equal(store.get_value("count"), 25, "Updated count is 25");

// Rollback to checkpoint
store.rollback(cp0);
suite.assert_equal(store.get_value("step"), 0, "Step restored to 0 after rollback");
suite.assert_equal(store.get_value("count"), 10, "Count restored to 10 after rollback");

local success = suite.summary();
if (!success) {
    throw "Core infrastructure tests failed.";
}
