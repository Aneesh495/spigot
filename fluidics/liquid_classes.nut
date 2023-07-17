// Spigot Calibrated Liquid Class Specifications
// Defines pipetting dynamics parameters for aqueous, viscous, volatile, and detergent fluids.

dofile("fluidics/liquid_properties.nut");

class LiquidClass {
    name = "Standard_Aqueous";
    properties = null; // LiquidProperties

    // Pipetting dynamics parameters
    aspiration_flow_rate_ul_s = 40.0;
    dispense_flow_rate_ul_s = 60.0;
    delay_after_aspiration_s = 0.5;
    delay_after_dispense_s = 0.3;
    pre_wetting_cycles = 0;
    air_transport_gap_ul = 0.0;
    blowout_volume_ul = 10.0;
    sub_surface_dispense = false;
    touch_off_enabled = true;
    immersion_depth_mm = 1.0; // Immersion depth below meniscus

    constructor(lc_name, props) {
        name = lc_name;
        properties = props;
    }
}

class StandardAqueousClass extends LiquidClass {
    constructor() {
        local props = LiquidProperties("Water_Aqueous", 1000.0, 1.002, 0.0728, 45.0, 2.34, 0.0);
        base.constructor("Standard_Aqueous", props);
        aspiration_flow_rate_ul_s = 50.0;
        dispense_flow_rate_ul_s = 80.0;
        delay_after_aspiration_s = 0.3;
        delay_after_dispense_s = 0.2;
        pre_wetting_cycles = 0;
        air_transport_gap_ul = 0.0;
        blowout_volume_ul = 8.0;
        sub_surface_dispense = false;
        touch_off_enabled = true;
        immersion_depth_mm = 1.0;
    }
}

class ViscousGlycerol50Class extends LiquidClass {
    constructor() {
        local props = LiquidProperties("Glycerol_50", 1130.0, 6.0, 0.068, 55.0, 0.1, 0.1);
        base.constructor("Viscous_Glycerol50", props);
        aspiration_flow_rate_ul_s = 15.0; // Slower aspiration to prevent cavitation
        dispense_flow_rate_ul_s = 20.0;
        delay_after_aspiration_s = 1.5; // Extended equilibration delay
        delay_after_dispense_s = 1.2;
        pre_wetting_cycles = 1;
        air_transport_gap_ul = 5.0;
        blowout_volume_ul = 15.0;
        sub_surface_dispense = false;
        touch_off_enabled = true;
        immersion_depth_mm = 1.5;
    }
}

class ViscousGlycerol80Class extends LiquidClass {
    constructor() {
        local props = LiquidProperties("Glycerol_80", 1210.0, 60.0, 0.065, 65.0, 0.02, 0.2);
        base.constructor("Viscous_Glycerol80", props);
        aspiration_flow_rate_ul_s = 5.0; // Very slow aspiration for high viscosity
        dispense_flow_rate_ul_s = 8.0;
        delay_after_aspiration_s = 3.0; // 3 seconds equilibration delay
        delay_after_dispense_s = 2.5;
        pre_wetting_cycles = 1;
        air_transport_gap_ul = 8.0;
        blowout_volume_ul = 25.0;
        sub_surface_dispense = false;
        touch_off_enabled = true;
        immersion_depth_mm = 2.0;
    }
}

class VolatileEthanol70Class extends LiquidClass {
    constructor() {
        local props = LiquidProperties("Ethanol_70", 860.0, 2.3, 0.028, 20.0, 5.9, 0.0);
        base.constructor("Volatile_Ethanol70", props);
        aspiration_flow_rate_ul_s = 30.0;
        dispense_flow_rate_ul_s = 50.0;
        delay_after_aspiration_s = 0.5;
        delay_after_dispense_s = 0.3;
        pre_wetting_cycles = 2; // Vapor equilibration to prevent dripping
        air_transport_gap_ul = 10.0; // Air gap seals liquid in tip
        blowout_volume_ul = 12.0;
        sub_surface_dispense = false;
        touch_off_enabled = true;
        immersion_depth_mm = 1.0;
    }
}

class VolatileEthanol100Class extends LiquidClass {
    constructor() {
        local props = LiquidProperties("Ethanol_100", 789.0, 1.2, 0.022, 15.0, 7.8, 0.0);
        base.constructor("Volatile_Ethanol100", props);
        aspiration_flow_rate_ul_s = 25.0;
        dispense_flow_rate_ul_s = 40.0;
        delay_after_aspiration_s = 0.8;
        delay_after_dispense_s = 0.5;
        pre_wetting_cycles = 3;
        air_transport_gap_ul = 15.0;
        blowout_volume_ul = 15.0;
        sub_surface_dispense = false;
        touch_off_enabled = true;
        immersion_depth_mm = 1.0;
    }
}

class DetergentTritonClass extends LiquidClass {
    constructor() {
        local props = LiquidProperties("Detergent_Triton", 1060.0, 15.0, 0.030, 25.0, 0.1, 0.9);
        base.constructor("Detergent_Triton", props);
        aspiration_flow_rate_ul_s = 15.0;
        dispense_flow_rate_ul_s = 15.0;
        delay_after_aspiration_s = 1.0;
        delay_after_dispense_s = 1.0;
        pre_wetting_cycles = 1;
        air_transport_gap_ul = 0.0;
        blowout_volume_ul = 0.0; // Zero blowout to prevent bubbling and foaming
        sub_surface_dispense = true; // Must dispense sub-surface
        touch_off_enabled = false;
        immersion_depth_mm = 0.8;
    }
}

class BiologicalSerumClass extends LiquidClass {
    constructor() {
        local props = LiquidProperties("Blood_Serum", 1025.0, 1.8, 0.055, 40.0, 2.2, 0.5);
        base.constructor("Biological_Serum", props);
        aspiration_flow_rate_ul_s = 20.0;
        dispense_flow_rate_ul_s = 35.0;
        delay_after_aspiration_s = 1.0;
        delay_after_dispense_s = 0.8;
        pre_wetting_cycles = 1;
        air_transport_gap_ul = 5.0;
        blowout_volume_ul = 10.0;
        sub_surface_dispense = false;
        touch_off_enabled = true;
        immersion_depth_mm = 0.8;
    }
}
