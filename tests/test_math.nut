// Unit tests for Vector3 and AABB geometric primitives

dofile("tests/assert.nut");
dofile("core/math.nut");
dofile("core/aabb.nut");

local suite = TestSuite("Vector3 and AABB Test Suite");

// Vector3 arithmetic
local v1 = Vector3(1.0, 2.0, 3.0);
local v2 = Vector3(4.0, 5.0, 6.0);

local v_sum = v1.add(v2);
suite.assert_near(v_sum.x, 5.0, 1e-6, "Vector addition X");
suite.assert_near(v_sum.y, 7.0, 1e-6, "Vector addition Y");
suite.assert_near(v_sum.z, 9.0, 1e-6, "Vector addition Z");

local v_diff = v2.sub(v1);
suite.assert_near(v_diff.x, 3.0, 1e-6, "Vector subtraction X");
suite.assert_near(v_diff.y, 3.0, 1e-6, "Vector subtraction Y");
suite.assert_near(v_diff.z, 3.0, 1e-6, "Vector subtraction Z");

local v_scale = v1.scale(2.5);
suite.assert_near(v_scale.x, 2.5, 1e-6, "Vector scale X");
suite.assert_near(v_scale.y, 5.0, 1e-6, "Vector scale Y");
suite.assert_near(v_scale.z, 7.5, 1e-6, "Vector scale Z");

local v_div = v2.divide(2.0);
suite.assert_near(v_div.x, 2.0, 1e-6, "Vector divide X");
suite.assert_near(v_div.y, 2.5, 1e-6, "Vector divide Y");
suite.assert_near(v_div.z, 3.0, 1e-6, "Vector divide Z");

// Vector length and distance
local v_len_test = Vector3(3.0, 4.0, 0.0);
suite.assert_near(v_len_test.length(), 5.0, 1e-6, "Vector length");
suite.assert_near(v_len_test.length_squared(), 25.0, 1e-6, "Vector length squared");

local p1 = Vector3(1.0, 1.0, 1.0);
local p2 = Vector3(4.0, 5.0, 1.0);
suite.assert_near(p1.distance_to(p2), 5.0, 1e-6, "Distance between points");

// Dot and Cross product
local vx = Vector3(1.0, 0.0, 0.0);
local vy = Vector3(0.0, 1.0, 0.0);
suite.assert_near(vx.dot(vy), 0.0, 1e-6, "Orthogonal dot product");
suite.assert_near(vx.dot(vx), 1.0, 1e-6, "Unit dot product");

local vz = vx.cross(vy);
suite.assert_near(vz.x, 0.0, 1e-6, "Cross product X");
suite.assert_near(vz.y, 0.0, 1e-6, "Cross product Y");
suite.assert_near(vz.z, 1.0, 1e-6, "Cross product Z");

// Interpolation (lerp)
local v_lerp = vx.lerp(vy, 0.5);
suite.assert_near(v_lerp.x, 0.5, 1e-6, "Vector lerp X");
suite.assert_near(v_lerp.y, 0.5, 1e-6, "Vector lerp Y");
suite.assert_near(v_lerp.z, 0.0, 1e-6, "Vector lerp Z");

// Normalization
local v_norm = Vector3(0.0, 10.0, 0.0).normalize();
suite.assert_near(v_norm.x, 0.0, 1e-6, "Normalize X");
suite.assert_near(v_norm.y, 1.0, 1e-6, "Normalize Y");
suite.assert_near(v_norm.z, 0.0, 1e-6, "Normalize Z");
suite.assert_near(v_norm.length(), 1.0, 1e-6, "Normalized length is unity");

// AABB tests
local box1 = AABB(Vector3(0.0, 0.0, 0.0), Vector3(100.0, 80.0, 50.0));
suite.assert_near(box1.width(), 100.0, 1e-6, "AABB width");
suite.assert_near(box1.depth(), 80.0, 1e-6, "AABB depth");
suite.assert_near(box1.height(), 50.0, 1e-6, "AABB height");
suite.assert_near(box1.volume(), 400000.0, 1e-6, "AABB volume");

local c = box1.center();
suite.assert_near(c.x, 50.0, 1e-6, "AABB center X");
suite.assert_near(c.y, 40.0, 1e-6, "AABB center Y");
suite.assert_near(c.z, 25.0, 1e-6, "AABB center Z");

// Point containment
suite.assert_true(box1.contains_point(Vector3(50.0, 40.0, 25.0)), "Center point is inside box");
suite.assert_true(box1.contains_point(Vector3(0.0, 0.0, 0.0)), "Corner point is inside box");
suite.assert_false(box1.contains_point(Vector3(105.0, 40.0, 25.0)), "Outside point is not inside box");

// Intersections
local box2 = AABB(Vector3(50.0, 40.0, 20.0), Vector3(150.0, 120.0, 80.0));
suite.assert_true(box1.intersects(box2), "Overlapping boxes intersect");

local box_disjoint = AABB(Vector3(200.0, 200.0, 200.0), Vector3(300.0, 300.0, 300.0));
suite.assert_false(box1.intersects(box_disjoint), "Disjoint boxes do not intersect");

local isect = box1.intersection(box2);
suite.assert_true(isect != null, "Intersection box is non-null");
suite.assert_near(isect.min.x, 50.0, 1e-6, "Intersection min X");
suite.assert_near(isect.max.x, 100.0, 1e-6, "Intersection max X");
suite.assert_near(isect.min.y, 40.0, 1e-6, "Intersection min Y");
suite.assert_near(isect.max.y, 80.0, 1e-6, "Intersection max Y");
suite.assert_near(isect.min.z, 20.0, 1e-6, "Intersection min Z");
suite.assert_near(isect.max.z, 50.0, 1e-6, "Intersection max Z");

// Union
local ubox = box1.union_box(box2);
suite.assert_near(ubox.min.x, 0.0, 1e-6, "Union min X");
suite.assert_near(ubox.max.x, 150.0, 1e-6, "Union max X");
suite.assert_near(ubox.min.y, 0.0, 1e-6, "Union min Y");
suite.assert_near(ubox.max.y, 120.0, 1e-6, "Union max Y");

// Translation and Expansion
local moved = box1.translate(Vector3(10.0, 20.0, 30.0));
suite.assert_near(moved.min.x, 10.0, 1e-6, "Moved min X");
suite.assert_near(moved.max.x, 110.0, 1e-6, "Moved max X");

local expanded = box1.expand(5.0);
suite.assert_near(expanded.min.x, -5.0, 1e-6, "Expanded min X");
suite.assert_near(expanded.max.x, 105.0, 1e-6, "Expanded max X");

local success = suite.summary();
if (!success) {
    throw "Vector3 and AABB tests failed.";
}
