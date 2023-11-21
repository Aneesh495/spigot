// Spigot Terminal Deck Layout Visualizer
// Renders the multi-slot deck grid, installed labware, and liquid inventory status.

dofile("ui/ansi_terminal.nut");
dofile("deck/deck_layout.nut");

class DeckRenderer {
    deck_layout = null;
    use_colors = true;

    constructor(layout, colors = true) {
        deck_layout = layout;
        use_colors = colors;
    }

    // Renders the deck grid to a formatted string.
    function render_deck_string() {
        local rows = deck_layout.grid_rows;
        local cols = deck_layout.grid_cols;
        local cell_w = 26;

        local out = "\n" + ansi_color("=== " + deck_layout.name + " ===", AnsiColor.BOLD + AnsiColor.BRIGHT_WHITE, use_colors) + "\n\n";

        // Top border
        local border = "+";
        for (local c = 0; c < cols; c++) {
            for (local i = 0; i < cell_w; i++) border += "-";
            border += "+";
        }
        out += border + "\n";

        // Render each row of slots from top (row 0) to bottom (row rows-1)
        for (local r = rows - 1; r >= 0; r--) {
            // Line 1: Slot ID and Label
            local line_id = "|";
            for (local c = 0; c < cols; c++) {
                local slot_id = (r * cols) + c + 1;
                local slot = deck_layout.get_slot(slot_id);
                local title = " Slot " + slot_id;
                local title_padded = ansi_pad_right(title, cell_w);
                line_id += ansi_color(title_padded, AnsiColor.BRIGHT_YELLOW, use_colors) + "|";
            }
            out += line_id + "\n";

            // Line 2: Labware Name or Empty
            local line_lw = "|";
            for (local c = 0; c < cols; c++) {
                local slot_id = (r * cols) + c + 1;
                local slot = deck_layout.get_slot(slot_id);
                local lw_name = slot.is_occupied() ? (" " + slot.installed_labware.name) : " [Empty]";
                if (lw_name.len() > cell_w) lw_name = lw_name.slice(0, cell_w - 3) + "...";
                local padded = ansi_pad_right(lw_name, cell_w);
                local col = slot.is_occupied() ? AnsiColor.BRIGHT_GREEN : AnsiColor.GRAY;
                line_lw += ansi_color(padded, col, use_colors) + "|";
            }
            out += line_lw + "\n";

            // Line 3: Volume Summary
            local line_vol = "|";
            for (local c = 0; c < cols; c++) {
                local slot_id = (r * cols) + c + 1;
                local slot = deck_layout.get_slot(slot_id);
                local vol_str = " ";
                if (slot.is_occupied()) {
                    local tot_vol = slot.installed_labware.get_total_volume_ul();
                    vol_str = " Vol: " + tot_vol.tointeger() + " uL";
                }
                local padded = ansi_pad_right(vol_str, cell_w);
                line_vol += ansi_color(padded, AnsiColor.CYAN, use_colors) + "|";
            }
            out += line_vol + "\n";

            out += border + "\n";
        }

        return out;
    }

    function print_deck() {
        ::print(render_deck_string());
    }
}
