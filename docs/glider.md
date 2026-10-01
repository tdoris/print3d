# Tiny chuck glider

![Assembled](images/glider.png)

Source: `scad/glider/glider.scad` · Exports: `exports/glider_fuselage.stl` and
`exports/glider_plate_wings.stl` (wings + tailplane) are the two prints;
`glider_plate.stl` has everything on one plate, and each part is also
exported on its own.

| Spec               | Value                                   |
|--------------------|-----------------------------------------|
| Wingspan           | 387 mm (2 × 190 mm halves + fuselage)    |
| Length             | 196 mm                                   |
| Wing area          | ~165 cm², mean chord 44 mm, aspect ratio ~9 |
| Wing section       | flat-bottomed, NACA-style top, 5.5% thick (max at 30% chord) |
| Mass (as sliced)   | ~18.5 g in PLA → wing loading ~0.11 g/cm². In LW-PLA ~8 g → ~0.05 g/cm² |
| Dihedral           | 6° per side                              |
| Decalage           | wing +2.5°, tailplane −1° (3.5° total)   |
| Design CG          | 30% of mean chord, marked by the notch on top of the wing pod |

![Wing section at the root](images/glider_section.png)

**Version 4: as light as PLA allows.** V3 (104 cm², 20 g, 0.19 g/cm²) printed
and fitted well, and the camber was good, but it still flew like a dart. The
problem is PLA's density. V4 attacks it from every side:

- 60% more wing area, at 0.1 mm layers with 2+2 skin layers and 6% infill
  (about 0.07 g/cm² for the wing itself, which is close to the floor for a
  printed PLA shell).
- The nose weight sits on a thin boom well ahead of the wing, so it has
  leverage and much less of it is needed. The fuselage drops from 9 g to 6.8 g
  while being 54 mm longer.
- Tailplane and fin at 0.3 and 0.6 mm; thinner rear boom.
- 3.5° of decalage and the CG at 30%, so it is trimmed on the slow side. If
  it stalls, add nose ballast; you can only make it faster, not slower.

**The honest limit:** at ~0.11 g/cm² this is a brisk glider, not a floater.
The real fix is **LW-PLA** (foaming lightweight PLA, e.g. ColorFabb LW-PLA or
eSun ePLA-LW), the standard material for printed RC aircraft. Same geometry,
same slicer settings, same balance (as long as every part is the same
material), and the model comes out at roughly 8 g, i.e. ~0.05 g/cm², which
is genuinely floaty.

## How it goes together

![Exploded](images/glider_exploded.png)
![Front view: dihedral](images/glider_front.png)

Four parts, push-fit, no glue needed (a dot of CA on the tabs is optional).
Fuselage upright: fin up, flat edge down, round end forward.

1. Slide the tailplane through the slot in the boom and centre it on the boom.
2. Wing halves. Each is an airfoil: flat on one face, curved on the other,
   thickest about a third of the way back from the rounded edge. Orientation:
   - **curved face up**, flat face down;
   - **thick, rounded edge forward** (leading edge); the thin edge is the
     trailing edge;
   - the tab is 5 mm behind the leading edge. It only fits the slot one way
     lengthwise;
   - push it in until the root touches the fuselage. Tips should angle **up**
     (6° each side, see the front view). If the tips angle down, the wing is
     upside down.
   The slots are cut at 6° dihedral and 2° incidence, so the angles come from
   the fuselage. The wing's leading edge ends up 4 mm ahead of the slot.
3. Balance it on two fingertips under the wings: it should balance at the
   notch, ~13 mm behind the wing's leading edge. Slightly nose-heavy is fine,
   tail-heavy is not.

Expected masses and balance point (from the model and the slicer settings above):

| Part         | Mass  | Balance point, from the nose            |
|--------------|-------|-----------------------------------------|
| Fuselage     | 6.8 g |                                         |
| Wing half    | ~5.5 g| (per side, at 6% infill / 2+2 skins, 0.1 mm layers) |
| Tailplane    | 0.7 g |                                         |
| **Complete** | ~18.5 g| **93 mm, at the notch**                 |

## Print settings (P2S)

Two prints, because the fuselage and the wings want different infill. (You can
do it as one plate with per-object settings instead: right-click an object →
Add settings → Sparse infill density.)

**Print 1: `glider_fuselage.stl`**
- 0.1 mm layers, 2 walls, **100% infill**. The balance calculation assumes
  a solid nose; sparse infill there makes it tail-heavy.
- It prints lying on its side, as exported (fin flat on the plate), so the
  slot widths are in-plane and come out to size. The boom and fin are flush
  with the bed-side face, so the tail sits ~3.5 mm to one side of the wing
  centre line. That's intentional and harmless.

**Print 2: `glider_plate_wings.stl`** (both wings and the tailplane)
- **0.1 mm layers**, 2 walls, **6% gyroid infill**, **2 top and 2 bottom
  layers**. The curved top skin is printed over the sparse infill like the top
  of any normal part. The balance estimate assumes these numbers: 100% infill
  here would add ~26 g and ruin it.
- Wing halves are 194 mm long, so the plate is 203 × 170 mm. Fits the P2S
  with room to spare.
- A 3 mm brim on the wings is cheap insurance against corners lifting.
- Balance was estimated by `scripts/glider_cg.py`, which models the wing as
  skins + walls + 10% infill rather than solid PLA.
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
