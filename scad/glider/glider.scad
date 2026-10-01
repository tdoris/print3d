// Tiny chuck glider.
//
// Four printed parts, no glue required:
//   * fuselage  - modelled upright, printed lying on its right side so the
//                 slot widths are drawn in-plane (accurate) rather than
//                 bridged. Two angled slots for the wing halves (dihedral +
//                 incidence), a through-slot for the tailplane, a nose
//                 ballast pocket and a CG notch on top.
//   * wing x2   - flat-bottomed cambered airfoil section (NACA-style upper
//                 surface, 6% thick), printed flat side down with sparse
//                 infill. Root tab plugs into the fuselage. Left half is a
//                 mirror of the right.
//   * tailplane - flat plate, slides through the boom.
//
// Set `part` to "plate" for the print layout, "assembled" to check the model,
// or one of "fuselage" / "wing_r" / "wing_l" / "tail" for individual exports.
part = "plate";

// ---- Wing -----------------------------------------------------------------
half_span   = 190;     // per side, excluding the root tab
root_chord  = 52;
tip_chord   = 34;
tip_round   = 5;       // corner radius at the tip
foil_t      = 0.055;   // section thickness / chord (flat bottom, all camber on top)
foil_base   = 0.25;    // minimum thickness at the leading and trailing edges
foil_n      = 40;      // points along the upper surface
tab_len     = 4.0;     // root tab that goes into the fuselage (per side)
tab_x0      = 5;       // tab runs from this chord station ...
tab_x1      = 29;      // ... to this one
tab_t       = 0.7;     // tab thickness (7 layers at 0.1 mm)
dihedral    = 6;       // degrees per side
incidence   = 2.5;     // wing angle relative to fuselage, degrees (LE up)
slot_clear  = 0.25;    // extra slot thickness / length for a push fit

// ---- Fuselage -------------------------------------------------------------
// Nose block -- thin front boom -- wing pod -- thin rear boom + fin.
// The nose block is the balance weight; putting it on a boom gives it
// leverage so less of it is needed.
x_le        = 80;      // wing leading edge position from the nose
nose_len    = 22;      // solid nose block
nose_h      = 10;
fboom_h     = 6;       // front boom height (full width, so it is stiff in the print)
fboom_w     = 2.4;
pod_x0      = x_le - 6;
pod_len     = 40;      // wing pod, holds the slots
pod_w       = 7;
pod_h       = 9.5;
boom_w      = 1.4;
boom_h0     = 3.5;     // rear boom height where it leaves the pod
boom_h1     = 2.5;     // rear boom height at the tail
fus_len     = 196;
wing_z      = 6.0;     // height of the wing slot centre line above the bottom
ballast_d   = 4.5;     // nose pocket diameter (BBs / screw / clay for trimming), enters from the left side
ballast_x   = 9;
ballast_depth = 5.5;

// ---- Tail -----------------------------------------------------------------
tail_span   = 110;
tail_root   = 20;
tail_tip    = 14;
tail_t      = 0.3;            // 3 layers at 0.1 mm
tail_inc    = -1;             // tailplane incidence, degrees (negative = LE down = nose-up trim)
tail_x      = fus_len - 26;   // tailplane leading edge position
fin_h       = 16;             // above the boom
fin_w       = 0.6;

// ---- Derived --------------------------------------------------------------
boom_y  = pod_w / 2 - boom_w / 2;       // rear boom centre line (flush with the right side)
tail_z  = 2.0;                           // tailplane slot height above the bottom
lambda  = tip_chord / root_chord;
mac     = 2 / 3 * root_chord * (1 + lambda + lambda * lambda) / (1 + lambda);
cg_frac = 0.30;
x_cg    = x_le + cg_frac * mac;         // where the CG should end up
echo(str("MAC = ", mac, " mm, target CG at x = ", x_cg, " mm from the nose"));

$fn = 48;

// ---------------------------------------------------------------------------
module rounded_planform(root, tip, span, r) {
    // Straight leading edge along y, tapering trailing edge, rounded tip.
    offset(r = r) offset(delta = -r)
        polygon([[0, 0], [root, 0], [tip, span], [0, span]]);
}

// NACA 4-digit thickness distribution (closed trailing edge): full thickness
// as a fraction of chord at x/c = u, peaking at t when u = 0.3.
function naca_t(u, t) = 10 * t * (0.2969 * sqrt(u) - 0.1260 * u - 0.3516 * u * u
                                   + 0.2843 * pow(u, 3) - 0.1036 * pow(u, 4));

// Flat-bottomed section for chord c: bottom on y = 0, curved top.
module foil_section(c) {
    polygon(concat(
        [[0, 0], [c, 0]],
        [for (i = [foil_n : -1 : 0]) let(u = i / foil_n) [u * c, foil_base + c * naca_t(u, foil_t)]]));
}

// Right wing half, flat side down, root at y = 0, LE at x = 0.
module wing_half() {
    intersection() {
        // loft root -> tip section (scaled about the LE / bottom), span along +y
        mirror([0, 1, 0]) rotate([90, 0, 0])
            linear_extrude(height = half_span, scale = tip_chord / root_chord)
                foil_section(root_chord);
        // rounded tip
        linear_extrude(20) rounded_planform(root_chord, tip_chord, half_span, tip_round);
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

// A side-profile polygon extruded to width w, flush with the right-hand face
// of the fuselage (y = +pod_w/2), which is the face that lies on the plate.
module slab(w) {
    translate([0, pod_w / 2 - w / 2, 0]) rotate([90, 0, 0]) linear_extrude(w, center = true) children();
}

module fuselage() {
    difference() {
        union() {
            // nose block, rounded front
            slab(pod_w) hull() {
                translate([nose_h / 2, nose_h / 2]) circle(nose_h / 2);
                translate([nose_h / 2, 0]) square([nose_len - nose_h / 2, nose_h]);
            }
            // front boom
            slab(fboom_w) translate([nose_len - 1, 0]) square([pod_x0 - nose_len + 2, fboom_h]);
            // wing pod, tapering into the rear boom
            slab(pod_w) polygon([[pod_x0, 0], [pod_x0 + pod_len + 10, 0], [pod_x0 + pod_len + 10, boom_h0],
                                 [pod_x0 + pod_len, pod_h], [pod_x0, pod_h]]);
            // rear boom and fin
            slab(boom_w) polygon([[pod_x0 + pod_len, 0], [fus_len, 0], [fus_len, boom_h1], [pod_x0 + pod_len, boom_h0]]);
            slab(fin_w) polygon([[fus_len - 30, 0], [fus_len, 0], [fus_len, boom_h1 + fin_h],
                                 [fus_len - 10, boom_h1 + fin_h]]);
        }
        // wing slots (angled for dihedral and incidence), open at the side face
        for (side = [-1, 1])
            place_wing(side)
                translate([tab_x0 - slot_clear, side > 0 ? -tab_len - 0.5 : -2, -slot_clear / 2])
                    cube([tab_x1 - tab_x0 + 2 * slot_clear, tab_len + 2.5, tab_t + slot_clear]);
        // tailplane slot, with its incidence
        translate([tail_x + tail_root / 2, 0, tail_z]) rotate([0, -tail_inc, 0])
            translate([-tail_root / 2 - slot_clear, -5, -slot_clear / 2])
                cube([tail_root + 2 * slot_clear, 10, tail_t + slot_clear]);
        // ballast pocket: blind hole from the left side (the top face when printed)
        translate([ballast_x, -pod_w / 2 + ballast_depth, nose_h / 2]) rotate([90, 0, 0])
            cylinder(d = ballast_d, h = 20);
        // CG notch on top of the pod
        translate([x_cg, 0, pod_h]) rotate([0, 45, 0]) cube([1.4, pod_w + 2, 1.4], center = true);
    }
}

module assembled() {
    fuselage();
    place_wing( 1) wing_half();
    place_wing(-1) mirror([0, 1, 0]) wing_half();
    translate([tail_x + tail_root / 2, 0, tail_z]) rotate([0, -tail_inc, 0])
        translate([-tail_root / 2, boom_y - tail_span / 2, -tail_t / 2]) tailplane();
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
    translate([30 + tail_x, boom_y - tail_span / 2, tail_z]) tailplane();
}

// Wings and tailplane only (they use different slicer settings to the fuselage).
module plate_wings() {
    translate([5, 52, 0])    rotate([0, 0, -90]) wing_half();                   // right wing, y 0..52
    translate([199, -8, 0])  rotate([0, 0, -90]) mirror([0, 1, 0]) wing_half(); // left wing, y -60..-8
    translate([5, 82, 0])    rotate([0, 0, -90]) tailplane();                   // y 62..82
}

module plate() {
    // Everything spanwise along X so the whole set fits in ~180 x 120 mm.
    fuselage_print();                                                            // y 0..19
    translate([5, 80, 0])    rotate([0, 0, -90]) wing_half();                   // right wing, y 28..80
    translate([199, -8, 0])  rotate([0, 0, -90]) mirror([0, 1, 0]) wing_half(); // left wing, y -60..-8
    translate([5, 110, 0])   rotate([0, 0, -90]) tailplane();                   // y 90..110
}

if (part == "plate")          plate();
else if (part == "assembled") assembled();
else if (part == "exploded")  exploded();
else if (part == "plate_wings") plate_wings();
// assembled-position single parts, for the balance estimate in scripts/glider_cg.py
else if (part == "asm_fuselage") fuselage();
else if (part == "asm_wings") { place_wing(1) wing_half(); place_wing(-1) mirror([0, 1, 0]) wing_half(); }
else if (part == "asm_tail")  translate([tail_x, boom_y - tail_span / 2, tail_z]) tailplane();
else if (part == "fuselage")  fuselage_print();
else if (part == "wing_r")    wing_half();
else if (part == "wing_l")    mirror([0, 1, 0]) wing_half();
else if (part == "tail")      tailplane();
