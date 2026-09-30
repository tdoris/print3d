# Tiny chuck glider

![Assembled](images/glider.png)

Source: `scad/glider/glider.scad` · Exports: `exports/glider_plate.stl` (all parts
laid out for printing) plus `glider_fuselage.stl`, `glider_wing_r.stl`,
`glider_wing_l.stl`, `glider_tail.stl`.

| Spec               | Value                                   |
|--------------------|-----------------------------------------|
| Wingspan           | 188 mm (2 × 90 mm halves + fuselage)     |
| Length             | 145 mm                                   |
| Wing area          | ~59 cm², mean chord 33.5 mm              |
| Mass (100% infill) | ~17 g → wing loading ~0.29 g/cm²         |
| Dihedral           | 6° per side                              |
| Wing incidence     | +2° relative to the tailplane            |
| Design CG          | 28% of mean chord, marked by the notch on top of the fuselage |

## How it goes together

Four parts, push-fit, no glue needed (a dot of CA on the tabs is optional):

1. Slide the tailplane through the slot in the boom, centre it.
2. Push each wing half's root tab into its slot in the pod. The slots are cut at
   6° dihedral and 2° incidence, so the angles are set by the fuselage.
3. Balance it on two fingertips under the wings: it should balance at the
   notch. Nose-heavy is fine, tail-heavy is not.

## Print settings (P2S)

- Import `glider_plate.stl`. Bambu Studio will ask to split it into objects; say yes.
- **Fuselage prints standing up**, as laid out. Wings and tail print flat.
- 0.2 mm layers, **100% infill** (the CG was computed for solid PLA; sparse
  infill in the pod makes it tail-heavy). Total print is small anyway.
- 2 walls. Brim optional for the fuselage; the pod's footprint is fine on PEI.
- The wing and tail slots are bridged; the printer handles the 2–4 mm spans.
- PLA. Avoid heavy, brittle "silk" PLA for the wings.

## Trimming

- **Dives**: too nose-heavy, or the tail is set nose-down. Bend nothing; check
  the tailplane is fully seated and level. Move the CG back only if it balances
  well ahead of the notch.
- **Stalls / porpoises**: tail-heavy. Add ballast to the nose pocket: a short
  M3 screw, airsoft BBs, or blu-tack, until it balances at the notch.
- **Turns hard one way**: a warped wing half. Reprint, or warm the wing gently
  and flatten.
- Launch: hold the pod under the wing, throw gently level, slightly nose-down.

## Tuning the model

All the numbers are at the top of the .scad. `part = "assembled"` renders the
whole aircraft; the OpenSCAD console echoes the target CG position. Mass and
CG of any variant can be checked with trimesh:

```
openscad -D 'part="assembled"' -o /tmp/g.stl scad/glider/glider.scad
.venv/bin/python -c "import trimesh; m=trimesh.load('/tmp/g.stl'); print(m.volume/1000*1.24, m.center_mass)"
```
