// Claddagh ring: two hands holding a crowned heart.
//
// The band is generated as a single polyhedron. The motif is defined as a
// height-map h(s, z) in "unwrapped" band coordinates (s = arc length along
// the band, z = along the finger) built from signed-distance primitives,
// then wrapped onto the cylinder.
//
// Printability (ring prints flat on the plate, bore vertical, crown up):
//  * flat_bottom keeps the band's bottom edge on the plate all the way round.
//  * An "underside" pass slopes the bottom of every raised feature to
//    drip_slope so nothing overhangs more than ~40 deg. Top edges stay crisp.

// ---- Size -----------------------------------------------------------------
ring_size_mm = 17.53;    // UK "N" (I=15.49 J=15.90 K=16.31 L=16.71 M=17.12 N=17.53 O=17.93)
clearance    = 0.30;     // FDM hole shrink compensation
inner_d      = ring_size_mm + clearance;

// ---- Band -----------------------------------------------------------------
band_thick   = 1.5;      // radial thickness of the plain band
// Band width vs angle from the top, as [angle, width] knots joined by
// smooth steps.
width_knots  = [[0, 12.0], [24, 12.0], [48, 8.0], [76, 8.0], [100, 5.0], [180, 5.0]];
// true:  bottom edge flat all the way round, width varies on the top edge only.
//        Prints with no supports or brim.
// false: symmetric about the mid-plane (classic look) but the narrow back
//        floats above the plate: needs supports and a brim.
flat_bottom  = true;

// ---- Relief heights (mm above the band) and crisp edge ramp widths --------
heart_h  = 1.1;  heart_ramp  = 0.40;
heart_dome = 0.6;                       // extra height at the heart's centre
crown_h  = 1.1;  crown_ramp  = 0.35;
arm_h    = 0.7;  arm_ramp    = 0.35;
cuff_h   = 1.0;  cuff_ramp   = 0.35;
palm_h   = 0.9;  palm_ramp   = 0.35;
finger_h = 1.2;  finger_ramp = 0.28;
drip_slope = 1.15;       // max radial rise per mm of drop on undersides (1.15 = 49 deg)

// ---- Mesh resolution ------------------------------------------------------
n_theta = 720;           // columns around the ring
n_z     = 96;            // rows across the band

r_in  = inner_d / 2;
r_out = r_in + band_thick;

// ---- 2D signed-distance primitives (mm) -----------------------------------
function clamp(x, a, b) = min(max(x, a), b);
function smoothstep(t) = let(u = clamp(t, 0, 1)) u * u * (3 - 2 * u);
function sd_circle(p, c, r) = norm(p - c) - r;
function sd_capsule(p, a, b, r) =
    let(pa = p - a, ba = b - a,
        t = clamp((pa * ba) / (ba * ba), 0, 1))
    norm(pa - ba * t) - r;
function sd_seg(p, a, b) = sd_capsule(p, a, b, 0);
function inside_poly(p, v, i = 0, c = false) =
    i >= len(v) ? c :
    let(a = v[i], b = v[(i + 1) % len(v)],
        cross_ = ((a[1] > p[1]) != (b[1] > p[1])) &&
                 (p[0] < (b[0] - a[0]) * (p[1] - a[1]) / (b[1] - a[1]) + a[0]))
    inside_poly(p, v, i + 1, cross_ ? !c : c);
function sd_poly(p, v) =
    let(d = min([for (i = [0 : len(v) - 1]) sd_seg(p, v[i], v[(i + 1) % len(v)])]))
    inside_poly(p, v) ? -d : d;

// 1 inside the shape, falling smoothly to 0 over `w` outside it
function ramp_of(d, w) = smoothstep(1 - d / w);

// ---- Motif ----------------------------------------------------------------
// s: arc length from the top centre (positive = right), z: +z toward crown.
heart_c = [0, -1.3];
function sd_heart(p) = min(
    sd_circle(p, [-1.85, 0.3], 1.95),
    sd_circle(p, [ 1.85, 0.3], 1.95),
    sd_poly(p, [[-3.7, -0.15], [3.7, -0.15], [0, -4.3]]));
function heart_puff(p) =
    let(q = p - heart_c, e = pow(q[0] / 3.6, 2) + pow(q[1] / 3.2, 2))
    heart_dome * smoothstep(1 - e);
function h_heart(p) = ramp_of(sd_heart(p), heart_ramp) * (heart_h + heart_puff(p));

crown_pts = [[-3.3, 1.9], [3.3, 1.9], [3.3, 3.0], [2.4, 5.0], [1.2, 3.3],
             [0, 5.3], [-1.2, 3.3], [-2.4, 5.0], [-3.3, 3.0]];
function sd_crown(p) = min(
    sd_poly(p, crown_pts),
    sd_circle(p, [-2.4, 5.0], 0.45),
    sd_circle(p, [ 0,   5.3], 0.45),
    sd_circle(p, [ 2.4, 5.0], 0.45));
function h_crown(p) = crown_h * ramp_of(sd_crown(p), crown_ramp);

// Right hand (+s). The arm comes in along the band, the palm turns to face
// the heart, fingers lie along the heart's lower edge toward its tip, thumb
// rests on the upper lobe. Mirrored for the left hand.
fdir = [-0.67, -0.745];              // finger direction (down the heart edge)
fsep = [ 0.745, -0.67];              // spacing direction between fingers
finger_len = [2.8, 3.0, 2.8, 2.4];
function sd_arm(p)  = sd_capsule(p, [12.5, -1.2], [6.0, -1.5], 0.95);
function sd_cuff(p) = sd_poly(p, [[9.2, -3.0], [10.9, -3.2], [10.9, 0.8], [9.2, 0.6]]);
function sd_palm(p) = sd_poly(p, [[6.2, -0.4], [6.4, -2.4], [5.4, -3.5],
                                  [4.0, -3.2], [3.8, -1.6], [4.4, -0.3]]);
function sd_fingers(p) = min([for (k = [0 : 3])
    let(a = [4.2, -1.0] + fsep * 0.95 * k)
    sd_capsule(p, a, a + fdir * finger_len[k], 0.35)]);
function sd_thumb(p) = sd_capsule(p, [4.6, -0.3], [3.6, 1.4], 0.42);

function h_hand(p) = max(
    arm_h    * ramp_of(sd_arm(p),     arm_ramp),
    cuff_h   * ramp_of(sd_cuff(p),    cuff_ramp),
    palm_h   * ramp_of(sd_palm(p),    palm_ramp),
    finger_h * ramp_of(sd_fingers(p), finger_ramp),
    finger_h * ramp_of(sd_thumb(p),   finger_ramp));

function relief(p) = max(h_heart(p), h_crown(p), h_hand(p), h_hand([-p[0], p[1]]));
max_relief = heart_h + heart_dome;

// ---- Band width as a function of angle from the top -----------------------
function band_width(theta, k = 0) =
    let(a = abs(theta > 180 ? theta - 360 : theta))
    k >= len(width_knots) - 1 ? width_knots[k][1] :
    a <= width_knots[k + 1][0]
        ? let(t = (a - width_knots[k][0]) / (width_knots[k + 1][0] - width_knots[k][0]))
          width_knots[k][1] + (width_knots[k + 1][1] - width_knots[k][1]) * smoothstep(t)
        : band_width(theta, k + 1);
width_max = max([for (k = width_knots) k[1]]);

// ---- Grid -----------------------------------------------------------------
// theta = 0 is the top of the ring (+Y).
function theta_of(i) = 360 * i / n_theta;
function s_of(theta) = r_out * (theta > 180 ? theta - 360 : theta) * PI / 180;
function dz_of(theta) = band_width(theta) / (n_z - 1);
function z_of(theta, j) = flat_bottom
    ? -width_max / 2 + dz_of(theta) * j
    : dz_of(theta) * j - band_width(theta) / 2;

// Raw relief on the grid, then the underside pass: each cell is raised to at
// least (cell above) - drip_slope * dz so no underside is shallower than
// atan(drip_slope). Only rows within max_relief / drip_slope need checking.
hraw = [for (i = [0 : n_theta - 1])
    let(th = theta_of(i), s = s_of(th))
    [for (j = [0 : n_z - 1]) relief([s, z_of(th, j)])]];
hgrid = [for (i = [0 : n_theta - 1])
    let(dz = dz_of(theta_of(i)), look = ceil(max_relief / drip_slope / dz))
    [for (j = [0 : n_z - 1])
        max([for (q = [0 : min(look, n_z - 1 - j)]) hraw[i][j + q] - drip_slope * q * dz])]];

function outer_pt(i, j) =
    let(th = theta_of(i), r = r_out + hgrid[i][j])
    [r * sin(th), r * cos(th), z_of(th, j)];
function inner_pt(i, j) =
    let(th = theta_of(i))
    [r_in * sin(th), r_in * cos(th), z_of(th, j)];

function O(i, j) = (i % n_theta) * n_z + j;
function I(i, j) = n_theta * n_z + (i % n_theta) * n_z + j;

pts = concat(
    [for (i = [0 : n_theta - 1], j = [0 : n_z - 1]) outer_pt(i, j)],
    [for (i = [0 : n_theta - 1], j = [0 : n_z - 1]) inner_pt(i, j)]);

faces = concat(
    [for (i = [0 : n_theta - 1], j = [0 : n_z - 2])       // outer surface
        [O(i + 1, j), O(i + 1, j + 1), O(i, j + 1), O(i, j)]],
    [for (i = [0 : n_theta - 1], j = [0 : n_z - 2])       // bore
        [I(i, j + 1), I(i + 1, j + 1), I(i + 1, j), I(i, j)]],
    [for (i = [0 : n_theta - 1])                          // top edge
        [O(i + 1, n_z - 1), I(i + 1, n_z - 1), I(i, n_z - 1), O(i, n_z - 1)]],
    [for (i = [0 : n_theta - 1])                          // bottom edge
        [I(i, 0), I(i + 1, 0), O(i + 1, 0), O(i, 0)]]);

// Sit on the build plate
translate([0, 0, width_max / 2]) polyhedron(points = pts, faces = faces, convexity = 10);
