// Spigot Reagent Reservoir Models
// Defines multichannel reagent troughs with pyramidal baffled bottoms for dead volume minimization.

dofile("deck/labware_definition.nut");

class Reservoir12Channel extends Labware {
    constructor(id = "reservoir_12", name = "12-Channel Reagent Reservoir 22mL") {
        // 12 columns, 1 row, 9.0 mm column pitch
        local geom = WellGeometry(WellShapeType.PYRAMIDAL_TROUGH, 32.0, 8.0, 5.0, 50.0);
        base.constructor(id, name, "RESERVOIR", 1, 12, 9.0, 71.0, 14.38, 7.24, 35.0, geom);
        // Override max volume for 22 mL per channel
        foreach (w in well_list) {
            w.geometry.max_volume_ul = 22000.0;
        }
    }
}

class Reservoir1ChannelBulk extends Labware {
    constructor(id = "reservoir_1_bulk", name = "1-Channel Bulk Reagent Reservoir 190mL") {
        local geom = WellGeometry(WellShapeType.PYRAMIDAL_TROUGH, 35.0, 75.0, 0.0, 500.0);
        base.constructor(id, name, "RESERVOIR", 1, 1, 0.0, 0.0, 63.88, 42.74, 38.0, geom);
        well_list[0].geometry.max_volume_ul = 190000.0;
    }
}
