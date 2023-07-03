// Spigot Structured Logging Subsystem
// Provides multi-level logging, ANSI color styling, timestamping, and memory audit sinks.

// Global log level constants registered in root table
::LogLevel <- {
    TRACE = 0,
    DEBUG = 1,
    INFO  = 2,
    WARN  = 3,
    ERROR = 4,
    AUDIT = 5
};

class Logger {
    level = LogLevel.INFO;
    subsystem = "ROOT";
    use_colors = true;
    buffer = null; // In-memory ring buffer for test inspection
    max_buffer_size = 500;

    constructor(sub = "ROOT", lvl = LogLevel.INFO, colors = true) {
        subsystem = sub;
        level = lvl;
        use_colors = colors;
        buffer = [];
    }

    function set_level(lvl) {
        level = lvl;
    }

    function set_colors(enable) {
        use_colors = enable;
    }

    function get_level_name(lvl) {
        switch (lvl) {
            case LogLevel.TRACE: return "TRACE";
            case LogLevel.DEBUG: return "DEBUG";
            case LogLevel.INFO:  return "INFO";
            case LogLevel.WARN:  return "WARN";
            case LogLevel.ERROR: return "ERROR";
            case LogLevel.AUDIT: return "AUDIT";
            default:             return "UNKNOWN";
        }
    }

    function get_level_color(lvl) {
        if (!use_colors) return "";
        switch (lvl) {
            case LogLevel.TRACE: return "\x1b[90m"; // Gray
            case LogLevel.DEBUG: return "\x1b[36m"; // Cyan
            case LogLevel.INFO:  return "\x1b[32m"; // Green
            case LogLevel.WARN:  return "\x1b[33m"; // Yellow
            case LogLevel.ERROR: return "\x1b[31m"; // Red
            case LogLevel.AUDIT: return "\x1b[35m"; // Magenta
            default:             return "\x1b[0m";
        }
    }

    function log(lvl, msg, extra_sub = null) {
        if (lvl < level) {
            return;
        }

        local sub_name = (extra_sub != null) ? extra_sub : subsystem;
        local lvl_name = get_level_name(lvl);
        local color_prefix = get_level_color(lvl);
        local reset = use_colors ? "\x1b[0m" : "";

        local entry = {
            level = lvl,
            level_name = lvl_name,
            subsystem = sub_name,
            message = msg,
            time = time()
        };

        if (buffer.len() >= max_buffer_size) {
            buffer.remove(0);
        }
        buffer.append(entry);

        local formatted = color_prefix + "[" + lvl_name + "] [" + sub_name + "] " + msg + reset + "\n";
        ::print(formatted);
    }

    function trace(msg, sub = null) {
        log(LogLevel.TRACE, msg, sub);
    }

    function debug(msg, sub = null) {
        log(LogLevel.DEBUG, msg, sub);
    }

    function info(msg, sub = null) {
        log(LogLevel.INFO, msg, sub);
    }

    function warn(msg, sub = null) {
        log(LogLevel.WARN, msg, sub);
    }

    function error(msg, sub = null) {
        log(LogLevel.ERROR, msg, sub);
    }

    function audit(msg, sub = null) {
        log(LogLevel.AUDIT, msg, sub);
    }

    function get_buffer_count() {
        return buffer.len();
    }

    function get_last_entry() {
        if (buffer.len() == 0) return null;
        return buffer[buffer.len() - 1];
    }

    function clear_buffer() {
        buffer.clear();
    }
}

// Global shared default logger instance
local default_spigot_logger = Logger("SPIGOT", LogLevel.INFO, true);

function spigot_log_info(msg, sub = "SPIGOT") {
    default_spigot_logger.info(msg, sub);
}

function spigot_log_warn(msg, sub = "SPIGOT") {
    default_spigot_logger.warn(msg, sub);
}

function spigot_log_error(msg, sub = "SPIGOT") {
    default_spigot_logger.error(msg, sub);
}
