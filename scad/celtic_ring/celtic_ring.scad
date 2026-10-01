// Celtic weave ring
// Two strands wrap around the band, alternating over/under to give an
// interlaced braid. Printed flat (band axis vertical) with no supports.

// ---- Size -----------------------------------------------------------------
// UK ring sizes, inner diameter in mm (Bambu/FDM holes come out slightly
// undersize, so a small clearance is added below).
ring_size_mm  = 15.49;   // UK "I"  (I=15.49 J=15.90 K=16.31 L=16.71 M=17.12 N=17.53 O=17.93 P=18.34 Q=18.75 R=19.15 S=19.56 T=19.96)
clearance     = 0.30;    // FDM hole shrink compensation
inner_d       = ring_size_mm + clearance;

// ---- Band -----------------------------------------------------------------
band_thick    = 1.2;     // solid base band under the weave
band_width    = 6.0;     // overall height of the ring
rim_h         = 0.8;     // small rims at the top/bottom edges
rim_thick     = 0.5;     // how far the rims stand proud of the base band


// ---- Weave ----------------------------------------------------------------
crossings     = 8;       // number of over/under crossings around the ring
strand_r      = 0.75;    // radius of each strand (tube)
weave_depth   = 0.45;    // radial in/out movement (gives the over/under)
steps         = 240;     // segments around the ring

// ---- Wavy top edge --------------------------------------------------------
// The top rim rises and falls around the ring, one crest over each place a
// strand of the braid peaks, so the edge follows the weave.
wavy_top      = false;
wave_amp      = 0.55;    // half the peak-to-trough height of the wave (mm)
wave_n        = crossings;   // one wave per crossing; 2 * crossings hugs every strand peak but looks like a crown
wave_phase    = 0;       // degrees; 0 puts crests over the peaks of the first strand

$fn = 16;

inner_r  = inner_d / 2;
band_r   = inner_r + band_thick;              // outer radius of base band
strand_c = band_r + 0.25;                     // mean radius of strand centres
amp      = (band_width - 2 * rim_h) / 2 - strand_r - 0.2;  // z amplitude

module strand(phase) {
    for (i = [0 : steps - 1]) {
        hull() {
            for (j = [0, 1]) {
                t = 360 * (i + j) / steps;
                a = crossings * t + phase;
                r = strand_c + weave_depth * cos(a);
                z = amp * sin(a);
                translate([r * cos(t), r * sin(t), z]) sphere(strand_r);
            }
        }
    }
}

// Height of the top edge above the ring's mid-plane, at angle t
function top_z(t) = band_width / 2 + (wavy_top ? wave_amp * sin(wave_n * t + wave_phase) : 0);

module base_band() {
    // stops just under the top rim; the rim fills the rest, wavy or not
    z0 = -band_width / 2;
    z1 = band_width / 2 - rim_h - (wavy_top ? wave_amp : 0);
    translate([0, 0, z0]) difference() {
        cylinder(h = z1 - z0, r = band_r, $fn = 180);
        translate([0, 0, -0.5]) cylinder(h = z1 - z0 + 1, r = inner_r, $fn = 180);
    }
}

module bottom_rim() {
    translate([0, 0, -band_width / 2]) difference() {
        cylinder(h = rim_h, r = band_r + rim_thick, $fn = 180);
        translate([0, 0, -0.5]) cylinder(h = rim_h + 1, r = inner_r, $fn = 180);
    }
}

// Top rim as a ring of hulled wedges so its top edge can follow top_z(t).
module top_rim() {
    z0 = band_width / 2 - rim_h - (wavy_top ? wave_amp : 0) - 0.01;
    n = 180;
    module plate(t) {
        rotate([0, 0, t]) translate([inner_r, 0, z0])
            cube([band_r + rim_thick - inner_r, 0.01, top_z(t) - z0]);
    }
    for (i = [0 : n - 1])
        hull() { plate(360 * i / n); plate(360 * (i + 1) / n); }
}

module rims() {
    bottom_rim();
    top_rim();
}

module ring() {
    base_band();
    rims();
    strand(0);
    strand(180);
}

// Sit the ring on the build plate
translate([0, 0, band_width / 2]) ring();
echo(str("bore ", inner_d, " mm, height ", band_width + (wavy_top ? wave_amp : 0), " mm"));
