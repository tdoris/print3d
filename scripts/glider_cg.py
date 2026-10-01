#!/usr/bin/env python3
"""Estimate the glider's as-printed mass and centre of gravity.

The fuselage and tailplane are effectively solid PLA. The cambered wing is
printed with sparse infill, so its mass is estimated from skins + walls +
infill rather than from the solid model volume.

Usage: scripts/glider_cg.py [-D 'param=value' ...]
"""
import re, subprocess, sys, tempfile, os
import trimesh, numpy as np

RHO = 1.24            # g/cm3, PLA
LAYER = 0.10          # mm
TOP, BOTTOM = 2, 2    # solid layers on the wing
WALLS = 2             # perimeters
LINE = 0.42           # mm line width
INFILL = 0.06         # sparse infill density on the wing

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
scad = os.path.join(root, "scad/glider/glider.scad")
defs = sys.argv[1:]

def export(part, out):
    r = subprocess.run(["openscad", "-D", f'part="{part}"', *defs, "--export-format", "binstl",
                        "-o", out, scad], capture_output=True, text=True)
    m = re.search(r"target CG at x = ([0-9.]+)", r.stdout + r.stderr)
    return float(m.group(1)) if m else None

with tempfile.TemporaryDirectory() as d:
    parts = {}
    for p in ["asm_fuselage", "asm_wings", "asm_tail"]:
        out = os.path.join(d, p + ".stl")
        tgt = export(p, out)
        parts[p] = trimesh.load(out)
    fus, wings, tail = parts["asm_fuselage"], parts["asm_wings"], parts["asm_tail"]

    # wing: planform area from the projected footprint of the solid model
    planform = wings.area / 2 * 0.98   # top + bottom faces dominate the surface
    skins = planform * (TOP + BOTTOM) * LAYER / 1000            # cm3
    walls = 0.35 * (wings.volume / 1000) * 0                    # negligible on a thin section
    ext = wings.extents
    outline = 2 * (2 * ext[1] / 2 + 2 * ext[0])                  # mm, both halves (approx)
    walls = outline * WALLS * LINE * 1.2 / 1000                  # ~1.2 mm mean wall height
    interior = max(wings.volume / 1000 - skins - walls, 0)
    m_wing = RHO * (skins + walls + interior * INFILL)
    m_fus = RHO * fus.volume / 1000
    m_tail = RHO * tail.volume / 1000
    m = m_fus + m_wing + m_tail
    cg = (m_fus * fus.center_mass + m_wing * wings.center_mass + m_tail * tail.center_mass) / m
    print(f"fuselage {m_fus:5.1f} g   wings {m_wing:5.1f} g (solid would be {RHO*wings.volume/1000:.1f})   tail {m_tail:4.1f} g")
    print(f"total {m:5.1f} g   CG x = {cg[0]:.1f} mm   target {tgt:.1f}   delta {cg[0]-tgt:+.1f} mm")
    print(f"wing area ~{planform/100:.0f} cm2   loading {m/(planform/100):.3f} g/cm2   (LW-PLA at 0.5 g/cm3: ~{m*0.5/RHO/(planform/100):.3f})")
