// Spigot Native C++ Squirrel Host Executable

#include <iostream>
#include <vector>
#include <string>
#include <cstdarg>
#include <squirrel.h>
#include <sqstdio.h>
#include <sqstdaux.h>
#include <sqstdmath.h>
#include <sqstdstring.h>
#include <sqstdsystem.h>
#include "sq_bindings.hpp"

static void print_func(HSQUIRRELVM, const SQChar* format, ...) {
    va_list args;
    va_start(args, format);
    vprintf(format, args);
    va_end(args);
}

static void error_func(HSQUIRRELVM, const SQChar* format, ...) {
    va_list args;
    va_start(args, format);
    vfprintf(stderr, format, args);
    va_end(args);
}

int main(int argc, char* argv[]) {
    HSQUIRRELVM v = sq_open(2048);
    sq_setprintfunc(v, print_func, error_func);
    sqstd_seterrorhandlers(v);

    // Register standard libraries
    sq_pushroottable(v);
    sqstd_register_iolib(v);
    sqstd_register_mathlib(v);
    sqstd_register_stringlib(v);
    sqstd_register_systemlib(v);

    // Register native Spigot C++ acceleration bindings
    spigot::register_native_spigot_bindings(v);
    sq_pop(v, 1);

    if (argc < 2) {
        std::cout << "Spigot C++ Native Acceleration Host (Squirrel 3.2 embedded)\n";
        std::cout << "Usage: spigot_native <script.nut> [args...]\n";
        sq_close(v);
        return 0;
    }

    const char* script_path = argv[1];

    // Load compiled script closure onto stack
    if (SQ_SUCCEEDED(sqstd_loadfile(v, script_path, SQTrue))) {
        sq_pushroottable(v); // 'this' target for closure
        for (int i = 2; i < argc; ++i) {
            sq_pushstring(v, argv[i], -1);
        }
        if (SQ_FAILED(sq_call(v, argc - 1, SQFalse, SQTrue))) {
            sq_close(v);
            return 1;
        }
    } else {
        sq_close(v);
        return 1;
    }

    sq_close(v);
    return 0;
}
