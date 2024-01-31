# ANSI/SLAS Labware Specification & Analytical Volume Integrals

This document defines the dimensional standards, coordinate systems, and analytical volumetric models for all labware supported by Spigot.

---

## 1. ANSI/SLAS Standard Footprint & Coordinate Frames

Spigot adheres to the Society for Laboratory Automation and Screening (ANSI/SLAS 1-2004 through ANSI/SLAS 4-2004) specifications for microplates.

```
+-------------------------------------------------------------+
| (Origin X0, Y0)                                             |
|   A1    A2    A3    A4    A5    A6    A7    A8    A9   A10  A11  A12
|   B1    .     .     .     .     .     .     .     .     .     .  B12
|   C1    .                                                     .  C12
|   D1    .                                                     .  D12
|   E1    .                    ANSI/SLAS                        .  E12
|   F1    .                   127.76 mm                         .  F12
|   G1    .                       x                             .  G12
|   H1    .                    85.48 mm                         .  H12
+-------------------------------------------------------------+
```

### 1.1 Universal Physical Footprint
- Length: 127.76 mm (+/- 0.25 mm)
- Width: 85.48 mm (+/- 0.25 mm)
- Standard Plate Height: 14.35 mm (+/- 0.25 mm)
- Deep Well Block Height: 44.00 mm
- Deck Slot Origin: Front-left-bottom corner of the slot socket ($[X_0, Y_0, 0.0]$).

### 1.2 Grid Layout Formats

| Format | Rows x Columns | Pitch ($P_x = P_y$) | First Well A1 Offset ($X_{off}, Y_{off}$) | Nominal Volume | Dead Volume ($V_{dead}$) |
|---|---|---|---|---|---|
| **96-Well Flat** | 8 x 12 | 9.00 mm | (14.38 mm, 11.24 mm) | 360 uL | 10.0 uL |
| **96-Well V-Conical** | 8 x 12 | 9.00 mm | (14.38 mm, 11.24 mm) | 220 uL | 2.0 uL |
| **96-Well Round (U)** | 8 x 12 | 9.00 mm | (14.38 mm, 11.24 mm) | 320 uL | 4.0 uL |
| **384-Well High Density**| 16 x 24 | 4.50 mm | (12.13 mm, 8.99 mm) | 120 uL | 1.5 uL |
| **1536-Well Ultra High** | 32 x 48 | 2.25 mm | (11.00 mm, 7.80 mm) | 12 uL | 0.3 uL |
| **12-Channel Reservoir** | 1 x 12 | 9.00 mm | (14.38 mm, 7.24 mm) | 22,000 uL | 50.0 uL |
| **1-Channel Bulk Res.** | 1 x 1 | 0.00 mm | (63.88 mm, 42.74 mm) | 190,000 uL | 500.0 uL |
| **24-Tube Eppendorf** | 4 x 6 | 18.00 mm | (18.88 mm, 15.74 mm) | 1,500 uL | 15.0 uL |

---

## 2. Piecewise Analytical Well Volume Integrals

Accurate liquid handling requires mapping liquid height $h$ to liquid volume $V$, and conversely, inverting volume $V$ to compute liquid height $h(V)$ for Tool Center Point immersion targeting.

### 2.1 Flat-Bottom Cylinder (`FLAT_CYLINDER`)
- Geometry: Pure cylindrical barrel with flat base.
- Volume as a function of height $h$:
  $$V(h) = \pi r^2 h$$
- Height as a function of volume $V$:
  $$h(V) = \frac{V}{\pi r^2}$$

### 2.2 Conical V-Bottom Well (`V_CONICAL`)
- Geometry: Right circular cone of base radius $r$ and total depth $H$.
- Volume as a function of height $h$:
  $$V(h) = \frac{1}{3} \pi \left( \frac{r \cdot h}{H} \right)^2 h = \frac{\pi r^2 h^3}{3 H^2}$$
- Height as a function of volume $V$:
  $$h(V) = \left( \frac{3 V H^2}{\pi r^2} \right)^{1/3}$$

### 2.3 Round U-Bottom Well (`U_ROUND`)
- Geometry: Spherical cap of radius $r$ at the bottom ($h \le r$), transitioning into a cylindrical barrel for $h > r$.
- Piecewise volume:
  $$V(h) = \begin{cases} \frac{1}{3} \pi h^2 (3 r - h) & \text{if } h \le r \\ \frac{2}{3} \pi r^3 + \pi r^2 (h - r) & \text{if } h > r \end{cases}$$

### 2.4 Composite Conical-Cylinder Well (`COMPOSITE_CONICAL`)
- Geometry: Conical bottom section up to height $h_{bot}$, followed by cylindrical barrel of depth $H - h_{bot}$.
- Let $V_{bot} = \frac{1}{3} \pi r^2 h_{bot}$.
- Piecewise volume:
  $$V(h) = \begin{cases} \frac{\pi r^2 h^3}{3 h_{bot}^2} & \text{if } h \le h_{bot} \\ V_{bot} + \pi r^2 (h - h_{bot}) & \text{if } h > h_{bot} \end{cases}$$
- Piecewise height inversion:
  $$h(V) = \begin{cases} \left( \frac{3 V h_{bot}^2}{\pi r^2} \right)^{1/3} & \text{if } V \le V_{bot} \\ h_{bot} + \frac{V - V_{bot}}{\pi r^2} & \text{if } V > V_{bot} \end{cases}$$

### 2.5 Pyramidal Rectangular Trough Reservoir (`PYRAMIDAL_TROUGH`)
- Geometry: 12-channel reagent reservoirs feature elongated rectangular troughs ($L \approx 71.0 \text{ mm}, W \approx 8.0 \text{ mm}$) with V-shaped bottom sumps.
- Cross-sectional Area: $A_{trough} = L \cdot W \approx 568.0 \text{ mm}^2$.
- Volume and Height:
  $$V(h) = A_{trough} \cdot h$$
  $$h(V) = \frac{V}{A_{trough}}$$
Modeling reservoirs as rectangular troughs rather than circular cylinders is critical: using cylindrical formulas overestimates liquid height by over $10\times$, resulting in spurious gantry Z limit breaches during deep aspiration.

---

## 3. Active Robotic Accessories

### 3.1 96-Ring Neodymium Magnetic Separation Block
- Purpose: Solid-Phase Reversible Immobilization (SPRI) bead pull-down for DNA/RNA purification.
- Mechanism: 96 individual sintered NdFeB permanent ring magnets mounted on a motorized elevator.
- States: Engaged (elevated against microplate skirt, 2.5 s transit) and Disengaged (retracted below deck).

### 3.2 Peltier Thermal Incubation Shaker
- Temperature Range: 4.0 C to 99.0 C (+/- 0.5 C accuracy).
- Heating Rate: 2.5 C / second.
- Cooling Rate: 1.2 C / second.
- Shaking Speed: 100 to 2200 RPM with 2.0 mm orbital radius.
- Automatic anti-vibration soft start and stop ramps.

### 3.3 Microplate Absorbance Reader Station
- Optical Detection: Multi-wavelength filter wheel (450 nm ELISA, 600 nm bacterial OD600, 405 nm enzyme kinetics).
- Dynamic Range: 0.000 to 4.000 Optical Density (OD) units (+/- 0.005 OD precision).
