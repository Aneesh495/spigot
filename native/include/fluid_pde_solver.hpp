// Spigot C++ Native Fluid Dynamics 1D Navier-Stokes Solver
// Discretizes micro-capillary transient flow and pressure waves across pipette tip bores.

#ifndef SPIGOT_FLUID_PDE_SOLVER_HPP
#define SPIGOT_FLUID_PDE_SOLVER_HPP

#include <vector>
#include <cmath>
#include <string>

namespace spigot {

struct FluidParams {
    double density{1000.0};          // kg / m^3
    double dynamic_viscosity{0.001};  // Pa * s
    double surface_tension{0.0728};   // N / m
    double length{0.0512};            // m (51.2 mm)
    double r_barrel{0.002};           // m (2.0 mm radius)
    double r_orifice{0.00025};        // m (0.25 mm radius)
};

class FluidPDESolver {
public:
    explicit FluidPDESolver(const FluidParams& params, size_t grid_points = 100);

    // Advances the numerical simulation by dt seconds given target inlet pressure
    void step(double dt, double inlet_pressure_pa);

    // Returns the cross-section averaged flow rate at tip orifice in uL / s
    [[nodiscard]] double get_orifice_flow_rate_ul_s() const;

    // Returns current pressure drop across the tip in mbar
    [[nodiscard]] double get_pressure_drop_mbar() const;

    // Returns velocity at grid index
    [[nodiscard]] double get_velocity_at(size_t index) const;

    // Resets internal state
    void reset();

private:
    FluidParams params_;
    size_t n_points_{100};
    double dz_{0.0};
    std::vector<double> radius_;
    std::vector<double> velocity_;
    std::vector<double> pressure_;
};

} // namespace spigot

#endif // SPIGOT_FLUID_PDE_SOLVER_HPP
