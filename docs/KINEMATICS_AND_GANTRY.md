# Robotic Kinematics & Gantry Control Specifications

This document details the Cartesian kinematics, 7-phase S-curve trajectory profiling, variable-pitch multichannel actuation, and dynamic collision avoidance algorithms implemented in Spigot.

---

## 1. Workstation Gantry Physical Architecture

The Spigot automated workstation operates a 3-axis Cartesian robotic gantry with an 8-channel pipetting arm and high-resolution optical/capacitive sensors.

```
       +---------------------------------------------+
       |                  X-Axis Beam                |===================>> [X: 0 - 750 mm]
       +---------------------------------------------+
              |                               |
       +---------------+               +---------------+
       |  Y-Carriage   |               |  Y-Carriage   |
       +---------------+               +---------------+
              |
       +---------------+
       |  Z-Mast Arm   |==============>> [Z: 0 - 400 mm]
       +---------------+
              |
      [8-Channel Pitch] ==============>> [Pitch: 4.5 - 18.0 mm]
              |
       Nozzles 1 to 8
```

### 1.1 Physical Travel Boundaries & Kinetic Limits

| Axis | Travel Range | Max Velocity ($V_{max}$) | Max Acceleration ($A_{max}$) | Max Jerk ($J_{max}$) |
|---|---|---|---|---|
| **X (Longitudinal)** | 0.0 to 750.0 mm | 600.0 mm/s | 3000.0 mm/s^2 | 15000.0 mm/s^3 |
| **Y (Lateral)** | 0.0 to 500.0 mm | 500.0 mm/s | 2500.0 mm/s^2 | 12000.0 mm/s^3 |
| **Z (Vertical)** | 0.0 to 400.0 mm | 350.0 mm/s | 2500.0 mm/s^2 | 12000.0 mm/s^3 |
| **Pitch (Spacing)** | 4.5 to 18.0 mm | 50.0 mm/s | 200.0 mm/s^2 | 1000.0 mm/s^3 |
| **Plunger (Piston)** | 0.0 to 60.0 mm | 40.0 mm/s | 500.0 mm/s^2 | 5000.0 mm/s^3 |

---

## 2. 7-Phase Jerk-Limited S-Curve Trajectory Profiling

### 2.1 The Sloshing Hazard of Trapezoidal Acceleration
Conventional CNC machines and 3D printers often employ trapezoidal velocity profiles where acceleration steps instantaneously between 0 and $A_{max}$. In liquid handling workstations, instantaneous acceleration steps correspond to theoretical infinite jerk ($j(t) = \frac{da}{dt} \to \infty$). 

Infinite jerk produces severe high-frequency vibrational excitation. In microplate wells, this resonance causes:
1. Liquid sloshing and well-to-well splashing.
2. Premature droplet shedding from pipette tip nozzles.
3. Meniscus oscillation that invalidates subsequent optical or capacitive liquid level detection.

### 2.2 Mathematical Formulation of 7-Phase S-Curves
Spigot enforces smooth $C^2$-continuous position trajectories via analytical 7-phase S-curve profiling (`motion/s_curve.nut`). The profile partitions the trajectory into 7 distinct temporal segments:

```
Acceleration a(t) Profile:
        +-------+                 Phase 2: Constant Accel
       /         \
      /           \               Phase 1 & 3: Jerk Ramping
-----+             +------------- Phase 4: Constant Cruise Velocity
                    \           /
                     \         /  Phase 5 & 7: Jerk Ramping
                      +-------+   Phase 6: Constant Decel
```

1. **Phase 1 ($t \in [0, T_1]$)**: Constant positive jerk $j(t) = +J_{max}$. Acceleration ramps linearly from 0 to $A_{max}$.
   $$a(t) = J_{max} t$$
   $$v(t) = \frac{1}{2} J_{max} t^2$$
   $$s(t) = \frac{1}{6} J_{max} t^3$$

2. **Phase 2 ($t \in [T_1, T_2]$)**: Constant maximum acceleration $j(t) = 0, a(t) = A_{max}$.
   $$v(t) = v(T_1) + A_{max}(t - T_1)$$
   $$s(t) = s(T_1) + v(T_1)(t - T_1) + \frac{1}{2} A_{max}(t - T_1)^2$$

3. **Phase 3 ($t \in [T_2, T_3]$)**: Constant negative jerk $j(t) = -J_{max}$. Acceleration ramps down from $A_{max}$ to 0. Velocity reaches cruise speed $V_{max}$.

4. **Phase 4 ($t \in [T_3, T_4]$)**: Constant cruise velocity $j(t) = 0, a(t) = 0, v(t) = V_{max}$.
   $$s(t) = s(T_3) + V_{max}(t - T_3)$$

5. **Phase 5 ($t \in [T_4, T_5]$)**: Constant negative jerk $j(t) = -J_{max}$. Deceleration ramps down from 0 to $-A_{max}$.

6. **Phase 6 ($t \in [T_5, T_6]$)**: Constant maximum deceleration $j(t) = 0, a(t) = -A_{max}$.

7. **Phase 7 ($t \in [T_6, T_7]$)**: Constant positive jerk $j(t) = +J_{max}$. Deceleration ramps smoothly from $-A_{max}$ to 0 as target position is attained with zero velocity.

---

## 3. Dynamic Variable-Pitch Multichannel Pipetting

High-throughput screening requires pipetting across heterogeneous formats:
- 384-Well Microplates: Center-to-center well spacing is exactly 4.50 mm.
- 96-Well Microplates & Reservoirs: Center-to-center well spacing is exactly 9.00 mm.
- 24-Position Microcentrifuge Tube Racks: Center-to-center tube spacing is exactly 18.00 mm.

### 3.1 Kinematic Mapping
The variable-pitch mechanism adjusts tip spacing synchronously using a scissor linkage driven by a precision lead-screw actuator (`motion/multi_channel_pitch.nut`). Given the tool center position of Channel 0 at $\mathbf{P}_0 = [X_0, Y_0, Z_0]^T$ and a commanded pitch $p \in [4.5, 18.0] \text{ mm}$, the 3D position of channel index $k \in \{0, 1, \dots, 7\}$ is:
$$\mathbf{P}_k = \begin{bmatrix} X_0 \\ Y_0 + k \cdot p \\ Z_0 \end{bmatrix}$$

The total span of the 8-channel array is $W_{span} = 7 \cdot p$, varying from 31.5 mm (at 4.5 mm pitch) to 126.0 mm (at 18.0 mm pitch).

---

## 4. Collision Avoidance & Safe Clearance Envelopes

The workstation deck accommodates consumables of varying heights: flat microplates (14.35 mm), deep-well plates (44.0 mm), tip racks (55.0 mm), 15 mL Falcon tube racks (120.0 mm), and active accessories (35.0 mm). Moving horizontally at low Z heights poses an acute risk of tip collision.

### 4.1 Safe Transit Z Height Calculation
The collision planner (`motion/collision_envelope.nut`) continuously queries the mounted labware heights across all 12 slots:
$$Z_{safe} = \max_{s \in \text{Slots}} \left( Z_{slot, origin} + H_{labware, s} \right) + \delta_{safety\_margin}$$
where $\delta_{safety\_margin} = 15.0 \text{ mm}$. If the calculated $Z_{safe}$ is less than the baseline clearance (160.0 mm), $Z_{safe} = 160.0 \text{ mm}$.

### 4.2 Three-Phase Retract-Traverse-Descend Transit Corridor
When moving the tool center point from origin $\mathbf{A} = [X_A, Y_A, Z_A]$ to destination $\mathbf{B} = [X_B, Y_B, Z_B]$:
1. **Vertical Retraction**: Move vertically from $[X_A, Y_A, Z_A]$ to $[X_A, Y_A, Z_{safe}]$.
2. **Horizontal Traverse**: Move along the horizontal plane at safe clearance from $[X_A, Y_A, Z_{safe}]$ to $[X_B, Y_B, Z_{safe}]$.
3. **Vertical Descent**: Move vertically from $[X_B, Y_B, Z_{safe}]$ to $[X_B, Y_B, Z_B]$.

This three-waypoint corridor guarantees zero lateral collision risk across all mounted deck components.

---

## 5. Tool Center Point (TCP) Tip Length Tracking

A common source of crashes in liquid handling systems occurs when the control software fails to distinguish between the bare pipette nozzle and the nozzle with an attached disposable tip.

Let $Z_{gantry}$ be the coordinate of the gantry Z carriage. The effective Tool Center Point $Z_{TCP}$ is:
$$Z_{TCP} = Z_{gantry} - L_{tip}$$
where $L_{tip} = 0.0 \text{ mm}$ when bare, $51.2 \text{ mm}$ for 200 uL tips, and $70.0 \text{ mm}$ for 1000 uL tips. All protocol immersion commands target the liquid meniscus relative to $Z_{TCP}$, ensuring sub-millimeter immersion precision regardless of tip consumable format.
