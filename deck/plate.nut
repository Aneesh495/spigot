// Spigot Standard Microplate Models
// Defines 96-well, 384-well, and 1536-well microplates following ANSI/SLAS 1-2004 to 4-2004 specifications.

dofile("deck/labware_definition.nut");

class Plate96WellFlat extends Labware {
    constructor(id = "plate_96_flat", name = "96-Well Flat Bottom Microplate 360uL") {
        local geom = WellGeometry(WellShapeType.FLAT_CYLINDER, 10.9, 6.4, 0.0, 10.0);
        base.constructor(id, name, "PLATE", 8, 12, 9.0, 9.0, 14.38, 11.24, 14.35, geom);
    }
}

class Plate96WellVBottom extends Labware {
    constructor(id = "plate_96_v", name = "96-Well V-Bottom Microplate 220uL") {
        local geom = WellGeometry(WellShapeType.COMPOSITE_CONICAL, 11.2, 6.5, 4.0, 2.0);
        base.constructor(id, name, "PLATE", 8, 12, 9.0, 9.0, 14.38, 11.24, 14.35, geom);
    }
}

class Plate96WellRound extends Labware {
    constructor(id = "plate_96_u", name = "96-Well Round U-Bottom Microplate 320uL") {
        local geom = WellGeometry(WellShapeType.COMPOSITE_ROUND, 10.8, 6.4, 3.2, 4.0);
        base.constructor(id, name, "PLATE", 8, 12, 9.0, 9.0, 14.38, 11.24, 14.35, geom);
    }
}

class Plate384Well extends Labware {
    constructor(id = "plate_384", name = "384-Well High-Density Microplate 120uL") {
        local geom = WellGeometry(WellShapeType.COMPOSITE_CONICAL, 11.5, 3.8, 3.0, 1.5);
        base.constructor(id, name, "PLATE", 16, 24, 4.5, 4.5, 12.13, 8.99, 14.35, geom);
    }
}

class Plate1536Well extends Labware {
    constructor(id = "plate_1536", name = "1536-Well Ultra-High-Density Microplate 12uL") {
        local geom = WellGeometry(WellShapeType.COMPOSITE_CONICAL, 5.0, 1.6, 1.5, 0.3);
        base.constructor(id, name, "PLATE", 32, 48, 2.25, 2.25, 11.0, 7.8, 10.4, geom);
    }
}
