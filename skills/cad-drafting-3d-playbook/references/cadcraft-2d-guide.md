# CADCraft 2D Technical Drawing Reference Guide

> Complete drafting workflow, layer standards, constraint commands, dimensioning, and export checklist for CADCraft (457 native AutoCAD-style commands over MCP).

---

## 1. Live Connection, MCP Tools & Viewport Setup

- **Headless mode (`cadcraft` MCP):** `cadcraft-cli mcp` — instant 2D DXF/DWG generation and measurement.
- **Live visual mode (`cadcraft-live` MCP):** Launch CADCraft via `cadcraft.exe --control 7979` (or `scripts/launch-cadcraft-live.bat`) so every command draws live on the canvas.
- **CADCraft MCP Tools (15 tools total):**
  - Core: `command_line` (AutoCAD-style CLI string), `script` (multi-line script), `execute` (structured JSON command), `list_commands`, `inspect_drawing`, `query_entities`, `find_text`, `render` (PNG/SVG), `new_drawing`, `open`, `save`, `cancel`.
  - Live-window UI tools (`cadcraft-live` only): `screenshot`, `ui_inspect`, `ui_click` — let agents inspect the live canvas and click UI controls directly!
- **AutoLISP Power-User Tip:** CADCraft natively supports AutoLISP (`lisp`, `appload`) for parametric 2D loops (gear teeth, repeating bolt arrays, title-block automation) in a single compact call — massive token savings!
- **First commands on every new drawing:**
  1. Set units (`units` / `-units`) — `mm`, decimal precision `0.00`.
  2. Set drawing limits (`limits`) and frame the viewport (`zoom` extents / `view.set`).
  3. Create standard layers BEFORE drawing any geometry!

---

## 2. Standard Engineering Layer Table (ISO 128 / ASME Y14.2)

Create these layers first using `layer`:

| Layer Name | Purpose | Color | Linetype | Lineweight |
| --- | --- | --- | --- | --- |
| `0` | Default / block definitions only | White | Continuous | Default |
| `OUTLINE` | Visible part edges & cut contours | White / Cyan | Continuous | `0.50 mm` |
| `HIDDEN` | Hidden internal edges & bores | Yellow | DASHED / HIDDEN | `0.25 mm` |
| `CENTER` | Centerlines, symmetry axes, bolt circles | Red | CENTER | `0.18 mm` |
| `DIM` | Dimensions, tolerances, leaders | Green | Continuous | `0.18 mm` |
| `HATCH` | Section cut hatching (`ANSI31` / `ANSI32`) | Gray | Continuous | `0.18 mm` |
| `TEXT` | Notes, callouts, BOM tables | White | Continuous | `0.25 mm` |
| `TITLEBLOCK` | Border, title block, revision table | Magenta / White | Continuous | `0.35 mm` |
| `DEFPOINTS` | Non-plotting construction / viewport frames | Dark Gray | Continuous | No-plot |

---

## 3. Core Drafting Command Reference (Verified in CADCraft)

### Primitives & Geometry
- Lines & Polylines: `line`, `pline`, `rectang`, `polygon`, `xline`, `ray`, `mline`
- Curves: `circle`, `arc`, `ellipse`, `spline`, `donut`, `helix`
- Construction & Hatching: `hatch`, `hatchpick`, `boundary`, `region`, `wipeout`, `revcloud`

### Precision Editing
- Transform: `move`, `copy`, `rotate`, `scale`, `mirror`, `align`, `stretch`
- Modify: `offset`, `trim`, `extend`, `fillet`, `chamfer`, `blend`, `break`, `breakatpoint`, `join`, `explode`, `pedit`, `lengthen`
- Arrays: `arrayrect`, `arraypolar`, `arraypath`
- Cleanup: `overkill` (remove duplicate overlapping lines!), `purge` (remove unused styles/blocks), `audit` (verify drawing integrity)

### Parametric 2D Constraints
- Geometric: `gccoincident`, `gcperpendicular`, `gcparallel`, `gctangent`, `gcconcentric`, `gccollinear`, `gchorizontal`, `gcvertical`, `gcequal`, `gcfix`, `gcsymmetric`, `gcsmooth`, `autoconstrain`
- Dimensional: `dclinear`, `dchorizontal`, `dcvertical`, `dcaligned`, `dcradius`, `dcdiameter`, `dcangular`, `parameters`

### Annotations, Dimensions & GD&T
- Linear / Angular: `dimlinear`, `dimaligned`, `dimangular`, `dimbaseline`, `dimcontinue`, `dimordinate`, `qdim`
- Circular: `dimradius`, `dimdiameter`, `dimarc`, `centermark`, `centerline`
- Callouts & GD&T: `mleader`, `tolerance` (feature control frames), `text`, `mtext`, `table`, `tablestyle`

### Blocks, Layouts & Export
- Reusable symbols: `block`, `insert`, `attdef`, `attedit`, `wblock`
- Multi-view sheets: `layout`, `pagesetup`, `mview`, `vpclip`, `mspace`, `pspace`, `vplayer`
- Verification & Measurement: `dist`, `area`, `angle`, `radius`, `measuregeom`, `massprop`, `list`, `status`
- Export: `saveas` (`.dxf` / `.dwg`), `exportpdf`, `pdfbook`, `plot`

---

## 4. Multi-View Orthographic Drawing Layout Standard

When producing a manufacturing 2D drawing from a 3D part or spec:
1. **Projection:** Use **Third-Angle** (US/ANSI: Top above Front, Right to the right of Front) or **First-Angle** (ISO/VN/EU: Top below Front, Left to the right of Front) — label the projection symbol clearly in the title block.
2. **View Spacing:** Leave at least `40–60 mm` (scaled) between views for clean dimension chains without crowding.
3. **Dimensioning Discipline:**
   - Dimension **overall size** (`W`, `H`, `D`) once; never over-constrain with redundant chains (mark reference dims in parentheses `(25.0)`).
   - Place dimensions **outside** part outlines; avoid crossing extension lines.
   - Always add `centermark` to every hole/circle and `centerline` to symmetric profiles and cylindrical bores.
   - For holes on a bolt circle, draw the pitch circle on `CENTER` layer and call out `4× Ø5.5 THRU, EQ SP ON Ø60 BC`.
4. **Title Block Must Include:** Part Name, Material, Finish, General Tolerance (e.g. `ISO 2768-mK`), Scale, Units (`mm`), Projection, Revision, Date.

---

## 5. Pre-Export QA Checklist (CADCraft)

1. Run `overkill` to eliminate duplicate/overlapping segments (critical for laser/CNC DXF!).
2. Verify closed outer profiles (`pedit` → `join` or `boundary`) for laser/waterjet cutting.
3. Check `dist` and `area` on key features against design spec.
4. Run `purge` + `audit` → zero errors.
5. Frame full sheet with `zoom` extents, capture visual verification, and export `.dxf` + `.pdf`.
