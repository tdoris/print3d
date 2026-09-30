// Tiny chuck glider.
//
// Four printed parts, no glue required:
//   * fuselage  - modelled upright, printed lying on its right side so the
//                 slot widths are drawn in-plane (accurate) rather than
//                 bridged. Two angled slots for the wing halves (dihedral +
//                 incidence), a through-slot for the tailplane, a nose
//                 ballast pocket and a CG notch on top.
//   * wing x2   - thin flat skin with two spanwise spars on top, printed
//                 flat. Root tab plugs into the fuselage. Left half is a
//                 mirror of the right.
//   * tailplane - flat plate, slides through the boom.
//
// Set `part` to "plate" for the print layout, "assembled" to check the model,
// or one of "fuselage" / "wing_r" / "wing_l" / "tail" for individual exports.
part = "plate";

// ---- Wing -----------------------------------------------------------------
half_span   = 125;     // per side, excluding the root tab
root_chord  = 45;
tip_chord   = 30;
tip_round   = 5;       // corner radius at the tip
skin_t      = 0.45;    // wing skin thickness (3 layers at 0.15 mm)
spar_w      = 1.2;     // spanwise spars on the top surface
spar_h      = 1.0;
spar_at     = [0.22, 0.55];   // spar positions as fraction of root chord
tab_len     = 4.0;     // root tab that goes into the fuselage (per side)
tab_x0      = 5;       // tab runs from this chord station ...
tab_x1      = 27;      // ... to this one
tab_t       = 0.75;    // tab thickness (5 layers at 0.15 mm)
dihedral    = 6;       // degrees per side
incidence   = 3;       // wing angle relative to fuselage, degrees (LE up)
slot_clear  = 0.25;    // extra slot thickness / length for a push fit

// ---- Fuselage -------------------------------------------------------------
x_le        = 50;      // wing leading edge position from the nose
pod_len     = 80;      // solid nose pod, nose to where it starts tapering
pod_w       = 8;
pod_h       = 9;
boom_w      = 1.6;
boom_h0     = 4.5;     // boom height where it leaves the pod
boom_h1     = 3;       // boom height at the tail
fus_len     = 142;
wing_z      = 6.3;     // height of the wing slot centre line above the bottom
ballast_d   = 5;       // nose pocket diameter (BBs / screw / clay for trimming), enters from the left side
ballast_x   = 10;
ballast_depth = 7;

// ---- Tail -----------------------------------------------------------------
tail_span   = 80;
tail_root   = 20;
tail_tip    = 15;
tail_t      = 0.45;
tail_x      = fus_len - 26;   // tailplane leading edge position
fin_h       = 19;             // above the boom
fin_w       = 0.8;

// ---- Derived --------------------------------------------------------------
boom_y  = pod_w / 2 - boom_w / 2;       // boom centre line (flush with the right side)
lambda  = tip_chord / root_chord;
mac     = 2 / 3 * root_chord * (1 + lambda + lambda * lambda) / (1 + lambda);
cg_frac = 0.32;
x_cg    = x_le + cg_frac * mac;         // where the CG should end up
echo(str("MAC = ", mac, " mm, target CG at x = ", x_cg, " mm from the nose"));

$fn = 48;

// ---------------------------------------------------------------------------
module rounded_planform(root, tip, span, r) {
    // Straight leading edge along y, tapering trailing edge, rounded tip.
    offset(r = r) offset(delta = -r)
        polygon([[0, 0], [root, 0], [tip, span], [0, span]]);
}

// Right wing half, flat side down, root at y = 0, LE at x = 0.
module wing_half() {
    linear_extrude(skin_t) rounded_planform(root_chord, tip_chord, half_span, tip_round);
    // spars: follow the local chord so they stay clear of the tip rounding
    for (f = spar_at)
        hull() {
            translate([f * root_chord - spar_w / 2, 0, 0]) cube([spar_w, 0.01, skin_t + spar_h]);
            translate([f * tip_chord - spar_w / 2, half_span - tip_round - 1, 0]) cube([spar_w, 0.01, skin_t + spar_h]);
        }
    // root tab
    translate([tab_x0, -tab_len, 0]) cube([tab_x1 - tab_x0, tab_len + 0.5, tab_t]);
}

module tailplane() {
    linear_extrude(tail_t)
        translate([0, tail_span / 2])
            union() {
                rounded_planform(tail_root, tail_tip, tail_span / 2, 3);
                mirror([0, 1]) rounded_planform(tail_root, tail_tip, tail_span / 2, 3);
            }
}

// Transform that places a wing half (or its slot cutter) onto the fuselage.
// The wing's root rib ends up on the pod's side face; the tab goes inward.
module place_wing(side = 1) {
    // pivot: middle of the tab, on the fuselage centre line, at wing height
    translate([x_le + (tab_x0 + tab_x1) / 2, 0, wing_z])
        rotate([side * dihedral, 0, 0]) rotate([0, incidence, 0])
            translate([-(tab_x0 + tab_x1) / 2, side * pod_w / 2, -tab_t / 2])
                children();
}

module fuselage() {
    difference() {
        union() {
            // pod: rounded nose, flat bottom, tapering into the boom
            rotate([90, 0, 0]) linear_extrude(pod_w, center = true)
                hull() {
                    translate([pod_h / 2, pod_h / 2]) circle(pod_h / 2);
                    translate([pod_h / 2, 0]) square([pod_len - pod_h / 2, pod_h]);
                    translate([pod_len + 12, 0]) square([0.1, boom_h0]);
                }
            // boom and fin, flush with the right side of the pod (the side that
            // lies on the build plate) so nothing floats when printed
            translate([0, boom_y, 0]) rotate([90, 0, 0]) linear_extrude(boom_w, center = true)
                polygon([[pod_len, 0], [fus_len, 0], [fus_len, boom_h1], [pod_len, boom_h0]]);
            translate([0, pod_w / 2 - fin_w / 2, 0]) rotate([90, 0, 0]) linear_extrude(fin_w, center = true)
                polygon([[fus_len - 34, 0], [fus_len, 0], [fus_len, boom_h1 + fin_h],
                         [fus_len - 12, boom_h1 + fin_h]]);
        }
        // wing slots (angled for dihedral and incidence), open at the side face
        for (side = [-1, 1])
            place_wing(side)
                translate([tab_x0 - slot_clear, side > 0 ? -tab_len - 0.5 : -2, -slot_clear / 2])
                    cube([tab_x1 - tab_x0 + 2 * slot_clear, tab_len + 2.5, tab_t + slot_clear]);
        // tailplane slot
        translate([tail_x - slot_clear, -5, 2.2])
            cube([tail_root + 2 * slot_clear, 10, tail_t + slot_clear]);
        // ballast pocket: blind hole from the left side (the top face when printed)
        translate([ballast_x, -pod_w / 2 + ballast_depth, pod_h / 2]) rotate([90, 0, 0])
            cylinder(d = ballast_d, h = 20);
        // CG notch on top of the pod
        translate([x_cg, 0, pod_h]) rotate([0, 45, 0]) cube([1.4, pod_w + 2, 1.4], center = true);
    }
}

module assembled() {
    fuselage();
    place_wing( 1) wing_half();
    place_wing(-1) mirror([0, 1, 0]) wing_half();
    translate([tail_x, boom_y - tail_span / 2, 2.2 + slot_clear / 2]) tailplane();
}

// Fuselage in its print orientation: lying on its right side, fin flat.
module fuselage_print() {
    translate([0, 0, pod_w / 2]) rotate([-90, 0, 0]) fuselage();
}

// Exploded view of the assembly, for the docs.
module exploded() {
    fuselage();
    translate([0,  28, 0]) place_wing( 1) wing_half();
    translate([0, -28, 0]) place_wing(-1) mirror([0, 1, 0]) wing_half();
    translate([30, boom_y - tail_span / 2, 2.2 + slot_clear / 2]) tailplane();
}

module plate() {
    // Everything spanwise along X so the whole set fits in ~180 x 120 mm.
    fuselage_print();                                                            // y 0..25.5
    translate([5, 78, 0])    rotate([0, 0, -90]) wing_half();                   // right wing, y 33..78
    translate([131, -8, 0])  rotate([0, 0, -90]) mirror([0, 1, 0]) wing_half(); // left wing, y -53..-8
    translate([142, 78, 0])  rotate([0, 0, -90]) tailplane();                   // y 58..78
}

if (part == "plate")          plate();
else if (part == "assembled") assembled();
else if (part == "exploded")  exploded();
else if (part == "fuselage")  fuselage_print();
else if (part == "wing_r")    wing_half();
else if (part == "wing_l")    mirror([0, 1, 0]) wing_half();
else if (part == "tail")      tailplane();
