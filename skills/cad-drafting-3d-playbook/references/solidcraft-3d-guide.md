# SolidCraft 3D Parametric Modeling Reference Guide

> Detailed engineering rules, coordinate traps, ISO tables, and verification checklists for SolidCraft 3D CAD agents.

---

## 1. Coordinate System & Sketch Plane Traps

SolidCraft uses a right-handed Cartesian system (`mm` default):
- **XY Plane (Top):** Sketch `+X = World +X`, Sketch `+Y = World +Y`, Normal `+Z`.
- **XZ Plane (Front):** WATCH OUT — verify sketch `+X`/`+Y` mapping via `inspect_design` or `solidcraft-modeling` reference before placing asymmetric cuts; a flipped Y sign puts pockets upside down!
- **YZ Plane (Right):** Sketch axes map to World Y/Z — always confirm normal direction before `extrude` (positive distance follows plane normal).
- **Best Practice:** Center symmetric parts around `(0, 0, 0)` on XY, extruding `0 → +H` (or symmetric `-H/2 → +H/2`). This makes mirroring and hole patterns trivial (`±x, ±y`).

---

## 2. Feature Ordering & Boolean Safety

Always build in this exact timeline order:
1. **User Parameters** (`param.set` / `set_parameter`) — define every driving dimension first (`W`, `L`, `H`, `t`, `r_fillet`, `d_hole`).
2. **Base Solid** — primary block/revolve/sweep/loft. Verify `measure` volume = exact analytic formula.
3. **Secondary Bosses / Ribs / Standoffs** — join to base solid (`operation: "join"`). Verify `bodies.length == 1`.
4. **Shell** (if enclosure) — apply BEFORE internal ribs/standoffs if uniform wall, or AFTER outer fillets so inner wall automatically gets `R_inner = R_outer - wall`.
5. **Subtractive Cuts & Holes** — extrude-cut through-all or explicit depth (`depth = wall + 1.0` to avoid coplanar zero-thickness faces!).
   - **Trap:** A cut that misses the body still reports `ok: true`! ALWAYS check `measure` volume decreased by `ΔV = area × depth`.
6. **Edge Dress-Up (Fillets & Chamfers) LAST** — apply structural fillets first, then small cosmetic edge breaks (`0.5–1.0 mm`). Keep `fillet_r < 0.45 × min_adjacent_edge`.

---

## 3. Standard Metric Fastener & Clearance Table (ISO 273 / DIN 912)

Use these exact diameters (in `mm`) for mounting holes, bosses, and heat-set inserts:

| Screw | Nominal Ø | Close Clearance | Normal Clearance | Tap Drill (75% Thread) | Socket Cap Head Ø (DIN 912) | Counterbore Ø | Counterbore Depth | Heat-Set Insert Hole (FDM) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| **M2** | 2.0 | 2.2 | 2.4 | 1.6 | 3.8 | 4.4 | 2.2 | 3.2 |
| **M2.5** | 2.5 | 2.7 | 2.9 | 2.05 | 4.5 | 5.4 | 2.7 | 3.8 |
| **M3** | 3.0 | 3.2 | 3.4 | 2.5 | 5.5 | 6.2 | 3.2 | 4.0–4.2 |
| **M4** | 4.0 | 4.3 | 4.5 | 3.3 | 7.0 | 7.8 | 4.2 | 5.6 |
| **M5** | 5.0 | 5.3 | 5.5 | 4.2 | 8.5 | 9.5 | 5.2 | 6.4 |
| **M6** | 6.0 | 6.4 | 6.6 | 5.0 | 10.0 | 11.0 | 6.2 | 8.0 |
| **M8** | 8.0 | 8.4 | 9.0 | 6.8 | 13.0 | 14.5 | 8.2 | — |
| **M10** | 10.0 | 10.5 | 11.0 | 8.5 | 16.0 | 17.5 | 10.2 | — |
| **M12** | 12.0 | 13.0 | 13.5 | 10.2 | 18.0 | 19.5 | 12.2 | — |

**Minimum boss outer diameter around a hole:** `OD_boss >= 2.0 × hole_d` (or `hole_d + 2 × wall`, minimum `1.6 mm` radial wall for FDM).

---

## 4. Manufacturing Clearances & Design Rules

### FDM 3D Printing (0.4 mm nozzle)
- **Tight / Press fit:** `0.10 – 0.15 mm` per side
- **Snug / Sliding fit:** `0.20 – 0.30 mm` per side (use `0.25 mm` default for lids/snap-fits)
- **Loose / Rotating fit:** `0.35 – 0.50 mm` per side
- **Minimum wall thickness:** `1.6 mm` (4 perimeters) structural; `1.2 mm` non-structural
- **Overhangs:** Keep `<= 45°` from vertical; use `45°` chamfers on bottom edges instead of fillets (avoids elephant-foot sag).

### SLA / Resin 3D Printing
- **Clearance:** `0.10 – 0.15 mm` per side
- **Minimum wall thickness:** `1.0 – 1.2 mm`
- **Drain holes:** `>= 2.5 mm` on hollow enclosures.

### CNC Milling (3-axis)
- **Internal pocket vertical corners:** MUST have fillet radius `R >= tool_radius + 0.5 mm` (e.g., `R >= 3.5 mm` for Ø6 mm endmill).
- **Max pocket depth:** `<= 4 × tool_diameter`.
- **Minimum wall thickness:** `>= 1.0 mm` (aluminum), `>= 1.5 mm` (plastics).

### Sheet Metal (Laser Cut + Press Brake)
- **Typical K-factor:** Soft Aluminum `0.33–0.40`, Mild Steel `0.40–0.44`, Stainless Steel `0.44–0.48`.
- **Minimum inside bend radius:** `R_in >= 1.0 × thickness` (steel/Al 5052); `>= 1.5 × t` (Al 6061-T6).
- **Minimum flange length:** `>= 4 × t + R_in`.
- **Hole-to-bend distance:** Edge of hole `>= 2.5 × t + R_in` from bend line (prevents hole distortion).

---

## 5. Verification Checklist Before Delivery

1. `measure` body count matches intended part count (no accidental disconnected fragments).
2. `measure` bounding box `[dx, dy, dz]` matches `W × D × H` within `0.01 mm`.
3. `measure` volume matches analytic hand calculation within `0.5%`.
4. `check_parameters` passes with zero broken expressions or out-of-range warnings.
5. `screenshot` captured from **Isometric**, **Front**, **Top**, and **Bottom/Section** views and visually verified.
6. Exported files: `.sc` (native parametric), `.step` (CNC/CAD), `.stl` or `.3mf` (`quality: "fine"` for 3D printing).
