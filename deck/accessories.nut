// Spigot Active Deck Accessories
// Models magnetic separation blocks, thermal cyclers / peltier shakers, and microplate readers.

dofile("deck/labware_definition.nut");

class MagneticSeparationBlock extends Labware {
    is_magnet_engaged = false;
    engagement_travel_time_s = 2.5;
    magnet_type = "RING_MAGNET"; // RING_MAGNET or POST_MAGNET

    constructor(id = "mag_block", name = "96-Well Ring Magnetic Separation Block") {
        local geom = WellGeometry(WellShapeType.FLAT_CYLINDER, 14.0, 7.0, 0.0, 0.0);
        base.constructor(id, name, "ACCESSORY", 8, 12, 9.0, 9.0, 14.38, 11.24, 25.0, geom);
        is_magnet_engaged = false;
        engagement_travel_time_s = 2.5;
        magnet_type = "RING_MAGNET";
    }

    // Engages the magnetic array upward into the plate skirts to pull down magnetic beads.
    function engage_magnets() {
        is_magnet_engaged = true;
    }

    // Retracts the magnetic array downward to release bead pellets for resuspension.
    function disengage_magnets() {
        is_magnet_engaged = false;
    }

    function is_engaged() {
        return is_magnet_engaged;
    }
}

class PeltierThermalShaker extends Labware {
    target_temperature_c = 20.0;
    current_temperature_c = 20.0;
    heating_rate_c_per_s = 2.5;
    cooling_rate_c_per_s = 1.2;
    shaking_rpm = 0;
    is_shaking = false;

    constructor(id = "thermal_shaker", name = "Peltier Thermal Shaker 4-95C") {
        local geom = WellGeometry(WellShapeType.FLAT_CYLINDER, 14.0, 7.0, 0.0, 0.0);
        base.constructor(id, name, "ACCESSORY", 8, 12, 9.0, 9.0, 14.38, 11.24, 35.0, geom);
        target_temperature_c = 20.0;
        current_temperature_c = 20.0;
        is_shaking = false;
    }

    function set_temperature(temp_c) {
        if (temp_c < 4.0 || temp_c > 99.0) {
            throw "TemperatureOutOfRangeException: Commanded temperature " + temp_c + " C exceeds range [4.0, 99.0] C";
        }
        target_temperature_c = temp_c.tofloat();
    }

    function start_shaking(rpm = 800) {
        if (rpm < 100 || rpm > 2200) {
            throw "ShakerSpeedOutOfRangeException: Commanded speed " + rpm + " RPM exceeds range [100, 2200] RPM";
        }
        shaking_rpm = rpm;
        is_shaking = true;
    }

    function stop_shaking() {
        shaking_rpm = 0;
        is_shaking = false;
    }

    // Advances thermal state simulation by delta seconds.
    function step_thermal_simulation(dt_seconds) {
        local dt = dt_seconds.tofloat();
        if (abs(current_temperature_c - target_temperature_c) < 0.1) {
            current_temperature_c = target_temperature_c;
            return;
        }

        if (current_temperature_c < target_temperature_c) {
            current_temperature_c += heating_rate_c_per_s * dt;
            if (current_temperature_c > target_temperature_c) {
                current_temperature_c = target_temperature_c;
            }
        } else {
            current_temperature_c -= cooling_rate_c_per_s * dt;
            if (current_temperature_c < target_temperature_c) {
                current_temperature_c = target_temperature_c;
            }
        }
    }
}

class MicroplateReaderStation extends Labware {
    supported_wavelengths = null;
    current_wavelength_nm = 450;

    constructor(id = "plate_reader", name = "Spectrophotometric Microplate Reader 450/600nm") {
        local geom = WellGeometry(WellShapeType.FLAT_CYLINDER, 14.0, 7.0, 0.0, 0.0);
        base.constructor(id, name, "ACCESSORY", 8, 12, 9.0, 9.0, 14.38, 11.24, 40.0, geom);
        supported_wavelengths = [405, 450, 490, 595, 600, 650];
        current_wavelength_nm = 450;
    }

    function set_wavelength(wavelength_nm) {
        local found = false;
        foreach (wl in supported_wavelengths) {
            if (wl == wavelength_nm) {
                found = true;
                break;
            }
        }
        if (!found) {
            throw "UnsupportedWavelengthException: Wavelength " + wavelength_nm + " nm not in supported filter wheel";
        }
        current_wavelength_nm = wavelength_nm;
    }

    // Reads simulated absorbance for a target microplate sitting on the reader nest.
    function read_absorbance_matrix(plate) {
        local absorbance_map = {};
        foreach (w in plate.well_list) {
            // Absorbance = pathlength * extinction_coefficient * concentration (Beer-Lambert law)
            // Pathlength is liquid height in cm: h_cm = h_mm * 0.1
            local pathlength_cm = w.get_liquid_height() * 0.1;
            local solute_conc = w.solutes.rawin("substrate_product") ? w.solutes["substrate_product"] : 0.0;
            local baseline = 0.035; // Plastic plate baseline absorbance
            local signal = baseline + (pathlength_cm * solute_conc * 1.8);
            absorbance_map[w.id] <- signal;
        }
        return absorbance_map;
    }
}
