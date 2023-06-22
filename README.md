# Spigot

An automated liquid handling workstation operating system, physics simulator, and assay execution engine.

Spigot models the physics of micro-volume liquid transfers, simulates multi-axis robotic gantry kinematics, and executes high-throughput biological and chemical assay protocols. The core runtime, domain models, protocol definitions, fluid dynamics solvers, and scheduling engines are authored in Squirrel 3.2, with high-performance C++20 native acceleration and Python analytics integration.

```
       +-------------------------------------------------------------+
       |                     Assay Protocols                         |
       |  (Serial Dilution, qPCR, ELISA, Magnetic Beads, NGS Prep)   |
       +------------------------------+------------------------------+
                                      |
       +------------------------------v------------------------------+
       |             Spigot Protocol Execution Engine                |
       |          (Resource Locks, DAG Scheduler, CPM Solver)        |
       +--------------+-------------------------------+--------------+
                      |                               |
       +--------------v---------------+ +-------------v--------------+
       |   Fluidics Physics Engine    | |  Robotic Motion Controller |
       | (Poiseuille, Young-Laplace,  | |  (S-Curve Profiles, Kin-   |
       |  Rayleigh-Plateau, cLLD/pLLD)| |   ematics, BVH Collisions) |
       +--------------+---------------+ +-------------+--------------+
                      |                               |
       +--------------v-------------------------------v--------------+
       |               Virtual Deck & Labware Models                 |
       |   (ANSI/SLAS Microplates, Tip Racks, Reservoirs, Heaters)   |
       +-------------------------------------------------------------+
```

## System Highlights

- **Pure Squirrel Core**: Scripted protocols, liquid classes, scheduling DAGs, and deck state tracking are native Squirrel (.nut) modules that run cleanly on the standard Squirrel 3.2 runtime.
- **Physical Fluidics Modeling**: Simulates viscous dissipation (Hagen-Poiseuille), capillary meniscus rise (Young-Laplace), droplet detachment limits (Rayleigh-Plateau instability), and air-cushion compressibility.
- **Multi-Sensor Liquid Level Detection**: Models both capacitive liquid level detection (cLLD) and dynamic pressure-based liquid level detection (pLLD) with real-time clot detection and air-draw fault handling.
- **Kinematic Gantry Engine**: Jerk-limited S-curve motion profiling, dynamic 9 mm to 4.5 mm multichannel pipette head pitch adjustment, and continuous collision avoidance via spatial bounding envelopes.
- **Deterministic Assay Verification**: Strict mass and volume conservation accounting, cross-contamination tracking graphs, tip-reuse optimization, and four-parameter logistic (4PL) regression curve fitting.
- **Interactive Terminal UI**: High-fidelity ANSI deck layout visualizer, well volume concentration heatmaps, and live step progress tracing.

## Architecture

Spigot is structured into focused subsystems:

1. `core/`: Fundamental math (Vector3, AABB, matrix transformations), unit conversions (uL, mL, mm, mbar, cP), hierarchical exception trees, structured logging, and state snapshotting.
2. `deck/`: ANSI/SLAS labware geometry specifications (96-well, 384-well, 1536-well microplates, tip racks, reagent reservoirs, tube racks) and active accessories (magnetic separation blocks, peltier thermal shakers, microplate absorbance readers).
3. `fluidics/`: Fluid physical properties, liquid classes (aqueous, viscous, volatile, detergent, blood serum), Poiseuille flow, capillary dynamics, droplet formation, and LLD sensing algorithms.
4. `motion/`: Multi-axis gantry trajectory generators, S-curve profiling, collision clearance envelopes, and pipette plunger displacement mechanics.
5. `scheduler/`: Task dependency DAGs, critical path analysis (CPM), resource mutexes, intelligent tip reuse, and asynchronous execution coordination.
6. `protocols/`: Production assay definitions including Serial Dilution, qPCR Setup, ELISA, Magnetic Bead RNA Extraction, Cherry-Picking Normalization, and NGS Library Preparation.
7. `analysis/`: Volume audit accounting, contamination detection graphs, plate reader kinetic simulations, and worklist manifest parsers.
8. `ui/`: Terminal deck renderer, microplate heatmaps, and CLI controller.
9. `native/`: Optional C++20 native acceleration layer embedding the Squirrel VM with high-speed Navier-Stokes 1D solver and spatial bounding volume hierarchies.
10. `tools/`: Python runners, worklist converters, and automated test harnesses.

## Prerequisites

- Squirrel 3.2+ (`sq` CLI)
- Python 3.10+ (for integration tests and tooling)
- Clang++ / G++ with C++20 support (optional, for native acceleration binary)
- GNU Make

To install Squirrel on macOS:
```bash
brew install squirrel-lang
```

## Quick Start

Run the entire automated test suite:
```bash
make test
```

Execute an automated assay simulation:
```bash
./scripts/spigot run protocols/serial_dilution.nut
```

Launch the interactive deck visualizer:
```bash
./scripts/spigot inspect
```

Validate a high-throughput worklist:
```bash
./scripts/spigot validate examples/demo_deck.nut
```
