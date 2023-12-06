// Spigot Native Squirrel FFI Bindings Implementation

#include "sq_bindings.hpp"
#include "fluid_pde_solver.hpp"
#include "spatial_bvh.hpp"
#include <iostream>

namespace spigot {

// Helper to register native C closure
static void register_global_func(HSQUIRRELVM v, SQFUNCTION f, const SQChar* name) {
    sq_pushstring(v, name, -1);
    sq_newclosure(v, f, 0);
    sq_newslot(v, -3, SQFalse);
}

// Native function: native_fluid_solve_flow(density, viscosity, pressure_mbar) -> flow_rate_ul_s
static SQInteger native_fluid_solve_flow(HSQUIRRELVM v) {
    SQFloat density = 1000.0;
    SQFloat visc_cp = 1.0;
    SQFloat p_mbar = 10.0;

    sq_getfloat(v, 2, &density);
    sq_getfloat(v, 3, &visc_cp);
    sq_getfloat(v, 4, &p_mbar);

    FluidParams p;
    p.density = static_cast<double>(density);
    p.dynamic_viscosity = static_cast<double>(visc_cp) * 0.001;

    FluidPDESolver solver(p, 50);
    double p_pa = static_cast<double>(p_mbar) * 100.0;
    for (int i = 0; i < 20; ++i) {
        solver.step(0.001, p_pa);
    }

    double flow_ul_s = solver.get_orifice_flow_rate_ul_s();
    sq_pushfloat(v, static_cast<SQFloat>(flow_ul_s));
    return 1;
}

// Native function: native_bvh_test_collision(box_min_x, min_y, min_z, max_x, max_y, max_z) -> bool
static SQInteger native_bvh_test_collision(HSQUIRRELVM v) {
    SQFloat min_x = 0, min_y = 0, min_z = 0;
    SQFloat max_x = 0, max_y = 0, max_z = 0;

    sq_getfloat(v, 2, &min_x);
    sq_getfloat(v, 3, &min_y);
    sq_getfloat(v, 4, &min_z);
    sq_getfloat(v, 5, &max_x);
    sq_getfloat(v, 6, &max_y);
    sq_getfloat(v, 7, &max_z);

    Box test_box{
        Vec3{static_cast<double>(min_x), static_cast<double>(min_y), static_cast<double>(min_z)},
        Vec3{static_cast<double>(max_x), static_cast<double>(max_y), static_cast<double>(max_z)},
        "HEAD"
    };

    SpatialBVH bvh;
    // Add sample deck slots into BVH
    bvh.insert(Box{Vec3{20.0, 20.0, 0.0}, Vec3{147.76, 105.48, 50.0}, "SLOT_1"});
    bvh.insert(Box{Vec3{162.0, 20.0, 0.0}, Vec3{289.76, 105.48, 55.0}, "SLOT_2"});
    bvh.build();

    auto hit = bvh.query_collision(test_box);
    sq_pushbool(v, hit.has_value() ? SQTrue : SQFalse);
    return 1;
}

SQRESULT register_native_spigot_bindings(HSQUIRRELVM v) {
    register_global_func(v, native_fluid_solve_flow, "native_fluid_solve_flow");
    register_global_func(v, native_bvh_test_collision, "native_bvh_test_collision");
    return SQ_OK;
}

} // namespace spigot
