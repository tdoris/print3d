// Tiny chuck glider.
//
// Four printed parts, no glue required:
//   * fuselage  - printed standing up (as modelled). Has two angled slots for
//                 the wing halves (dihedral + incidence), a through-slot for
//                 the tailplane, a nose ballast pocket and a CG notch on top.
//   * wing x2   - flat-bottomed wedge plates, printed flat. Root tab plugs
//                 into the fuselage. Left half is a mirror of the right.
//   * tailplane - flat plate, slides through the boom.
//
// Set `part` to "plate" for the print layout, "assembled" to check the model,
// or one of "fuselage" / "wing_r" / "wing_l" / "tail" for individual exports.
part = "plate";

// ---- Wing -----------------------------------------------------------------
half_span   = 90;      // per side, excluding the root tab
root_chord  = 40;
tip_chord   = 26;
tip_round   = 4;       // corner radius at the tip
t_le        = 1.0;     // wing thickness at the leading edge
t_te        = 0.45;     // ... at the trailing edge (wedge section)
tab_len     = 4.0;     // root tab that goes into the fuselage (per side)
tab_x0      = 4;       // tab runs from this chord station ...
tab_x1      = 26;      // ... to this one
tab_t       = 0.8;     // tab thickness
dihedral    = 6;       // degrees per side
incidence   = 2;       // wing angle relative to fuselage, degrees (LE up)
slot_clear  = 0.18;    // extra slot height / length for a snug push fit

// ---- Fuselage -------------------------------------------------------------
x_le        = 54;      // wing leading edge position from the nose
pod_len     = 84;      // solid nose pod, nose to where it starts tapering
pod_w       = 9;
pod_h       = 10;
boom_w      = 2.0;
boom_h0     = 5;       // boom height where it leaves the pod
boom_h1     = 3.5;       // boom height at the tail
fus_len     = 145;
wing_z      = 7.8;     // height of the wing slot centre line above the bottom
ballast_d   = 6;       // nose pocket diameter (BBs / screw / clay for trimming)
ballast_x   = 10;
ballast_depth = 7;

// ---- Tail -----------------------------------------------------------------
tail_span   = 68;
tail_root   = 18;
tail_tip    = 13;
tail_t      = 0.6;
tail_x      = fus_len - 24;   // tailplane leading edge position
fin_h       = 22;             // above the boom
fin_w       = 1.2;

// ---- Derived --------------------------------------------------------------
lambda  = tip_chord / root_chord;
mac     = 2 / 3 * root_chord * (1 + lambda + lambda * lambda) / (1 + lambda);
cg_frac = 0.28;
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
    // wedge section: thick at the LE, thin at the TE, over the root chord
    intersection() {
        linear_extrude(t_le) rounded_planform(root_chord, tip_chord, half_span, tip_round);
        hull() {
            cube([0.01, half_span + 1, t_le]);
            translate([root_chord, 0, 0]) cube([0.01, half_span + 1, t_te]);
        }
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

// Transform that places the right wing half onto the fuselage.
module place_wing(side = 1) {
    // pivot: middle of the tab, on the fuselage centre line, at wing height
    translate([x_le + (tab_x0 + tab_x1) / 2, 0, wing_z])
        rotate([side * dihedral, 0, 0]) rotate([0, incidence, 0])
            translate([-(tab_x0 + tab_x1) / 2, 0, -tab_t / 2])
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
            // boom
            rotate([90, 0, 0]) linear_extrude(boom_w, center = true)
                polygon([[pod_len, 0], [fus_len, 0], [fus_len, boom_h1], [pod_len, boom_h0]]);
            // fin
            rotate([90, 0, 0]) linear_extrude(fin_w, center = true)
                polygon([[fus_len - 34, 0], [fus_len, 0], [fus_len, boom_h1 + fin_h],
                         [fus_len - 12, boom_h1 + fin_h]]);
        }
        // wing slots (angled for dihedral and incidence)
        for (side = [-1, 1])
            place_wing(side)
                translate([tab_x0 - slot_clear, side > 0 ? -0.5 : -pod_w / 2 - 1, -slot_clear / 2])
                    cube([tab_x1 - tab_x0 + 2 * slot_clear, pod_w / 2 + 0.5 + 1 - 0.8, tab_t + slot_clear]);
        // tailplane slot
        translate([tail_x - slot_clear, -5, 2.2])
            cube([tail_root + 2 * slot_clear, 10, tail_t + slot_clear + 0.15]);
        // ballast pocket
        translate([ballast_x, 0, pod_h - ballast_depth]) cylinder(d = ballast_d, h = 20);
        // CG notch on top of the pod
        translate([x_cg, 0, pod_h]) rotate([0, 45, 0]) cube([1.4, pod_w + 2, 1.4], center = true);
    }
}

module assembled() {
    fuselage();
    place_wing( 1) wing_half();
    place_wing(-1) mirror([0, 1, 0]) wing_half();
    translate([tail_x, 0, 2.2 + slot_clear / 2]) translate([0, -tail_span / 2, 0]) tailplane();
}

module plate() {
    fuselage();
    translate([0, 40, 0]) wing_half();
    translate([0, -40, 0]) mirror([0, 1, 0]) wing_half();
    translate([110, 40, 0]) tailplane();
}

if (part == "plate")          plate();
else if (part == "assembled") assembled();
else if (part == "fuselage")  fuselage();
else if (part == "wing_r")    wing_half();
else if (part == "wing_l")    mirror([0, 1, 0]) wing_half();
else if (part == "tail")      tailplane();
