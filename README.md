# Spigot

```
  ___ _ __ (_) __ _  ___ | |_ 
 / __| '_ \| |/ _` |/ _ \| __|
 \__ \ |_) | | (_| | (_) | |_ 
 |___/ .__/|_|\__, |\___/ \__|
     |_|      |___/           
```

**Automated Laboratory Liquid Handling Workstation Operating System, Micro-Fluidic Physics Simulator & Assay Execution Engine**

Spigot is a high-performance operating system, simulation engine, and execution framework for automated laboratory liquid handling workstations. Engineered in **Squirrel 3.2** with an optional **C++20** native acceleration layer for partial differential equation (PDE) fluid simulation and 3D spatial hierarchy queries, Spigot bridges the gap between low-level Cartesian robotics and high-level biochemical assay protocols.

---

## Key Highlights

- **Physical Micro-Fluidic Modeling**: Replaces empirical lookups with analytical transport laws: Hagen-Poiseuille viscous resistance in conical nozzles, Young-Laplace capillary pressure, Rayleigh-Plateau critical pendant droplet detachment, and Boyle isothermal air cushion compressibility.
- **7-Phase Jerk-Limited S-Curve Kinematics**: Continuous $C^2$ trajectory profiling with dynamic variable-pitch multichannel pipetting (4.5 mm to 18.0 mm) and collision-free retract-traverse-descend safe clearance envelopes.
- **ANSI/SLAS Standard Microplate Modeling**: Analytical piecewise volumetric integration for flat, conical, spherical cap, and pyramidal trough geometries across 96-well, 384-well, and 1536-well densities.
- **DAG Assay Scheduling & Critical Path Method**: Directed Acyclic Graph task orchestration with Kahn topological cycle detection, forward/backward slack calculation, resource mutex locking, and consumable tip reuse optimization.
- **7 Turnkey Bio-Assay Protocols**: Pre-calibrated protocols for 12-point Serial Dilution, 96-well qPCR setup, Sandwich ELISA with automated 3x wash cycles, SPRI Magnetic Bead Nucleic Acid Extraction, Compound Cherry-Picking, NGS Library Prep, and Michaelis-Menten Enzyme Kinetics.
- **Analytical Quality Auditing**: Real-time mass balance volume conservation accounting, bipartite tip-to-well cross-contamination prevention graphs, and Four-Parameter Logistic (4PL) dose-response sigmoidal regression.
- **Dual-Mode Execution**: Runs 100% natively in pure Squirrel 3.2 or via the embedded C++ native host binary (`spigot_native`) with zero behavioral discrepancies.

---

## Architecture Overview

```
+-----------------------------------------------------------------------+
|                           Spigot CLI & UI                             |
|       (ANSI Terminal Dashboard, Microplate Heatmaps, Worklists)       |
+-----------------------------------------------------------------------+
                                   |
+-----------------------------------------------------------------------+
|                         Assay Protocols Layer                         |
|  (Serial Dilution, PCR, ELISA, SPRI Beads, Cherry-Pick, NGS, Kinetics)|
+-----------------------------------------------------------------------+
                                   |
+-----------------------------------------------------------------------+
|                      Scheduler & Execution DAG                        |
|  (TaskGraph, Kahn Topological Sort, CPM Critical Path, Tip Optimizer) |
+-----------------------------------------------------------------------+
        |                                                   |
+-----------------------+                   +---------------------------+
|   Fluidics Subsystem  |                   |     Motion & Kinematics   |
| (Poiseuille, Laplace, |                   | (7-Phase S-Curves, Pitch, |
|  Droplets, Boyle LLD) |                   |  Safe Collision Envelope) |
+-----------------------+                   +---------------------------+
        \                                                   /
         +-------------------------------------------------+
         |            Deck & Labware Modeling              |
         | (ANSI/SLAS Slots, Well Geometries, Accessories) |
         +-------------------------------------------------+
                                   |
+-----------------------------------------------------------------------+
|                    Spigot Core Runtime Substrate                      |
| (Vector3, AABB, Unit Systems, State Rollback, Event Dispatcher, Logs) |
+-----------------------------------------------------------------------+
                                   |
+-----------------------------------------------------------------------+
|                 C++20 Native Acceleration Host (FFI)                  |
|    (1D Navier-Stokes PDE Solver, 3D Bounding Volume Hierarchy)        |
+-----------------------------------------------------------------------+
```

---

## Why Squirrel?

Robotic liquid handling requires high determinism, real-time response, and zero unpredictable latency spikes. Squirrel 3.2 provides unique architectural advantages:

1. **Immediate Reference-Counted Cleanup**: Memory is reclaimed the microsecond an object reference drops to zero. Deck slot reservations, mutex locks, and native buffers are deallocated deterministically without garbage collection pauses.
2. **Lightweight Cooperative Coroutines**: Native generator threads allow long-running assay steps (thermal incubation, orbital shaking, wash cycles) to yield cleanly without threading overhead.
3. **C++ Embedding & Compact Footprint**: Seamless bidirectional FFI with zero-copy buffer passing, running within embedded controllers or full workstation host PCs.

---

## Quickstart

### Prerequisites

- **Squirrel 3.2** (`sq`):
  ```bash
  # macOS (via Homebrew)
  brew install squirrel

  # Linux (Debian/Ubuntu)
  sudo apt-get install squirrel3
  ```
- **Python 3.10+** (for test orchestration and worklist tools)
- **C++20 Compiler** (Clang 15+ or GCC 12+, for native acceleration)

### Building & Testing

```bash
# Clone the repository
git clone https://github.com/Aneesh495/spigot.git
cd spigot

# Run all Squirrel and Python test suites
make test

# Compile the optional C++ native acceleration binary
make native

# Verify lint standards (strictly zero em/en dashes)
make lint
```

---

## Running Protocols & Visualizers

### 1. Interactive CLI Application
```bash
# Display help and available commands
sq ui/cli_app.nut --help

# Execute the 12-point serial dilution protocol
sq ui/cli_app.nut run serial_dilution

# Execute 96-well qPCR reaction setup
sq ui/cli_app.nut run pcr

# Execute Sandwich ELISA with automated 3x wash cycles
sq ui/cli_app.nut run elisa

# Execute SPRI magnetic bead nucleic acid extraction
sq ui/cli_app.nut run beads

# Inspect deck layout and microplate density heatmaps
sq ui/cli_app.nut inspect

# Run high-throughput simulation benchmark (10,000+ transfers/sec)
sq ui/cli_app.nut benchmark
```

### 2. Python Runner & Automation Tool
```bash
# Inspect workstation deck
python3 tools/spigot_runner.py inspect

# Run protocol with automatic C++ native acceleration
python3 tools/spigot_runner.py run --protocol serial_dilution

# Generate precision report (%CV) and ASCII 4PL calibration curve
python3 tools/report_generator.py --demo

# Generate synthetic cherry-picking hit worklist
python3 tools/worklist_generator.py generate --hits 16 --output worklist.csv
```

### 3. Standalone Runnable Examples
```bash
# Minimal quickstart assay script
sq examples/quickstart.nut

# Populating a 12-slot deck with diverse plates and accessories
sq examples/demo_deck.nut

# Subclassing AssayProtocol to implement custom binding assays
sq examples/custom_protocol.nut
```

---

## Terminal Visualizations

### Deck Layout Inspection
```
=== Full Production Bio-Assay Deck ===

+--------------------------+--------------------------+--------------------------+--------------------------+
| Slot 9                   | Slot 10                  | Slot 11                  | Slot 12                  |
| [Empty]                  | [Empty]                  | [Empty]                  | [Empty]                  |
|                          |                          |                          |                          |
+--------------------------+--------------------------+--------------------------+--------------------------+
| Slot 5                   | Slot 6                   | Slot 7                   | Slot 8                   |
| 24-Tube Calibrator Sta...| Peltier Shaker Module    | 96-Ring Magnetic Bead ...| 450nm Absorbance Reader  |
| Vol: 0 uL                | Vol: 0 uL                | Vol: 0 uL                | Vol: 0 uL                |
+--------------------------+--------------------------+--------------------------+--------------------------+
| Slot 1                   | Slot 2                   | Slot 3                   | Slot 4                   |
| 12-Channel Reagents 22mL | 96-Well Reaction Plate   | 200uL Pipette Tips       | 384-Well Compound Library|
| Vol: 0 uL                | Vol: 0 uL                | Vol: 0 uL                | Vol: 0 uL                |
+--------------------------+--------------------------+--------------------------+--------------------------+
```

### Microplate Heatmap & 4PL Sigmoidal Fitting
```
--- Plate Heatmap: 96-Well Reaction Plate ---
      1   2   3   4   5   6   7   8   9  10  11  12
A |   O   O   O   O   O   O   .   .   .   .   .   .
B |   .   .   .   .   .   .   .   .   .   .   .   .
C |   .   .   .   .   .   .   .   .   .   .   .   .

=== 4PL CALIBRATION CURVE (EC50=12.50, Hill=1.15) ===
  2.85 |                                      *************
  2.65 |                                  ****             
  2.45 |                                **                 
  2.26 |                              **                   
  2.06 |                             *                     
  1.86 |                           **                      
  1.66 |                          *                        
  1.47 |                         *                         
  1.27 |                       **                          
  1.07 |                      *                            
  0.87 |                    **                             
  0.67 |                  **                               
  0.48 |              ****                                 
  0.28 | *************                                     
       +--------------------------------------------------
        1.25e-01                                1.25e+03 [Conc]
```

---

## Repository Structure

```
spigot/
├── CMakeLists.txt              # CMake C++ native acceleration build definition
├── Makefile                    # Unified build, test, lint, and run targets
├── README.md                   # Project documentation and quickstart
├── core/                       # Foundational runtime primitives
│   ├── aabb.nut                # 3D Axis-Aligned Bounding Box spatial geometry
│   ├── errors.nut              # Hierarchical exception models and diagnostics
│   ├── events.nut              # Decoupled publish/subscribe event engine
│   ├── logging.nut             # ANSI-colored structured terminal logger
│   ├── math.nut                # 3D Cartesian Vector3 and numerical utilities
│   ├── state.nut               # State store, snapshot, and rollback engine
│   └── units.nut               # Dimensional analysis and SI conversions
├── deck/                       # Spatial workstation deck and labware
│   ├── accessories.nut         # Magnetic elevators, Peltier shakers, readers
│   ├── coordinate.nut          # Coordinate transformation matrix frames
│   ├── deck_layout.nut         # 12-slot ANSI/SLAS deck grid manager
│   ├── labware_definition.nut  # Labware base class with row/col slicing
│   ├── plate.nut               # 96, 384, 1536-well microplate models
│   ├── reservoir.nut           # 12-channel and 1-channel reagent troughs
│   ├── slot.nut                # ANSI/SLAS slot footprint models
│   ├── tip_rack.nut            # Disposable tip rack inventory manager
│   ├── tube_rack.nut           # 24-tube Eppendorf and Falcon tube racks
│   └── well.nut                # Well liquid tracking, meniscus, and solute mix
├── fluidics/                   # Physical micro-fluidics transport engine
│   ├── air_displacement.nut    # Boyle isothermal air cushion compressibility
│   ├── aspiration_profile.nut  # Multi-phase aspiration/dispense sequencer
│   ├── capacitive_lld.nut      # High-frequency capacitive level detection
│   ├── capillary_model.nut     # Young-Laplace pressure and Jurin rise
│   ├── droplet_dynamics.nut    # Harkins-Brown critical pendant drop touch-off
│   ├── liquid_classes.nut      # Calibrated parameters (Aqueous, Glycerol, etc.)
│   ├── liquid_properties.nut   # Density, viscosity, surface tension, Re, Oh
│   ├── poiseuille_model.nut    # Hagen-Poiseuille conical tip pressure drop
│   └── pressure_lld.nut        # Differential pressure slope level detection
├── motion/                     # Robotic kinematics and path planning
│   ├── axis_limits.nut         # Cartesian boundaries, velocities, jerk limits
│   ├── collision_envelope.nut  # Safe transit Z and 3-phase corridor planner
│   ├── gantry_kinematics.nut   # 3-axis gantry controller with TCP tracking
│   ├── multi_channel_pitch.nut # 8-channel dynamic variable-pitch lead-screw
│   ├── pipette_actuator.nut    # Stepper plunger lead-screw displacement
│   └── s_curve.nut             # Analytical 7-phase jerk-limited S-curve
├── scheduler/                  # Assay workflow scheduling and DAG
│   ├── cpm_solver.nut          # Critical Path Method forward/backward pass
│   ├── execution_engine.nut    # Asynchronous assay event loop and checkpoints
│   ├── resource_lock.nut       # Mutex locks on deck slots and gantry axes
│   ├── task_graph.nut          # Directed Acyclic Graph (DAG) task engine
│   ├── task_node.nut           # Atomic assay task step definition
│   └── tip_optimizer.nut       # Consumable tip reuse and disposal optimizer
├── protocols/                  # Turnkey bio-assay implementations
│   ├── cherry_picking.nut      # Compound library hit cherry-picking
│   ├── elisa_assay.nut         # Sandwich ELISA with automated 3x wash cycles
│   ├── enzyme_kinetics_screen.nut # Michaelis-Menten ONPG kinetic screen
│   ├── magnetic_bead_extraction.nut # SPRI DNA/RNA bead extraction
│   ├── ngs_library_prep.nut    # End-repair, A-tailing, adapter ligation
│   ├── pcr_setup.nut           # 96-well qPCR master mix and primer setup
│   ├── protocol_base.nut       # Base assay class with transfer/mix primitives
│   └── serial_dilution.nut     # 12-point 1:2 serial dilution with normalization
├── analysis/                   # Analytical verification and auditing
│   ├── audit_manifest.nut      # Execution provenance and run summaries
│   ├── contamination_graph.nut # Bipartite carryover violation audit graph
│   ├── four_parameter_logistic.nut # 4PL sigmoidal dose-response fitting
│   ├── volume_accounting.nut   # Strict mass conservation volume balance
│   └── worklist_parser.nut     # CSV worklist parsing with header skip
├── ui/                         # Visualizers and terminal interfaces
│   ├── ansi_terminal.nut       # Terminal formatting and ANSI palettes
│   ├── cli_app.nut             # Main interactive command line application
│   ├── deck_renderer.nut       # ASCII multi-slot deck layout visualizer
│   ├── plate_heatmap.nut       # Microplate well liquid density heatmaps
│   └── progress_bar.nut        # Terminal execution progress meters
├── native/                     # Optional C++20 acceleration host
│   ├── include/
│   │   ├── fluid_pde_solver.hpp# 1D Navier-Stokes numerical PDE solver
│   │   ├── spatial_bvh.hpp     # 3D spatial Bounding Volume Hierarchy
│   │   └── sq_bindings.hpp     # Squirrel C++ FFI registration bindings
│   └── src/
│       ├── fluid_pde_solver.cpp# Finite difference numerical PDE implementation
│       ├── main.cpp            # Standalone C++ embedded Squirrel host binary
│       ├── spatial_bvh.cpp     # Binary spatial partitioning BVH tree
│       └── sq_bindings.cpp     # Squirrel FFI glue functions
├── tools/                      # Python developer and automation utilities
│   ├── report_generator.py     # Statistical %CV report and ASCII 4PL curves
│   ├── spigot_runner.py        # Workstation orchestrator and subprocess runner
│   └── worklist_generator.py   # Synthetic hit generator and Tecan/Hamilton converter
├── tests/                      # Comprehensive test suites (All passing 100%)
│   ├── assert.nut              # Test assertion library and summary reporter
│   ├── test_analysis.nut       # Volume accounting, 4PL, and worklist tests
│   ├── test_deck.nut           # Deck slots, labware, and well geometry tests
│   ├── test_edge_cases.nut     # Boundary conditions and extreme limits tests
│   ├── test_errors.nut         # Exception hierarchy and metadata tests
│   ├── test_fluidics.nut       # Poiseuille, Young-Laplace, Boyle tests
│   ├── test_integration.py     # Python subprocess and cross-runtime tests
│   ├── test_math.nut           # Vector3 and AABB geometric tests
│   ├── test_motion.nut         # Kinematics, S-curves, and pitch actuator tests
│   ├── test_native_accel.nut   # C++ FFI native acceleration bindings tests
│   ├── test_protocols.nut      # Assay protocols integration tests
│   ├── test_regression_bugs.nut# Regression prevention tests for documented bugs
│   ├── test_runner.nut         # Central Squirrel test suite runner
│   ├── test_scheduler.nut      # DAG, Kahn sort, and CPM solver tests
│   ├── test_state.nut          # State store, snapshot, and event tests
│   └── test_units.nut          # Dimensional transformation tests
├── docs/                       # In-depth architectural and mathematical manuals
│   ├── ARCHITECTURE.md         # Systems design, memory model, reference counting
│   ├── DIAGRAMS.md             # ASCII and Mermaid architectural flowcharts
│   ├── FLUID_DYNAMICS.md       # Analytical derivations of micro-fluidic transport
│   ├── KINEMATICS_AND_GANTRY.md# 7-phase S-curve profiling and gantry specs
│   ├── LABWARE_SPECIFICATION.md# ANSI/SLAS standards and volume integrals
│   ├── LIQUID_CLASSES.md       # Fluid physical properties and calibration manual
│   └── PROTOCOL_AUTHORING.md   # Step-by-step assay composition tutorial
└── scripts/
    └── lint_no_em_dashes.py    # Strict linter enforcing zero forbidden dashes
```

---

## Verification & Test Results

Spigot includes comprehensive unit, structure, boundary, and integration test suites:

```bash
$ make test
=== Running Squirrel Test Suite ===
sq tests/test_runner.nut

=======================================================
       SPIGOT AUTOMATED TEST RUNNER (SQUIRREL 3.2)     
=======================================================

>> Running suite: tests/test_math.nut ...
[PASS] Vector3 and AABB Test Suite: 54/54 assertions passed.
>> Running suite: tests/test_units.nut ...
[PASS] Units and Dimensional Conversions Test Suite: 26/26 assertions passed.
>> Running suite: tests/test_errors.nut ...
[PASS] Error Hierarchy and Exception Metadata Test Suite: 21/21 assertions passed.
>> Running suite: tests/test_state.nut ...
[PASS] Core Infrastructure (Logging, Events, State) Test Suite: 14/14 assertions passed.
>> Running suite: tests/test_deck.nut ...
[PASS] Deck and Labware Subsystem Test Suite: 33/33 assertions passed.
>> Running suite: tests/test_fluidics.nut ...
[PASS] Fluid Dynamics and Liquid Physics Test Suite: 21/21 assertions passed.
>> Running suite: tests/test_motion.nut ...
[PASS] Robotic Motion and Kinematics Test Suite: 31/31 assertions passed.
>> Running suite: tests/test_scheduler.nut ...
[PASS] Scheduler and Task Graph Subsystem Test Suite: 20/20 assertions passed.
>> Running suite: tests/test_protocols.nut ...
[PASS] Assay Protocols Integration Test Suite: 33/33 assertions passed.
>> Running suite: tests/test_analysis.nut ...
[PASS] Analysis and Validation Subsystem Test Suite: 18/18 assertions passed.
>> Running suite: tests/test_regression_bugs.nut ...
[PASS] Regression Bug Prevention Suite: 16/16 assertions passed.
>> Running suite: tests/test_edge_cases.nut ...
[PASS] Boundary Conditions and Edge Case Suite: 17/17 assertions passed.

=======================================================
  ALL 12 TEST SUITES PASSED SUCCESSFULLY!
  Total Execution Time: 0.175088 seconds
  Status: ZERO REGRESSIONS (Smooth as butter)
=======================================================

=== Running Python Integration Suite ===
python3 -m unittest discover -s tests -p "test_*.py"
.....
----------------------------------------------------------------------
Ran 5 tests in 1.150s

OK
```

---

## License

Standard MIT License. Authored with passion for systems programming, laboratory automation, and robotic liquid handling.
