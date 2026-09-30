# print3d

3D-printing projects for a **Bambu Lab P2S**. Models are written in OpenSCAD so they are
parametric and version-controlled; exported STL/3MF files live alongside the source.

## Layout

| Path        | Purpose                                                             |
|-------------|---------------------------------------------------------------------|
| `scad/`     | OpenSCAD sources. One directory per model, shared modules in `lib/` |
| `exports/`  | Exported STL / 3MF files ready to slice (committed for convenience)   |
| `models/`   | Third-party or hand-made meshes (STL/STEP) that aren't generated     |
| `scripts/`  | Helper scripts (batch export, checks)                               |
| `docs/`     | Notes, print settings, photos                                       |

## Printer

- Bambu Lab P2S, 256 x 256 x 256 mm build volume
- Slice with Bambu Studio (or OrcaSlicer) and print over the network

## Workflow

1. Edit a `.scad` file (e.g. `openscad scad/<model>/<model>.scad` for the live preview).
2. Export: `scripts/export.sh scad/<model>/<model>.scad` writes `exports/<model>.stl`.
3. Open the STL in Bambu Studio, slice, print.

## Tooling (installed on this machine)

| Tool                | Where                                                | Notes                                        |
|---------------------|------------------------------------------------------|----------------------------------------------|
| OpenSCAD nightly    | `~/.local/opt/OpenSCAD-nightly.AppImage` → `openscad` | Manifold backend, fast renders                |
| OpenSCAD 2021.01    | `/usr/bin/openscad` (apt)                            | Fallback; `~/.local/bin` shadows it on PATH   |
| Bambu Studio        | `~/.local/opt/BambuStudio.AppImage` → `bambu-studio` | Slicer; also has a CLI (`bambu-studio --help`)|
| admesh              | apt                                                  | STL sanity checks / repair                    |
| Python venv         | `.venv/` (`requirements.txt`: trimesh, numpy-stl)    | Mesh inspection scripts                       |

## Projects

| Model           | Notes                                     |
|-----------------|-------------------------------------------|
| `celtic_ring`   | Woven band ring, UK size I ([docs](docs/celtic_ring.md)) |
| `claddagh_ring` | Hands, heart and crown, UK size N ([docs](docs/claddagh_ring.md)) |
| `glider`        | 258 mm chuck glider, push-fit ([docs](docs/glider.md)) |
