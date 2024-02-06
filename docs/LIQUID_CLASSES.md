# Liquid Class Developer Guide & Physical Calibration Manual

In automated liquid handling, dispensing 50 uL of water is fundamentally different from dispensing 50 uL of 80% glycerol or 100% ethanol. Differences in dynamic viscosity, surface tension, volatility, and foaming tendencies dictate distinct pipetting kinematics.

This manual documents Spigot's calibrated liquid class specifications and provides an empirical calibration protocol for authoring new liquid classes.

---

## 1. Liquid Class Parameters Specification

A Spigot `LiquidClass` encapsulates both physical fluid properties and robotic execution parameters:

```squirrel
class LiquidClass {
    name = "Standard_Aqueous";
    properties = null; // LiquidProperties

    // Kinematic flow parameters
    aspiration_flow_rate_ul_s = 40.0;
    dispense_flow_rate_ul_s   = 60.0;
    delay_after_aspiration_s  = 0.5;
    delay_after_dispense_s    = 0.3;
    pre_wetting_cycles        = 0;
    air_transport_gap_ul      = 0.0;
    blowout_volume_ul         = 10.0;
    sub_surface_dispense      = false;
    touch_off_enabled         = true;
    immersion_depth_mm        = 1.0;
}
```

### Parameter Functional Definitions
- `aspiration_flow_rate_ul_s`: Speed of plunger retraction during liquid intake. Must be reduced for viscous liquids to prevent cavitation and bubble formation.
- `dispense_flow_rate_ul_s`: Speed of plunger downward stroke during liquid expulsion. Must be controlled to prevent liquid splashing.
- `delay_after_aspiration_s`: Pause duration before withdrawing the tip from the liquid. Allows the internal air cushion to equilibrate and viscous fluid filaments to enter the tip.
- `delay_after_dispense_s`: Pause duration before tip retraction. Allows fluid clinging to the orifice to break free.
- `pre_wetting_cycles`: Number of rapid aspirate-and-dispense cycles in the source reservoir before the actual transfer. Saturates the tip vapor headspace with solvent vapor to prevent dripping of volatile liquids.
- `air_transport_gap_ul`: Extra air aspirated after withdrawing from liquid. Creates an air buffer that prevents droplets from weeping during high-speed gantry transit.
- `blowout_volume_ul`: Air volume expelled beyond the nominal dispense stroke to clear liquid retained inside the orifice. Set to 0 for foaming detergents.
- `sub_surface_dispense`: If true, dispenses beneath the liquid surface of the target well, preventing droplet splashing and foaming.
- `touch_off_enabled`: If true, translates the tip against the inner well wall to wick off hanging droplets.
- `immersion_depth_mm`: Distance the tip penetrates below the liquid meniscus. Tracked dynamically to avoid exterior tip wetting.

---

## 2. Standard Pre-Calibrated Liquid Classes

| Liquid Class | Fluid Properties | Flow Rate (Asp/Disp) | Delays (Asp/Disp) | Pre-Wet | Air Gap | Blowout | Special Rules |
|---|---|---|---|---|---|---|---|
| **Standard_Aqueous** | rho=1000, mu=1.00 cP, gamma=72.8 mN/m | 50 / 80 uL/s | 0.3 / 0.2 s | 0 | 0.0 uL | 8.0 uL | Wall touch-off |
| **Viscous_Glycerol50** | rho=1130, mu=6.00 cP, gamma=68.0 mN/m | 15 / 20 uL/s | 1.5 / 1.2 s | 1 | 5.0 uL | 15.0 uL | Extended delay |
| **Viscous_Glycerol80** | rho=1210, mu=60.0 cP, gamma=65.0 mN/m | 5 / 8 uL/s | 3.0 / 2.5 s | 1 | 8.0 uL | 25.0 uL | Low shear rate |
| **Volatile_Ethanol70** | rho=860, mu=2.30 cP, gamma=28.0 mN/m | 30 / 50 uL/s | 0.5 / 0.3 s | 2 | 10.0 uL | 12.0 uL | Vapor saturation |
| **Volatile_Ethanol100**| rho=789, mu=1.20 cP, gamma=22.0 mN/m | 25 / 40 uL/s | 0.8 / 0.5 s | 3 | 15.0 uL | 15.0 uL | Vapor saturation |
| **Detergent_Triton** | rho=1060, mu=15.0 cP, gamma=30.0 mN/m | 15 / 15 uL/s | 1.0 / 1.0 s | 1 | 0.0 uL | 0.0 uL | Sub-surface (NO blowout) |
| **Biological_Serum** | rho=1025, mu=1.80 cP, gamma=55.0 mN/m | 20 / 35 uL/s | 1.0 / 0.8 s | 1 | 5.0 uL | 10.0 uL | Protein film guard |

---

## 3. Physical Calibration Protocol for Custom Reagents

When introducing a novel buffer or clinical specimen into Spigot, follow this 4-step empirical calibration workflow:

```
[Step 1: Physical Fluid Characterization]
           |
           v
[Step 2: Gravimetric Volumetric Assessment]
           |
           v
[Step 3: High-Speed Meniscus Inspection]
           |
           v
[Step 4: Regression Parameter Tuning]
```

### Step 1: Characterize Fluid Properties
Measure or look up fluid density $\rho$ (g/mL), dynamic viscosity $\mu$ (cP), surface tension $\gamma$ (mN/m), and wetting contact angle $\theta$ on polypropylene. Instantiate a `LiquidProperties` record in `fluidics/liquid_properties.nut`.

### Step 2: Gravimetric Volumetric Assessment
1. Mount a 96-well flat plate onto an analytical micro-balance (0.01 mg resolution).
2. Execute 24 replicate dispenses of nominal volume $V_{nom}$ using default aqueous settings.
3. Weigh the plate before and after each transfer:
   $$V_{actual} = \frac{m_{dispensed}}{\rho_{fluid}}$$
4. Compute accuracy bias ($Bias = \frac{\bar{V} - V_{nom}}{V_{nom}} \cdot 100\%$) and precision coefficient of variation ($CV = \frac{\sigma}{\bar{V}} \cdot 100\%$).

### Step 3: High-Speed Optical Inspection
- Dripping during transit: Increase `air_transport_gap_ul` and add 1 to 2 `pre_wetting_cycles`.
- Foam formation in target well: Set `sub_surface_dispense = true` and `blowout_volume_ul = 0.0`.
- Residual liquid clinging to tip exterior: Decrease tip `immersion_depth_mm` to 0.5 mm and enable `touch_off_enabled = true`.
- Under-aspiration due to cavitation: Reduce `aspiration_flow_rate_ul_s` by 50% and increase `delay_after_aspiration_s` to 2.0 seconds.

### Step 4: Register New Liquid Class
Define the class in `fluidics/liquid_classes.nut` inheriting from `LiquidClass`, and register it into the protocol execution engine.
