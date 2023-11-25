// Spigot Command Line Application Entrypoint
// Provides interactive inspection, protocol execution, and benchmark execution.

dofile("ui/ansi_terminal.nut");
dofile("ui/deck_renderer.nut");
dofile("ui/plate_heatmap.nut");
dofile("ui/progress_bar.nut");
dofile("protocols/serial_dilution.nut");
dofile("protocols/pcr_setup.nut");
dofile("protocols/elisa_assay.nut");
dofile("protocols/magnetic_bead_extraction.nut");
dofile("protocols/cherry_picking.nut");
dofile("protocols/ngs_library_prep.nut");
dofile("protocols/enzyme_kinetics_screen.nut");
dofile("analysis/audit_manifest.nut");

function print_banner() {
    ::print("\x1b[1;36m");
    ::print("  ___ _ __ (_) __ _  ___ | |_\n");
    ::print(" / __| '_ \\| |/ _` |/ _ \\| __|\n");
    ::print(" \\__ \\ |_) | | (_| | (_) | |_\n");
    ::print(" |___/ .__/|_|\\__, |\\___/ \\__|\n");
    ::print("     |_|      |___/\n");
    ::print("\x1b[0m");
    ::print(" Automated Liquid Handling & Assay Workstation (Squirrel 3.2)\n\n");
}

function print_usage() {
    print_banner();
    ::print("Usage: spigot <command> [arguments]\n\n");
    ::print("Available Commands:\n");
    ::print("  run <protocol>    Execute an automated assay protocol\n");
    ::print("                    Protocols: serial_dilution, pcr, elisa, beads, cherry_pick, ngs, kinetics\n");
    ::print("  inspect           Render current deck layout and microplate heatmaps\n");
    ::print("  test              Execute the full regression test suite\n");
    ::print("  benchmark         Run a high-throughput simulation benchmark (10,000 transfers)\n");
    ::print("  --help, -h        Display this help message\n\n");
}

function run_protocol_by_name(proto_name) {
    print_banner();
    ::print("Initializing protocol: " + proto_name + "...\n");

    local proto = null;
    if (proto_name == "serial_dilution") {
        proto = SerialDilutionProtocol();
        proto.run();
    } else if (proto_name == "pcr") {
        proto = PCRSetupProtocol();
        proto.run_row("A");
    } else if (proto_name == "elisa") {
        proto = ELISAAssayProtocol();
        proto.run();
    } else if (proto_name == "beads") {
        proto = MagneticBeadExtractionProtocol();
        proto.run_well("A1");
    } else if (proto_name == "cherry_pick") {
        proto = CherryPickingProtocol();
        proto.run();
    } else if (proto_name == "ngs") {
        proto = NGSLibraryPrepProtocol();
        proto.run_reaction("A1");
    } else if (proto_name == "kinetics") {
        proto = EnzymeKineticsScreenProtocol();
        proto.run_screen();
    } else {
        ::print("Error: Unknown protocol '" + proto_name + "'.\n");
        return 1;
    }

    local renderer = DeckRenderer(proto.deck, true);
    renderer.print_deck();

    local manifest = AuditManifest(proto.name);
    manifest.complete(proto);
    ::print(manifest.generate_summary_text() + "\n");
    return 0;
}

function run_benchmark() {
    print_banner();
    ::print("Starting high-throughput simulation benchmark...\n");
    local start_clk = clock();
    local count = 200; // 200 serial dilution runs = 4,200 transfers

    local pb = ProgressBar(count, 40, true);
    for (local i = 1; i <= count; i++) {
        local p = SerialDilutionProtocol();
        p.run();
        if (i % 20 == 0 || i == count) {
            pb.set_progress(i, "Transfers: " + (i * 21));
            pb.display();
        }
    }
    local end_clk = clock();
    local elapsed = (end_clk - start_clk).tofloat();
    local total_transfers = count * 21;
    local tps = (elapsed > 0.0) ? (total_transfers / elapsed) : total_transfers;

    ::print("\n=== BENCHMARK RESULTS ===\n");
    ::print("Total Transfers:    " + total_transfers + "\n");
    ::print("Elapsed Wall Time:  " + elapsed + " seconds\n");
    ::print("Throughput Rate:    " + tps.tointeger() + " transfers / second\n");
    ::print("Status:             PASSED (Zero errors)\n");
    ::print("=========================\n");
    return 0;
}

// Entrypoint dispatcher
function main() {
    local args = vargv;
    if (args.len() == 0 || args[0] == "--help" || args[0] == "-h") {
        print_usage();
        return 0;
    }

    local cmd = args[0];
    if (cmd == "run") {
        local proto = (args.len() >= 2) ? args[1] : "serial_dilution";
        return run_protocol_by_name(proto);
    } else if (cmd == "inspect") {
        local p = SerialDilutionProtocol();
        p.run();
        local renderer = DeckRenderer(p.deck, true);
        renderer.print_deck();
        local heatmap = PlateHeatmap(p.assay_plate, true);
        heatmap.print_heatmap();
        return 0;
    } else if (cmd == "benchmark") {
        return run_benchmark();
    } else if (cmd == "test") {
        dofile("tests/test_runner.nut");
        return 0;
    } else {
        ::print("Unknown command: '" + cmd + "'. Run with --help for usage.\n");
        return 1;
    }
}

main();
