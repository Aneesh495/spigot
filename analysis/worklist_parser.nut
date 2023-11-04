// Spigot CSV and Hamilton/Tecan Worklist File Parser
// Parses delimited pipetting worklists, normalizes well identifiers, and validates volume bounds.

class WorklistParser {
    delimiter = ",";

    constructor(delim = ",") {
        delimiter = delim;
    }

    // Splits a string by delimiter.
    function split_string(str, delim) {
        local tokens = [];
        local start = 0;
        local len = str.len();
        for (local i = 0; i < len; i++) {
            if (str.slice(i, i + 1) == delim) {
                tokens.append(str.slice(start, i));
                start = i + 1;
            }
        }
        if (start <= len) {
            tokens.append(str.slice(start, len));
        }
        return tokens;
    }

    // Trims whitespace from both ends of a string.
    function trim(str) {
        local start = 0;
        local len = str.len();
        while (start < len && (str.slice(start, start + 1) == " " || str.slice(start, start + 1) == "\t")) {
            start++;
        }
        local end = len - 1;
        while (end >= start && (str.slice(end, end + 1) == " " || str.slice(end, end + 1) == "\t" || str.slice(end, end + 1) == "\r" || str.slice(end, end + 1) == "\n")) {
            end--;
        }
        if (start > end) return "";
        return str.slice(start, end + 1);
    }

    // Parses raw CSV text into an array of transfer commands.
    // Schema: SourcePlate, SourceWell, DestPlate, DestWell, Volume, LiquidClass
    function parse_csv(csv_text) {
        local lines = split_string(csv_text, "\n");
        local transfers = [];
        local line_num = 0;

        foreach (raw_line in lines) {
            line_num++;
            local line = trim(raw_line);
            // Skip empty lines or comments
            if (line.len() == 0 || line.slice(0, 1) == "#") {
                continue;
            }

            local tokens = split_string(line, delimiter);
            if (tokens.len() < 5) {
                throw "WorklistParseException: Line " + line_num + " has invalid token count (expected at least 5): '" + line + "'";
            }

            // Skip header row if present
            local first_token_lower = trim(tokens[0]).tolower();
            if (first_token_lower == "sourceplate" || first_token_lower == "source_plate" || first_token_lower == "source plate") {
                continue;
            }

            local src_plate = trim(tokens[0]);
            local src_well = trim(tokens[1]);
            local dest_plate = trim(tokens[2]);
            local dest_well = trim(tokens[3]);
            local vol = trim(tokens[4]).tofloat();
            local lclass = (tokens.len() >= 6) ? trim(tokens[5]) : "Standard_Aqueous";

            if (vol <= 0.0) {
                throw "InvalidVolumeException: Line " + line_num + " has non-positive volume: " + vol;
            }

            transfers.append({
                source_plate = src_plate,
                source_well = src_well,
                dest_plate = dest_plate,
                dest_well = dest_well,
                volume_ul = vol,
                liquid_class = lclass,
                line = line_num
            });
        }

        return transfers;
    }
}
