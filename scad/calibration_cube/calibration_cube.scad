// 20 mm calibration cube with embossed axis labels. Print to check dimensional accuracy.
size = 20;
label_depth = 0.6;

difference() {
    cube(size, center = true);
    // X label on +X face
    translate([size / 2 - label_depth, 0, 0]) rotate([90, 0, 90])
        linear_extrude(label_depth + 0.01) text("X", size = 10, halign = "center", valign = "center");
    // Y label on +Y face
    translate([0, size / 2 - label_depth, 0]) rotate([90, 0, 0]) mirror([0, 0, 1])
        linear_extrude(label_depth + 0.01) text("Y", size = 10, halign = "center", valign = "center");
    // Z label on top
    translate([0, 0, size / 2 - label_depth])
        linear_extrude(label_depth + 0.01) text("Z", size = 10, halign = "center", valign = "center");
}
