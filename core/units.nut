// Spigot Core Units and Physical Constants
// Provides dimensional transformations, unit conversions, and physical constants for fluidics and kinematics.

// Physical Constants
const GRAVITY_M_S2 = 9.80665;
const ATMOSPHERIC_PRESSURE_PA = 101325.0;
const ATMOSPHERIC_PRESSURE_MBAR = 1013.25;
const UNIVERSAL_GAS_CONSTANT_J_MOL_K = 8.314462;
const STANDARD_TEMP_KELVIN = 293.15; // 20.0 Celsius

// Standard Fluid Properties at 20 C
const WATER_DENSITY_KG_M3 = 1000.0;
const WATER_DENSITY_MG_UL = 1.0;
const WATER_SURFACE_TENSION_N_M = 0.0728;
const WATER_VISCOSITY_PA_S = 0.001002; // 1.002 cP

// Volume conversions
function ul_to_ml(ul) {
    return ul.tofloat() * 0.001;
}

function ml_to_ul(ml) {
    return ml.tofloat() * 1000.0;
}

function ul_to_nl(ul) {
    return ul.tofloat() * 1000.0;
}

function nl_to_ul(nl) {
    return nl.tofloat() * 0.001;
}

function l_to_ul(liters) {
    return liters.tofloat() * 1000000.0;
}

function ul_to_m3(ul) {
    return ul.tofloat() * 1e-9;
}

function m3_to_ul(m3) {
    return m3.tofloat() * 1e9;
}

// Distance conversions
function mm_to_m(mm) {
    return mm.tofloat() * 0.001;
}

function m_to_mm(m) {
    return m.tofloat() * 1000.0;
}

function um_to_mm(um) {
    return um.tofloat() * 0.001;
}

function mm_to_um(mm) {
    return mm.tofloat() * 1000.0;
}

function in_to_mm(inches) {
    return inches.tofloat() * 25.4;
}

function mm_to_in(mm) {
    return mm.tofloat() / 25.4;
}

// Pressure conversions
function mbar_to_pa(mbar) {
    return mbar.tofloat() * 100.0;
}

function pa_to_mbar(pa) {
    return pa.tofloat() * 0.01;
}

function psi_to_pa(psi) {
    return psi.tofloat() * 6894.757;
}

function pa_to_psi(pa) {
    return pa.tofloat() / 6894.757;
}

function atm_to_pa(atm) {
    return atm.tofloat() * 101325.0;
}

// Viscosity conversions
function cp_to_pa_s(cp) {
    return cp.tofloat() * 0.001;
}

function pa_s_to_cp(pa_s) {
    return pa_s.tofloat() * 1000.0;
}

// Time conversions
function s_to_ms(s) {
    return s.tofloat() * 1000.0;
}

function ms_to_s(ms) {
    return ms.tofloat() * 0.001;
}

function min_to_s(minutes) {
    return minutes.tofloat() * 60.0;
}

function hr_to_s(hours) {
    return hours.tofloat() * 3600.0;
}

// Angular conversions
function deg_to_rad(deg) {
    return deg.tofloat() * (PI / 180.0);
}

function rad_to_deg(rad) {
    return rad.tofloat() * (180.0 / PI);
}

// Temperature conversions
function c_to_k(celsius) {
    return celsius.tofloat() + 273.15;
}

function k_to_c(kelvin) {
    return kelvin.tofloat() - 273.15;
}
