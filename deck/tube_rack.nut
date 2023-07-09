// Spigot Tube Rack Models
// Defines microcentrifuge tube racks (1.5 mL) and conical centrifuge tube racks (15 mL / 50 mL).

dofile("deck/labware_definition.nut");

class TubeRack24Eppendorf extends Labware {
    constructor(id = "tube_rack_24", name = "24-Tube Rack 1.5mL Microcentrifuge") {
        // 4 rows x 6 columns, pitch 18.0 mm
        local geom = WellGeometry(WellShapeType.COMPOSITE_CONICAL, 38.0, 10.5, 8.0, 15.0);
        base.constructor(id, name, "TUBE_RACK", 4, 6, 18.0, 18.0, 18.88, 15.74, 42.0, geom);
        foreach (w in well_list) {
            w.geometry.max_volume_ul = 1500.0;
        }
    }
}

class TubeRack6Falcon15mL extends Labware {
    constructor(id = "tube_rack_6_falcon", name = "6-Tube Rack 15mL Conical") {
        // 2 rows x 3 columns, pitch 35.0 mm
        local geom = WellGeometry(WellShapeType.COMPOSITE_CONICAL, 115.0, 16.5, 20.0, 50.0);
        base.constructor(id, name, "TUBE_RACK", 2, 3, 35.0, 35.0, 28.88, 25.24, 120.0, geom);
        foreach (w in well_list) {
            w.geometry.max_volume_ul = 15000.0;
        }
    }
}
