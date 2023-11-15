// Spigot Terminal Progress Bar
// Renders dynamic progress meters with elapsed timings, percentages, and task status.

dofile("ui/ansi_terminal.nut");

class ProgressBar {
    total_steps = 100;
    current_step = 0;
    bar_width = 30;
    task_name = "";
    use_colors = true;

    constructor(total = 100, width = 30, colors = true) {
        total_steps = (total > 0) ? total : 1;
        current_step = 0;
        bar_width = width;
        task_name = "Running";
        use_colors = colors;
    }

    function set_progress(step, task_desc = "") {
        current_step = step;
        if (current_step > total_steps) current_step = total_steps;
        if (task_desc != "") task_name = task_desc;
    }

    function render_string() {
        local frac = current_step.tofloat() / total_steps.tofloat();
        local filled = (frac * bar_width).tointeger();
        if (filled > bar_width) filled = bar_width;

        local bar_str = "";
        for (local i = 0; i < filled; i++) bar_str += "=";
        if (filled < bar_width) bar_str += ">";
        while (bar_str.len() < bar_width) bar_str += " ";

        local pct = (frac * 100.0).tointeger();
        local pct_str = ansi_pad_left(pct + "%", 4);

        local colored_bar = ansi_color("[" + bar_str + "]", AnsiColor.BRIGHT_CYAN, use_colors);
        local colored_pct = ansi_color(pct_str, AnsiColor.BRIGHT_GREEN, use_colors);

        return colored_bar + " " + colored_pct + " " + task_name;
    }

    function display() {
        ::print(render_string() + "\n");
    }
}
