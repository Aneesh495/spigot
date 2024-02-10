# Assay Protocol Authoring Guide

Spigot provides an expressive, object-oriented API in Squirrel 3.2 for composing complex laboratory bio-assays from reusable fluidic and robotic primitives.

---

## 1. The `AssayProtocol` Base Architecture

All assay protocols inherit from `AssayProtocol` (`protocols/protocol_base.nut`). The base class provides:
- Automated gantry path planning and safe Z-axis corridor management.
- Dynamic meniscus tracking and tip immersion targeting.
- Plunger actuation with physical stroke limits.
- Consumable tip management and disposal accounting.
- Volume balance logging and contamination audit trail generation.

```squirrel
dofile("protocols/protocol_base.nut");

class MyCustomAssay extends AssayProtocol {
    constructor() {
        base.constructor("MyCustomAssay", "Demonstration assay protocol");
        // Deck initialization and consumable configuration
    }

    function run() {
        // High-level assay execution logic
    }
}
```

---

## 2. Core Pipetting Primitives

### 2.1 Single-Transfer: `transfer()`
Executes an end-to-end liquid transfer from a single source well to a single target well:
```squirrel
transfer(src_well, tgt_well, volume_ul, lclass = null, tip_rack = null, channel = 0, new_tip = false, touch_off = true);
```
- Automatically picks a fresh tip from `tip_rack` if the nozzle is currently bare.
- Computes source liquid height and targets tip immersion to `meniscus_z - immersion_depth_mm`.
- Aspirates `volume_ul` with plunger over-stroke for air cushion compensation.
- Retracts to safe Z clearance, moves to target well, and dispenses with blowout.
- Executes wall touch-off if required by droplet surface tension.

### 2.2 Reagent Distribution: `distribute()`
Dispenses a common reagent from one reservoir into an array of target wells:
```squirrel
distribute(src_reservoir_well, [well_A1, well_A2, well_A3], 50.0, "Standard_Aqueous", tip_rack);
```
If total volume fits within tip capacity ($V_{total} \le V_{tip}$), Spigot performs a batch aspiration and multi-dispenses across targets, minimizing travel time and gantry cycles.

### 2.3 In-Place Mixing: `mix()`
Homogenizes contents of a well by repeated aspiration and dispensing:
```squirrel
mix(target_well, 80.0, 5, channel); // 80 uL stroke, 5 repetitions
```
Performs mixing sub-surface with smooth plunger velocity ramps to prevent bubble entrapment, finishing with a surface blowout stroke.

### 2.4 Tip Management: `pick_tip_from_rack()` & `eject_tip_to_waste()`
- `pick_tip_from_rack(tip_rack, channel)`: Locates the next available tip, moves to position, press-fits into collar, and updates tip inventory.
- `eject_tip_to_waste(channel)`: Transits to the deck waste chute and fires the mechanical tip stripper sleeve.

---

## 3. Walkthrough: The 7 Standard Protocols

Spigot includes 7 production-grade assay protocols:

### 3.1 12-Point Serial Dilution (`protocols/serial_dilution.nut`)
Generates a two-fold serial dilution across a 96-well plate row:
1. Dispenses 100 uL diluent buffer from reservoir channel 1 across wells 2 through 12.
2. Dispenses 200 uL high-concentration stock into well 1.
3. For each step $i \in [1, 11]$: aspirates 100 uL from well $i$, transfers to well $i+1$, and mixes 3 times.
4. Final well 12 serves as background control or has 100 uL discarded to waste.

### 3.2 96-Well qPCR Reaction Setup (`protocols/pcr_setup.nut`)
Assembles quantitative real-time PCR reaction mixtures:
1. Distributes master mix (polymerase, dNTPs, buffer, SYBR Green) across 96 reaction wells.
2. Adds forward and reverse primer pairs from 24-tube racks using fresh tips.
3. Adds template DNA (or nuclease-free water for No Template Controls - NTC).

### 3.3 Sandwich ELISA with Automated 3x Wash Cycles (`protocols/elisa_assay.nut`)
Performs antibody-antigen sandwich immunoassay:
1. Sample incubation in pre-coated capture antibody microplate.
2. Triple wash cycle: dispenses 300 uL PBST wash buffer, pauses 30 s, and completely evacuates wells to waste.
3. Detection antibody addition and secondary wash.
4. TMB substrate addition for color development, followed by 1M H2SO4 stop solution.
5. End-point optical density measurement at 450 nm on the microplate reader station.

### 3.4 Magnetic Bead SPRI Nucleic Acid Extraction (`protocols/magnetic_bead_extraction.nut`)
Extracts genomic DNA/RNA using Solid-Phase Reversible Immobilization paramagnetic beads:
1. Binds nucleic acid to carboxylated magnetic beads in polyethylene glycol / salt buffer.
2. Engages 96-ring neodymium magnetic separator block to pull down bead pellets against well skirts.
3. Evacuates supernatant to liquid waste.
4. Performs 2x 70% ethanol washes with air-gap volatile pipetting.
5. Air-dries bead pellet to evaporate ethanol remnants.
6. Disengages magnets, dispenses 10 mM Tris-HCl elution buffer, and resuspends pellet by mixing.

### 3.5 High-Throughput Compound Cherry-Picking (`protocols/cherry_picking.nut`)
Selects active screening hits from 96-well compound libraries into target validation plates using worklist specifications, validating volume limits and logging carryover provenance.

### 3.6 Next-Generation Sequencing (NGS) Library Preparation (`protocols/ngs_library_prep.nut`)
Orchestrates multi-step enzymatic reactions:
1. End-Repair & A-tailing: mixes fragmented DNA with repair enzyme master mix, incubates at 20 C for 30 min and 65 C for 30 min on the Peltier thermal cycler.
2. Adapter Ligation: adds barcoded sequencing adapters and T4 DNA ligase.
3. Post-ligation SPRI bead clean-up to size-select adapter-ligated library fragments.

### 3.7 Michaelis-Menten Enzyme Kinetics Screen (`protocols/enzyme_kinetics_screen.nut`)
Evaluates enzyme catalytic efficiency ($V_{max}, K_m$):
1. Titrates chromogenic substrate (e.g. ONPG for beta-galactosidase) across 8 concentration gradients.
2. Injects enzyme stock synchronously across rows using multichannel gantry.
3. Performs kinetic absorbance reads every 15 seconds at 405 nm on the microplate reader station.
4. Fits initial velocities $v_0$ against substrate concentration $[S]$ to extract $K_m$ and $V_{max}$.
