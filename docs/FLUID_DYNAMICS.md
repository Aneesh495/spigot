# Micro-Fluidic Dynamics & Mathematical Physics Derivations

This document provides rigorous mathematical derivations of the physical principles governing liquid handling in Spigot, including viscous resistance in conical nozzles, capillary pressure differentials, Rayleigh-Plateau droplet detachment, and air cushion compressibility.

---

## 1. Viscous Hydraulic Resistance in Conical Tapered Pipette Tips

Standard laboratory disposable pipette tips are not uniform cylinders; they are truncated hollow cones. The internal radius varies continuously along the axial length $z$, from a wide barrel radius $r_1$ at the top to a narrow orifice radius $r_2$ at the distal tip ($r_1 > r_2$).

### 1.1 Geometry of the Tapered Tip
Let the tip axis align with the coordinate $z \in [0, L]$, where $z = 0$ corresponds to the wide barrel ($r(0) = r_1$) and $z = L$ corresponds to the dispensing orifice ($r(L) = r_2$). Under uniform taper, the radius as a function of axial position $z$ is:
$$r(z) = r_1 + \left( \frac{r_2 - r_1}{L} \right) z$$

### 1.2 Elemental Resistance Integration
For an infinitesimal cylindrical slice of length $dz$, laminar Newtonian flow obeys the classical Hagen-Poiseuille differential equation:
$$dR_{hyd} = \frac{8 \mu}{\pi [r(z)]^4} dz$$

Integrating from $z = 0$ to $z = L$:
$$R_{hyd} = \int_0^L \frac{8 \mu}{\pi} \frac{dz}{\left[ r_1 + \frac{r_2 - r_1}{L} z \right]^4}$$

Let $u = r_1 + \frac{r_2 - r_1}{L} z$, such that $du = \frac{r_2 - r_1}{L} dz$. The integration limits transform to $u(0) = r_1$ and $u(L) = r_2$:
$$R_{hyd} = \frac{8 \mu}{\pi} \left( \frac{L}{r_2 - r_1} \right) \int_{r_1}^{r_2} u^{-4} du$$

Evaluating the integral:
$$\int_{r_1}^{r_2} u^{-4} du = \left[ -\frac{1}{3} u^{-3} \right]_{r_1}^{r_2} = \frac{1}{3} \left( \frac{1}{r_1^3} - \frac{1}{r_2^3} \right) = \frac{r_2^3 - r_1^3}{3 r_1^3 r_2^3}$$

Substituting back:
$$R_{hyd} = \frac{8 \mu L}{\pi (r_2 - r_1)} \cdot \frac{r_2^3 - r_1^3}{3 r_1^3 r_2^3}$$

Factoring the difference of cubes $r_2^3 - r_1^3 = (r_2 - r_1)(r_1^2 + r_1 r_2 + r_2^2)$:
$$R_{hyd} = \frac{8 \mu L}{\pi} \cdot \frac{r_1^2 + r_1 r_2 + r_2^2}{3 r_1^3 r_2^3}$$

This closed-form analytical expression is implemented in `fluidics/poiseuille_model.nut`. Notice that if $r_1 = r_2 = r$, the numerator becomes $3 r^2$ and denominator becomes $3 r^6$, collapsing correctly to the classical cylindrical result $R_{hyd} = \frac{8 \mu L}{\pi r^4}$.

---

## 2. Capillarity, Meniscus Curvature & Young-Laplace Pressure

At the air-liquid-solid contact boundary inside a narrow tip orifice or microplate well, interfacial surface tension causes a curved meniscus that introduces a Laplace pressure jump.

### 2.1 The Young-Laplace Discontinuity
For a spherical meniscus of radius of curvature $R_{curv}$ inside a circular tube of radius $r$, the contact angle $\theta$ with the tube wall determines the curvature:
$$R_{curv} = \frac{r}{\cos \theta}$$

The pressure discontinuity across the curved liquid-gas interface is:
$$\Delta P_{Laplace} = \frac{2 \gamma}{R_{curv}} = \frac{2 \gamma \cos \theta}{r}$$
where $\gamma$ is the liquid surface tension (N/m) and $\theta$ is the wetting contact angle on polypropylene.

### 2.2 Jurin's Law for Capillary Rise
When a pipette tip orifice contacts a liquid reservoir without active pumping, spontaneous capillary action draws fluid upward until hydrostatic head balances Laplace suction:
$$\rho g h_{rise} = \Delta P_{Laplace} = \frac{2 \gamma \cos \theta}{r}$$

Solving for the equilibrium capillary rise height $h_{rise}$:
$$h_{rise} = \frac{2 \gamma \cos \theta}{\rho g r}$$

In Spigot (`fluidics/capillary_model.nut`), this calculation dictates the pre-immersion boundary condition: when descending into small-volume wells, capillary intrusion is compensated by maintaining a slight positive air counter-pressure.

---

## 3. Rayleigh-Plateau Pendant Droplet Detachment & Touch-Off

During low-volume dispensing (e.g. 0.5 to 5.0 uL), fluid expelled through the nozzle forms a pendant droplet hanging at the tip orifice. The droplet remains attached until gravitational body force exceeds the perimeter surface tension holding it to the nozzle.

### 3.1 Tate's Law and Harkins-Brown Correction
The theoretical detachment volume $V_{tate}$ given by Tate's law equates gravity force to perimeter tension:
$$\rho V_{tate} g = 2 \pi r \gamma \implies V_{tate} = \frac{2 \pi r \gamma}{\rho g}$$

In practice, a neck develops during detachment (Rayleigh-Plateau instability), causing only a fraction $\psi \approx 0.60$ to $0.72$ of the drop to fall, leaving a satellite remnant on the tip. Harkins and Brown introduced the empirical correction factor $\psi(r / V^{1/3})$:
$$V_{crit} = \psi \left( \frac{r}{V_{tate}^{1/3}} \right) \cdot \frac{2 \pi r \gamma}{\rho g}$$

### 3.2 Spigot Touch-Off Criterion
For aqueous solutions dispensing from a 0.5 mm outer diameter tip:
$$V_{crit} \approx 10.0 \text{ to } 15.0 \ \mu\text{L}$$

When a protocol commands a dispense volume $V_{disp} < V_{crit}$, surface tension holds the droplet to the orifice, resulting in an incomplete transfer (0 uL delivered into well). Spigot (`fluidics/droplet_dynamics.nut`) detects this condition and automatically schedules a physical wall touch-off motion:
1. Translate pipette tip toward the inner wall of the target well at $0.7 \cdot r_{well}$.
2. Liquid wets the hydrophilic well wall, breaking the symmetric surface tension ring.
3. Capillary wicking pulls the droplet from the tip into the target well.
4. Retract along vertical centerline.

---

## 4. Air Displacement Compressibility & Hydrostatic Lag

In air-displacement pipetting workstations, a piston moves inside a cylinder to displace an enclosed volume of air. Unlike positive-displacement systems, the trapped air cushion acts as an elastic spring governed by the ideal gas law under isothermal conditions.

### 4.1 Isothermal Boyle Expansion
Let $P_0$ be ambient atmospheric pressure ($\approx 1013.25 \text{ mbar} = 101325 \text{ Pa}$) and $V_0$ be the volume of the internal air cushion (typically 200 to 1200 uL depending on tip size and plunger position).

When a liquid column of height $h_{col}$ and density $\rho$ is aspirated into the tip, it exerts a downward hydrostatic head:
$$\Delta P_{hyd} = \rho g h_{col}$$

The pressure inside the trapped air cushion drops to $P_1 = P_0 - \Delta P_{hyd}$. By Boyle's Law ($P_0 V_0 = P_1 V_1$):
$$V_1 = V_0 \cdot \frac{P_0}{P_0 - \Delta P_{hyd}}$$

The volumetric expansion of the air cushion $\Delta V_{exp}$ is:
$$\Delta V_{exp} = V_1 - V_0 = V_0 \left( \frac{P_0}{P_0 - \Delta P_{hyd}} - 1 \right) = V_0 \left( \frac{\Delta P_{hyd}}{P_0 - \Delta P_{hyd}} \right)$$

Because the air cushion expands, the actual aspirated liquid volume $V_{liq}$ is less than the commanded plunger displacement volume $V_{plunger}$:
$$V_{liq} = V_{plunger} - \Delta V_{exp}$$

Spigot (`fluidics/air_displacement.nut`) accounts for this elasticity by applying an over-aspiration compensation factor $\beta_{comp} = 1 + \frac{\Delta V_{exp}}{V_{plunger}}$, followed by an equilibration pause before tip withdrawal.

---

## 5. Dimensionless Transport Numbers in Pipetting

Spigot characterizes liquid classes using four fundamental dimensionless groups:

| Number | Formula | Physical Interpretation | Spigot Regimes |
|---|---|---|---|
| **Reynolds ($Re$)** | $\frac{\rho v D}{\mu}$ | Inertia vs Viscosity | $Re < 100$: Strictly laminar<br>$Re > 2300$: Turbulent (forbidden) |
| **Ohnesorge ($Oh$)** | $\frac{\mu}{\sqrt{\rho \gamma D}}$ | Viscosity vs Surface Tension & Inertia | $Oh < 0.1$: Clean droplet pinch-off<br>$Oh > 1.0$: Viscous filamentation |
| **Capillary ($Ca$)** | $\frac{\mu v}{\gamma}$ | Viscous Stress vs Interfacial Tension | $Ca \ll 1$: Meniscus retains spherical cap<br>$Ca \gg 1$: Viscous drag distorts meniscus |
| **Weber ($We$)** | $\frac{\rho v^2 D}{\gamma}$ | Fluid Inertia vs Surface Tension | $We < 1$: Capillarity dominates (bead formation)<br>$We > 10$: Droplet splashing / atomization |
