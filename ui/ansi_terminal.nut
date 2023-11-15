// Spigot ANSI Terminal Styling and Box Formatting
// Provides color constants, styles, and terminal text layout helpers.

::AnsiColor <- {
    RESET      = "\x1b[0m",
    BOLD       = "\x1b[1m",
    DIM        = "\x1b[2m",
    UNDERLINE  = "\x1b[4m",

    BLACK      = "\x1b[30m",
    RED        = "\x1b[31m",
    GREEN      = "\x1b[32m",
    YELLOW     = "\x1b[33m",
    BLUE       = "\x1b[34m",
    MAGENTA    = "\x1b[35m",
    CYAN       = "\x1b[36m",
    WHITE      = "\x1b[37m",

    GRAY       = "\x1b[90m",
    BRIGHT_RED = "\x1b[91m",
    BRIGHT_GREEN = "\x1b[92m",
    BRIGHT_YELLOW = "\x1b[93m",
    BRIGHT_BLUE = "\x1b[94m",
    BRIGHT_MAGENTA = "\x1b[95m",
    BRIGHT_CYAN = "\x1b[96m",
    BRIGHT_WHITE = "\x1b[97m",

    BG_BLUE    = "\x1b[44m",
    BG_GRAY    = "\x1b[100m"
};

function ansi_color(text, color_code, enable = true) {
    if (!enable) return text;
    return color_code + text + AnsiColor.RESET;
}

function ansi_pad_right(str, target_len) {
    local s = "" + str;
    while (s.len() < target_len) {
        s += " ";
    }
    return s;
}

function ansi_pad_left(str, target_len) {
    local s = "" + str;
    while (s.len() < target_len) {
        s = " " + s;
    }
    return s;
}
