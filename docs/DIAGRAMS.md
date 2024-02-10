# Spigot Architecture & System Diagrams

This document collects architectural, fluidic, kinematic, and scheduling diagrams illustrating the internal mechanisms of Spigot.

---

## 1. System Architecture Overview

```mermaid
flowchart TD
    CLI["CLI & Dashboard (ui/cli_app.nut)"] --> Protocol["Assay Protocols (protocols/*.nut)"]
    Protocol --> Engine["Execution Engine (scheduler/execution_engine.nut)"]
    
    subgraph Scheduling["Scheduling & Orchestration"]
        Engine --> TaskGraph["Task DAG (scheduler/task_graph.nut)"]
        TaskGraph --> CPM["CPM Solver (scheduler/cpm_solver.nut)"]
        Engine --> TipOpt["Tip Optimizer (scheduler/tip_optimizer.nut)"]
        Engine --> Locks["Resource Locks (scheduler/resource_lock.nut)"]
    end

    subgraph MotionControl["Robotic Motion & Kinematics"]
        Engine --> Gantry["Gantry Controller (motion/gantry_kinematics.nut)"]
        Gantry --> SCurve["7-Phase S-Curve (motion/s_curve.nut)"]
        Gantry --> Pitch["Multi-Channel Pitch (motion/multi_channel_pitch.nut)"]
        Gantry --> Collision["Collision Planner (motion/collision_envelope.nut)"]
        Gantry --> Plunger["Plunger Actuators (motion/pipette_actuator.nut)"]
    end

    subgraph FluidicsEngine["Fluid Dynamics & Liquid Physics"]
        Engine --> Profile["Aspiration Profile (fluidics/aspiration_profile.nut)"]
        Profile --> LiquidClass["Liquid Class Factory (fluidics/liquid_classes.nut)"]
        Profile --> Poiseuille["Poiseuille Viscous Flow (fluidics/poiseuille_model.nut)"]
        Profile --> Droplet["Droplet & Touch-Off (fluidics/droplet_dynamics.nut)"]
        Profile --> AirDisp["Boyle Air Cushion (fluidics/air_displacement.nut)"]
        Profile --> LLD["Dual LLD Sensing (pressure_lld & capacitive_lld)"]
    end

    subgraph DeckLabware["Deck & Physical Modeling"]
        Gantry --> DeckLayout["Deck Layout (deck/deck_layout.nut)"]
        DeckLayout --> Slots["12 ANSI/SLAS Slots (deck/slot.nut)"]
        Slots --> Plates["Microplates & Reservoirs (deck/plate.nut, reservoir.nut)"]
        Plates --> WellGeom["Piecewise Geometries (deck/well_geometry.nut)"]
        Slots --> Accessories["Active Accessories (Magnetic, Shaker, Reader)"]
    end

    subgraph NativeLayer["C++ Native Acceleration (Optional)"]
        Poiseuille -.-> PDE["1D Navier-Stokes PDE Solver"]
        Collision -.-> BVH["3D Spatial BVH Tree"]
    end
```

---

## 2. Micro-Fluidic Meniscus & Pendant Droplet Anatomy

```
         +-----------------------------+
         |     Pipette Tip Barrel      |
         |         (Radius r1)         |
         \                             /
          \                           /
           \                         /
            \                       /
             \                     /
              \     Conical       /
               \     Taper       /
                \               /
                 |             |
                 | Nozzle (r2) |
                 +-----+ +-----+
                       | |
                  ..---' '---..
                .'             '.   Pendant Droplet (V_drop)
               /                 \  Held by Surface Tension: F_gamma = 2 * pi * r2 * gamma
              |                   | Opposed by Gravity: F_g = rho * V_drop * g
               \                 /
                '.             .'
                  ''---------''
                       |
                       v [If V_drop < V_crit => Touch-Off Required]
      ------------------------------------ Well Wall
```

---

## 3. 7-Phase Jerk-Limited S-Curve Kinematics Profile

```
Acceleration a(t):
               +----------------+  (Phase 2: a = +A_max)
              /                  \
   Phase 1   /                    \ Phase 3
  (j = +J)  /                      \ (j = -J)
  ---------+                        +-----------------------+ (Phase 4: a = 0)
                                     \                     /
                                      \                   /
                                       \                 /
                                        +---------------+  (Phase 6: a = -A_max)
                                      Phase 5           Phase 7
                                     (j = -J)          (j = +J)

Velocity v(t):
                                    +-----------------------+ (Phase 4: v = V_max)
                                  .'                         '.
                                .'                             '.
                              .'                                 '.
  ---------------------------+                                     +------------- (v = 0)
     Acceleration Segment                                      Deceleration Segment
```

---

## 4. Assay Scheduling DAG & Critical Path Method (CPM)

```mermaid
graph LR
    Start(["Start Assay"]) --> T1["T1: Pick Tip (10s)"]
    T1 --> T2["T2: Distribute Master Mix (45s)"]
    T1 --> T3["T3: Resuspend Primers (20s)"]
    T2 --> T4["T4: Add Primers to Target (35s)"]
    T3 --> T4
    T4 --> T5["T5: Add Template DNA (30s)"]
    T5 --> T6["T6: Seal & Thermal Cycle (1200s)"]
    T6 --> Finish(["Assay Complete"])

    classDef critical stroke:#f00,stroke-width:3px,fill:#fee;
    class T1,T2,T4,T5,T6 critical;
```

---

## 5. 12-Slot Workstation Deck Coordinate System

```
  Y (500 mm)
    ^
    |  +--------------------+  +--------------------+  +--------------------+  +--------------------+
    |  | Slot 9 (Row 3)     |  | Slot 10 (Row 3)    |  | Slot 11 (Row 3)    |  | Slot 12 (Row 3)    |
    |  | [127.76 x 85.48 mm]|  | [127.76 x 85.48 mm]|  | [127.76 x 85.48 mm]|  | [127.76 x 85.48 mm]|
    |  +--------------------+  +--------------------+  +--------------------+  +--------------------+
    |
    |  +--------------------+  +--------------------+  +--------------------+  +--------------------+
    |  | Slot 5 (Row 2)     |  | Slot 6 (Row 2)     |  | Slot 7 (Row 2)     |  | Slot 8 (Row 2)     |
    |  | [127.76 x 85.48 mm]|  | [127.76 x 85.48 mm]|  | [127.76 x 85.48 mm]|  | [127.76 x 85.48 mm]|
    |  +--------------------+  +--------------------+  +--------------------+  +--------------------+
    |
    |  +--------------------+  +--------------------+  +--------------------+  +--------------------+
    |  | Slot 1 (Row 1)     |  | Slot 2 (Row 1)     |  | Slot 3 (Row 1)     |  | Slot 4 (Row 1)     |
    |  | [127.76 x 85.48 mm]|  | [127.76 x 85.48 mm]|  | [127.76 x 85.48 mm]|  | [127.76 x 85.48 mm]|
    |  +--------------------+  +--------------------+  +--------------------+  +--------------------+
    |
  (0,0)-----------------------------------------------------------------------------------------> X (750 mm)
```

---

## 6. Contamination Bipartite Audit Graph

```mermaid
graph TD
    subgraph Tips["Tip Set"]
        Tip1["Tip Channel 0"]
        Tip2["Tip Channel 1"]
    end

    subgraph Liquids["Liquids / Wells"]
        Res1["Buffer Reservoir (Pure)"]
        WellA1["Sample Well A1 (Stock DNA)"]
        WellB1["Target Well B1 (Reaction)"]
    end

    Tip1 -- "1. Clean Aspirate" --> Res1
    Tip1 -- "2. Dispense" --> WellB1
    Tip1 -- "3. Dirty Contact" --> WellA1
    Tip1 -. "4. VIOLATION: Dirty Aspirate" .-> Res1

    classDef violation stroke:#f00,stroke-width:2px,stroke-dasharray: 5 5,color:#f00;
    class Res1,WellA1,WellB1,Tip1,Tip2 default;
```
