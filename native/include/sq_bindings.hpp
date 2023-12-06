// Spigot Squirrel C++ FFI Bindings Header
// Declares registration routines to expose native fluid solvers and BVH trees to Squirrel scripts.

#ifndef SPIGOT_SQ_BINDINGS_HPP
#define SPIGOT_SQ_BINDINGS_HPP

#include <squirrel.h>

namespace spigot {

// Registers all native Spigot C++ classes into the Squirrel VM root table.
SQRESULT register_native_spigot_bindings(HSQUIRRELVM v);

} // namespace spigot

#endif // SPIGOT_SQ_BINDINGS_HPP
