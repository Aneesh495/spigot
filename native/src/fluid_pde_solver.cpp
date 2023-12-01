// Implementation of Spigot 1D Navier-Stokes numerical PDE solver

#include "fluid_pde_solver.hpp"
#include <algorithm>
#include <numbers>

namespace spigot {

FluidPDESolver::FluidPDESolver(const FluidParams& params, size_t grid_points)
    : params_(params), n_points_(grid_points) {
    dz_ = params_.length / static_cast<double>(n_points_ - 1);
    radius_.resize(n_points_);
    velocity_.resize(n_points_, 0.0);
    pressure_.resize(n_points_, 0.0);

    // Conical taper from barrel (index 0) to orifice (index n-1)
    for (size_t i = 0; i < n_points_; ++i) {
        double frac = static_cast<double>(i) / static_cast<double>(n_points_ - 1);
        radius_[i] = params_.r_barrel + (params_.r_orifice - params_.r_barrel) * frac;
    }
}

void FluidPDESolver::step(double dt, double inlet_pressure_pa) {
    if (dt <= 0.0) return;

    pressure_[0] = inlet_pressure_pa;
    pressure_[n_points_ - 1] = 0.0; // Ambient discharge

    // Linear pressure gradient approximation along bore
    for (size_t i = 1; i < n_points_ - 1; ++i) {
        double frac = static_cast<double>(i) / static_cast<double>(n_points_ - 1);
        pressure_[i] = inlet_pressure_pa * (1.0 - frac);
    }

    // Navier-Stokes momentum update:
    // du/dt = -(1/rho) * dp/dz - (8 * mu / (rho * r^2)) * u
    for (size_t i = 0; i < n_points_; ++i) {
        double dp_dz = -inlet_pressure_pa / params_.length;
        double r = radius_[i];
        double viscous_drag = (8.0 * params_.dynamic_viscosity * velocity_[i]) / (params_.density * r * r);
        double accel = (-dp_dz / params_.density) - viscous_drag;

        velocity_[i] += accel * dt;
        if (std::isnan(velocity_[i])) {
            velocity_[i] = 0.0;
        }
    }
}

double FluidPDESolver::get_orifice_flow_rate_ul_s() const {
    constexpr double pi = 3.14159265358979323846;
    double r_orif = params_.r_orifice;
    double area_m2 = pi * r_orif * r_orif;
    double flow_m3_s = area_m2 * velocity_.back();
    return flow_m3_s * 1e9; // 1 m^3 = 1e9 uL
}

double FluidPDESolver::get_pressure_drop_mbar() const {
    double dp_pa = pressure_.front() - pressure_.back();
    return dp_pa * 0.01; // 1 Pa = 0.01 mbar
}

double FluidPDESolver::get_velocity_at(size_t index) const {
    if (index >= velocity_.size()) return 0.0;
    return velocity_[index];
}

void FluidPDESolver::reset() {
    std::fill(velocity_.begin(), velocity_.end(), 0.0);
    std::fill(pressure_.begin(), pressure_.end(), 0.0);
}

} // namespace spigot
