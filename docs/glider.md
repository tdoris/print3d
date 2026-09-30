# Tiny chuck glider

![Assembled](images/glider.png)

Source: `scad/glider/glider.scad` · Exports: `exports/glider_plate.stl` (all parts
laid out for printing) plus `glider_fuselage.stl`, `glider_wing_r.stl`,
`glider_wing_l.stl`, `glider_tail.stl`.

| Spec               | Value                                   |
|--------------------|-----------------------------------------|
| Wingspan           | 258 mm (2 × 125 mm halves + fuselage)    |
| Length             | 142 mm                                   |
| Wing area          | ~94 cm², mean chord 38 mm                |
| Mass (100% infill) | ~15 g → wing loading ~0.16 g/cm²         |
| Dihedral           | 6° per side                              |
| Wing incidence     | +3° relative to the tailplane            |
| Design CG          | 32% of mean chord, marked by the notch on top of the fuselage |

Version 2. The first version (59 cm², 17 g, 0.29 g/cm²) flew like a dart:
far too much wing loading for a flat-plate wing. V2 has 60% more wing area
built as a 0.45 mm skin with two spanwise spars instead of a solid wedge, a
lighter tail and boom, a degree more incidence and the CG 4% further back.

## How it goes together

![Exploded](images/glider_exploded.png)
![Front view: dihedral](images/glider_front.png)

Four parts, push-fit, no glue needed (a dot of CA on the tabs is optional).
Fuselage upright: fin up, flat edge down, round end forward.

1. Slide the tailplane through the slot in the boom and centre it on the boom.
2. Wing halves. Each is a thin plate with two ridges (spars) on one face.
   Orientation:
   - **spars up**, flat face down;
   - **the edge nearest a spar is the leading edge**: spars sit at 22% and
     55% of the chord, so the wider gap is at the back;
   - the tab is 5 mm behind the leading edge. It only fits the slot one way
     lengthwise;
   - push it in until the root touches the fuselage. Tips should angle **up**
     (6° each side, see the front view). If the tips angle down, the wing is
     upside down.
   The slots are cut at 6° dihedral and 2° incidence, so the angles come from
   the fuselage. The wing's leading edge ends up 4 mm ahead of the slot.
3. Balance it on two fingertips under the wings: it should balance at the
   notch, ~12 mm behind the wing's leading edge. Slightly nose-heavy is fine,
   tail-heavy is not.

Expected masses and balance points (100% infill PLA, from the model):

| Part         | Mass  | Balance point, from the nose            |
|--------------|-------|-----------------------------------------|
| Fuselage     | 8.2 g |                                         |
| Wing half    | 3.0 g | (per side)                              |
| Tailplane    | 0.8 g |                                         |
| **Complete** | 15.0 g| **62 mm, at the notch**                  |

## Print settings (P2S)

- Import `glider_plate.stl`. Bambu Studio will ask to split it into objects; say yes.
- **Fuselage prints lying on its side**, as laid out (fin flat on the plate).
  This keeps both slot widths in-plane, where the printer is accurate. An
  earlier upright version bridged the slots and they closed up. The boom and
  fin are flush with the bed-side face, so the tail sits ~3.5 mm to one side
  of the wing centre line. That's intentional and harmless.
- **0.15 mm layers** (the wing skin is 3 layers, the tab 5), **100% infill**
  (the CG was computed for solid PLA; sparse infill in the pod makes it
  tail-heavy). Total print is small anyway.
- The wing skin is thin and wide. Keep the plate clean and warm so the first
  layer sticks; a 3 mm brim on the wings is cheap insurance against lifting.
- 2 walls. Brim optional for the fuselage; the pod's footprint is fine on PEI.
- Slots have 0.25 mm clearance over the tab/plate. If one is still tight,
  a couple of passes with a craft knife or a needle file opens it up.
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
  With the lower wing loading it wants a gentle push, not a hard throw.
- **Still too fast?** Camber helps flat plates a lot. Warm a wing half with a
  hair dryer until it just softens, bow it gently so the top surface is convex
  (2–3 mm rise at mid-chord), hold until cool. Do both sides the same.
- The dihedral is held by the tab fit. Once both tips sit at the same height,
  a drop of PVA or CA at each root locks it.

## Tuning the model

All the numbers are at the top of the .scad. `part = "assembled"` renders the
whole aircraft; the OpenSCAD console echoes the target CG position. Mass and
CG of any variant can be checked with trimesh:

```
openscad -D 'part="assembled"' -o /tmp/g.stl scad/glider/glider.scad
.venv/bin/python -c "import trimesh; m=trimesh.load('/tmp/g.stl'); print(m.volume/1000*1.24, m.center_mass)"
```
