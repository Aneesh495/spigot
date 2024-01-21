// Spigot Quickstart Example
// Demonstrates minimal setup for running an automated serial dilution assay.

dofile("protocols/serial_dilution.nut");
dofile("analysis/audit_manifest.nut");
dofile("ui/deck_renderer.nut");

::print("=== Spigot Liquid Handling Workstation: Quickstart ===\n");

// 1. Instantiate the automated 12-point serial dilution protocol
local protocol = SerialDilutionProtocol();

// 2. Execute the protocol (sets up deck, transfers diluent, serial transfers, mixing)
protocol.run();

// 3. Render the workstation deck layout
local renderer = DeckRenderer(protocol.deck, true);
renderer.print_deck();

// 4. Generate and display the execution audit manifest
local manifest = AuditManifest("QuickstartSerialDilution");
manifest.complete(protocol);
::print(manifest.generate_summary_text() + "\n");
