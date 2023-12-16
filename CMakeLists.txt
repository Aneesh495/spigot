cmake_minimum_required(VERSION 3.20)
project(spigot_native VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Homebrew paths on Apple Silicon and Intel macOS
list(APPEND CMAKE_PREFIX_PATH "/opt/homebrew" "/usr/local")

find_path(SQUIRREL_INCLUDE_DIR squirrel.h PATHS /opt/homebrew/include /usr/local/include)
find_library(SQUIRREL_LIB NAMES squirrel PATHS /opt/homebrew/lib /usr/local/lib)
find_library(SQSTDLIB_LIB NAMES sqstdlib PATHS /opt/homebrew/lib /usr/local/lib)

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/native/include
    ${SQUIRREL_INCLUDE_DIR}
)

set(SPIGOT_SOURCES
    native/src/fluid_pde_solver.cpp
    native/src/spatial_bvh.cpp
    native/src/sq_bindings.cpp
    native/src/main.cpp
)

add_executable(spigot_native ${SPIGOT_SOURCES})

target_link_libraries(spigot_native
    PRIVATE
    ${SQUIRREL_LIB}
    ${SQSTDLIB_LIB}
)

set_target_properties(spigot_native PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/bin"
)
