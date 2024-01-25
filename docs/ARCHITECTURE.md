# Spigot Architecture & Systems Design

Spigot is a high-performance automated liquid handling workstation operating system, micro-fluidic physics simulator, and assay execution engine. The platform is engineered primarily in Squirrel 3.2, providing object-oriented determinism, lightweight coroutine tasking, and immediate reference-counted memory cleanup, backed by an optional C++20 acceleration layer for PDE fluid simulation and spatial hierarchy queries.

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

## 1. Subsystem Decomposition

### 1.1 Core Foundation Layer (`core/`)
The foundational layer establishes mathematical primitives, dimensional verification, structured diagnostics, and state snapshot mechanisms:
- `math.nut`: 3D Cartesian vector mathematics (`Vector3`), linear interpolation (`lerp`), smoothstep hermite interpolation, Euclidean norms, and dot/cross products. Floating point equality uses explicit IEEE 754 epsilon tolerances via `fabs()` to avoid Squirrel integer truncation pitfalls.
- `aabb.nut`: Axis-Aligned Bounding Box (`AABB`) geometry providing collision intersection tests, ray casting tests, spatial containment, and bounding box unions.
- `units.nut`: Dimensional transformations enforcing consistent SI calculations. Converts between microliters, milliliters, nanoliters, cubic meters, millimeters, meters, millibars, Pascals, and centipoise.
- `errors.nut`: Polymorphic exception hierarchy rooted at `SpigotError`, subclassing into `DeckError`, `FluidicsError`, `MotionError`, and `SchedulerError` with rich diagnostic payloads (coordinates, volumes, channel indices).
- `logging.nut`: ANSI-colored structured terminal logger supporting log levels `TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR`, and `FATAL`. Global level constants reside in the root table `::LogLevel` for cross-file accessibility.
- `events.nut`: Decoupled publish/subscribe event dispatcher enabling runtime monitoring of aspiration events, motion trajectories, sensor triggers, and assay milestones.
- `state.nut`: Workstation state snapshot and rollback engine. Enables deep cloning of deck and actuator state to facilitate dry-run simulations and transactional rollbacks upon protocol failures.

### 1.2 Deck & Labware Architecture (`deck/`)
The physical workstation deck conforms to international microplate standards:
- ANSI/SLAS Footprint: Deck slots feature standard 127.76 mm x 85.48 mm footprints arranged in a configurable 3x4 grid (12 slots) plus dedicated wash stations and waste chutes.
- Analytical Well Geometries (`well_geometry.nut`): Microplate wells and reagent reservoirs model exact physical cross-sections via piecewise analytical volume integrals:
  - `FLAT_CYLINDER`: Standard flat-bottom microplates where V = pi * r^2 * h.
  - `V_CONICAL`: Conical PCR tubes and V-bottom assay plates where V = (1/3) * pi * (r*h/H)^2 * h.
  - `U_ROUND`: Spherical cap bottoms transitioning to cylindrical barrels.
  - `PYRAMIDAL_TROUGH`: 12-channel reagent troughs (71.0 mm x 8.0 mm) with tapered bottom sumps to accurately reflect liquid height without artificial cylinder inflation.
- Active Accessories (`accessories.nut`): Robotic hardware integration for `MagneticSeparationBlock` (motorized ring/post magnet elevators), `PeltierThermalShaker` (thermal incubation 4 to 99 C with 100 to 2200 RPM orbital shaking), and `MicroplateReaderStation` (multi-wavelength absorbance detection).

### 1.3 Micro-Fluidics Physics Engine (`fluidics/`)
Liquid transfers are modeled using fundamental physical transport laws rather than static volumetric lookups:
- Hagen-Poiseuille Viscous Flow (`poiseuille_model.nut`): Computes hydraulic resistance through conical tapered pipette tips:
  $$R_{hyd} = \frac{8 \mu L}{\pi} \cdot \frac{r_1^2 + r_1 r_2 + r_2^2}{3 r_1^3 r_2^3}$$
  Predicts viscous pressure drop and dynamically restricts maximum flow rates to prevent cavitation and air fingering.
- Capillarity & Meniscus Curvature (`capillary_model.nut`): Models Young-Laplace pressure differentials across curved interfaces and Jurin capillary rise heights:
  $$h_{rise} = \frac{2 \gamma \cos \theta}{\rho g r}$$
- Rayleigh-Plateau Droplet Detachment (`droplet_dynamics.nut`): Evaluates critical pendant drop volumes using Harkins-Brown dimensionless shape corrections to determine when a droplet will detach spontaneously or require well-wall touch-off.
- Boyle Gas Compression (`air_displacement.nut`): Models isothermal gas expansion in the air cushion of air-displacement pipettes under hydrostatic liquid load, accurately predicting aspiration lag and volumetric loss.
- Dual Liquid Level Detection (`pressure_lld.nut`, `capacitive_lld.nut`): Simulates differential pressure slope thresholding during tip descent, as well as high-frequency capacitive admittance shifts upon liquid contact, including clot and foam detection.

### 1.4 Kinematics & Motion Control (`motion/`)
- Axis Constraints (`axis_limits.nut`): Physical travel envelopes (X: 750 mm, Y: 500 mm, Z: 400 mm) with velocity, acceleration, and jerk limits.
- 7-Phase S-Curve Trajectory Profiler (`s_curve.nut`): Analytical jerk-limited motion profiling. Smoothly ramps acceleration to eliminate liquid sloshing and meniscus oscillation during rapid high-speed transit.
- Dynamic Variable-Pitch Multichannel Pipetting (`multi_channel_pitch.nut`): Stepper-driven lead screw adjusting 8-channel tip spacing continuously between 4.5 mm (384-well microplates), 9.0 mm (96-well microplates), and 18.0 mm (tube racks).
- Collision Envelope Planning (`collision_envelope.nut`): Dynamically computes safe transit Z heights above all mounted labware and accessory heights, generating retract-traverse-descend collision-free 3D corridors.

### 1.5 Assay DAG Scheduling & CPM Optimization (`scheduler/`)
- Dependency Task Graph (`task_graph.nut`): Directed Acyclic Graph (DAG) representing assay steps with explicit resource requirements and temporal constraints. Enforces cycle prevention via Kahn's topological sort.
- Critical Path Method Solver (`cpm_solver.nut`): Performs forward and backward passes over the DAG to compute Early Start (ES), Early Finish (EF), Late Start (LS), Late Finish (LF), and Total Float (Slack). Highlights the critical path determining total assay duration.
- Consumable & Tip Optimization (`tip_optimizer.nut`): Evaluates tip reuse safety (air-dispense reagent distribution vs dirty immersion) to minimize disposable plastic tip consumption while preventing cross-contamination.
- Execution Engine (`execution_engine.nut`): Event loop dispatcher with step-level rollback checkpoints, mutex locking over deck slots and gantry axes, and error recovery policies.

### 1.6 Analytical Verification & Auditing (`analysis/`)
- Mass Balance Volume Accounting (`volume_accounting.nut`): Real-time tracking of every aspirated, dispensed, and wasted microliter across the system. Flags any discrepancies exceeding physical evaporation thresholds.
- Contamination Graph (`contamination_graph.nut`): Bipartite graph tracking tip-to-well liquid contacts. Audits for dirty tip carryover, cross-sample contamination, and pure reagent reservoir breaches.
- Four-Parameter Logistic (4PL) Regression (`four_parameter_logistic.nut`): Analytical sigmoidal dose-response curve fitting:
  $$y = D + \frac{A - D}{1 + (x / C)^B}$$
  Computes Bottom asymptote (A), Top asymptote (D), EC50 concentration (C), and Hill slope (B) using log-linear regression, complete with analytical inversion x(y).

---

## 2. Memory Model & Reference Counting in Squirrel

Squirrel employs a hybrid memory management model featuring deterministic reference counting supplemented by an incremental mark-and-sweep cycle detector.

### 2.1 Deterministic Resource Deallocation
Every Squirrel object (instance, table, array, string) maintains an internal reference counter `_refCount`. When a variable goes out of scope or is reassigned, its reference count decrements immediately. When it hits zero, its destructor (`_destructor` or native release hook) is invoked deterministically without waiting for a garbage collection pause. This property is crucial for robotic systems:
- Mutex locks and deck slot reservations are released the instant a task finishes.
- Native C++ buffer allocations and spatial BVH tree nodes are freed synchronously.

### 2.2 Table Slot Creation Semantics
Squirrel distinguishes between slot creation and slot assignment:
- Table creation: `tbl[key] <- value;` creates a new key-value pair in `tbl`.
- Table assignment: `tbl[key] = value;` requires `key` to already exist in `tbl`, otherwise throwing an `index 'key' does not exist` exception.
Spigot explicitly adheres to this convention throughout state stores, event registries, and well dictionaries.

### 2.3 Root Table (`::`) Global Scoping
In Squirrel 3.2, compile-time declarations like `const` and `enum` are local to the single translation unit being parsed. To make enumeration dictionaries (such as `::LogLevel` and `::WellShapeType`) available across files loaded dynamically via `dofile()`, Spigot registers them directly into the global root table:
```squirrel
::WellShapeType <- {
    FLAT_CYLINDER     = 0,
    V_CONICAL         = 1,
    U_ROUND           = 2,
    COMPOSITE_CONICAL = 3,
    COMPOSITE_ROUND   = 4,
    PYRAMIDAL_TROUGH  = 5
};
```

---

## 3. C++ Native Acceleration FFI Architecture

While Spigot runs 100% natively in pure Squirrel using standard interpreters (`sq`), it includes an optional high-performance C++20 acceleration host (`bin/spigot_native`):

```
+-------------------------------------------------------+
|                Squirrel 3.2 Script Layer              |
|        calls native_fluid_solve_flow(rho, mu, dp)     |
+-------------------------------------------------------+
                           |
                           v  (Squirrel FFI Stack Push/Pop)
+-------------------------------------------------------+
|               native/src/sq_bindings.cpp              |
|   Extracts SQFloat arguments -> calls C++ engines     |
+-------------------------------------------------------+
              /                           \
             v                             v
+--------------------------+  +--------------------------+
|  fluid_pde_solver.cpp    |  |     spatial_bvh.cpp      |
|  1D Navier-Stokes Solver |  |  3D Spatial AABB BVH Tree|
+--------------------------+  +--------------------------+
```

### 3.1 1D Navier-Stokes PDE Solver (`native/src/fluid_pde_solver.cpp`)
Discretizes fluid velocity along the pipette tip axis using finite differences to simulate unsteady viscous start-up flow and inertial relaxation during high-speed aspiration pulses:
$$\rho \left( \frac{\partial u}{\partial t} + u \frac{\partial u}{\partial z} \right) = -\frac{\partial p}{\partial z} + \mu \frac{\partial^2 u}{\partial r^2}$$

### 3.2 Spatial Bounding Volume Hierarchy (`native/src/spatial_bvh.cpp`)
Builds a binary BVH tree of 3D AABBs encompassing deck slots, labware bodies, and active accessories. Accelerates robotic collision detection queries from O(N) linear scans to O(log N) ray and box intersection tests.
