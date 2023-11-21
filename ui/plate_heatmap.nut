// Spigot Microplate Concentration and Volume Heatmap Visualizer
// Renders 8x12 (96-well) or 16x24 (384-well) microplate grids with color-coded density glyphs.

dofile("ui/ansi_terminal.nut");
dofile("deck/plate.nut");

class PlateHeatmap {
    plate = null; // Labware
    use_colors = true;

    constructor(target_plate, colors = true) {
        plate = target_plate;
        use_colors = colors;
    }

    // Renders the microplate well matrix with volume level glyphs.
    function render_volume_heatmap() {
        local rows = plate.rows;
        local cols = plate.cols;
        local letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

        local out = "\n" + ansi_color("--- Plate Heatmap: " + plate.name + " ---", AnsiColor.BOLD + AnsiColor.BRIGHT_WHITE, use_colors) + "\n";

        // Column header numbers
        local header = "   ";
        for (local c = 1; c <= cols; c++) {
            header += ansi_pad_left(c + "", 4);
        }
        out += header + "\n";

        for (local r = 0; r < rows; r++) {
            local row_letter = letters.slice(r, r + 1);
            local line = ansi_color(row_letter + " |", AnsiColor.BRIGHT_YELLOW, use_colors);

            for (local c = 1; c <= cols; c++) {
                local w = plate.get_well(row_letter + c);
                local vol = w.volume_ul;

                local glyph = " ."; // Empty
                local col = AnsiColor.GRAY;

                if (vol > 0.0) {
                    local frac = vol / w.geometry.max_volume_ul;
                    if (frac < 0.25) {
                        glyph = " o";
                        col = AnsiColor.CYAN;
                    } else if (frac < 0.65) {
                        glyph = " O";
                        col = AnsiColor.BRIGHT_GREEN;
                    } else {
                        glyph = " @";
                        col = AnsiColor.BRIGHT_MAGENTA;
                    }
                }

                line += ansi_color(ansi_pad_left(glyph, 4), col, use_colors);
            }
            out += line + "\n";
        }

        out += "\nLegend: " + ansi_color(". Empty", AnsiColor.GRAY, use_colors) + "  " +
               ansi_color("o Low (<25%)", AnsiColor.CYAN, use_colors) + "  " +
               ansi_color("O Med (<65%)", AnsiColor.BRIGHT_GREEN, use_colors) + "  " +
               ansi_color("@ High (>=65%)", AnsiColor.BRIGHT_MAGENTA, use_colors) + "\n\n";

        return out;
    }

    function print_heatmap() {
        ::print(render_volume_heatmap());
    }
}
