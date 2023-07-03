// Spigot Event Dispatcher and Pub/Sub Subsystem
// Decouples deck state changes, fluidic transfers, and sensor telemetry from UI and analysis.

class EventDispatcher {
    listeners = null;
    history = null;
    max_history = 1000;
    is_paused = false;

    constructor() {
        listeners = {};
        history = [];
        is_paused = false;
    }

    // Subscribes a callable handler to a specific event name.
    function subscribe(event_name, handler) {
        if (!listeners.rawin(event_name)) {
            listeners[event_name] <- [];
        }
        listeners[event_name].append(handler);
    }

    // Removes a previously subscribed handler.
    function unsubscribe(event_name, handler) {
        if (!listeners.rawin(event_name)) return;
        local list = listeners[event_name];
        for (local i = 0; i < list.len(); i++) {
            if (list[i] == handler) {
                list.remove(i);
                return;
            }
        }
    }

    // Dispatches an event with an associated payload dictionary.
    function dispatch(event_name, payload = null) {
        local event_record = {
            name = event_name,
            timestamp = time(),
            data = (payload != null) ? payload : {}
        };

        if (history.len() >= max_history) {
            history.remove(0);
        }
        history.append(event_record);

        if (is_paused) {
            return;
        }

        if (listeners.rawin(event_name)) {
            local list = listeners[event_name];
            for (local i = 0; i < list.len(); i++) {
                local fn = list[i];
                fn(event_record);
            }
        }
    }

    // Clears all event history and listener bindings.
    function reset() {
        listeners.clear();
        history.clear();
        is_paused = false;
    }

    function pause() {
        is_paused = true;
    }

    function resume_dispatcher() {
        is_paused = false;
    }

    function get_event_count(event_name = null) {
        if (event_name == null) {
            return history.len();
        }
        local count = 0;
        foreach (evt in history) {
            if (evt.name == event_name) {
                count++;
            }
        }
        return count;
    }

    function get_last_event(event_name = null) {
        if (history.len() == 0) return null;
        if (event_name == null) {
            return history[history.len() - 1];
        }
        for (local i = history.len() - 1; i >= 0; i--) {
            if (history[i].name == event_name) {
                return history[i];
            }
        }
        return null;
    }
}
