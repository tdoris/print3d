// Celtic weave ring
// Two strands wrap around the band, alternating over/under to give an
// interlaced braid. Printed flat (band axis vertical) with no supports.

// ---- Size -----------------------------------------------------------------
// UK ring sizes, inner diameter in mm (Bambu/FDM holes come out slightly
// undersize, so a small clearance is added below).
ring_size_mm  = 15.49;   // UK "I"
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

module base_band() {
    difference() {
        cylinder(h = band_width, r = band_r, center = true, $fn = 180);
        cylinder(h = band_width + 1, r = inner_r, center = true, $fn = 180);
    }
}

module rims() {
    for (s = [-1, 1])
        translate([0, 0, s * (band_width / 2 - rim_h / 2)])
            difference() {
                cylinder(h = rim_h, r = band_r + rim_thick, center = true, $fn = 180);
                cylinder(h = rim_h + 1, r = inner_r, center = true, $fn = 180);
            }
}

module ring() {
    base_band();
    rims();
    strand(0);
    strand(180);
}

// Sit the ring on the build plate
translate([0, 0, band_width / 2]) ring();
