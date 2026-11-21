---
name: cad-drafting-3d-playbook
description: >-
  Ultra-detailed engineering reference playbook for 3D parametric modeling
  (SolidCraft) and 2D technical drafting (CADCraft). Includes ISO/DIN fastener
  tables, 3D-printing & CNC tolerances, sheet-metal K-factors, sketch-plane
  coordinate traps, layer standards, GD&T, and multi-stage QA checklists.
---

# CAD 3D Modeling & 2D Technical Drawing Playbook

Load the exact reference file needed for your task (do NOT load both if you only need one):

- **3D Parametric Modeling, Sheet Metal & Mechanisms (SolidCraft):**
  Read [`references/solidcraft-3d-guide.md`](./references/solidcraft-3d-guide.md)
- **2D Technical Drafting, Layers, Constraints & DXF/PDF (CADCraft):**
  Read [`references/cadcraft-2d-guide.md`](./references/cadcraft-2d-guide.md)

---

## Universal Engineering Workflow (5 Mandatory Gates)

1. **Gate 1 — Parametric Spec Sheet:** Define units (`mm`), global parameters (`W`, `D`, `H`, `wall`, `fillet_r`, `hole_d`), manufacturing process (FDM / SLA / CNC / Laser+Bend), and target analytic volume/area.
2. **Gate 2 — Datum & Skeleton First:** Establish origin symmetry (center on XY/XZ planes whenever symmetric) so mirrors, patterns, and hole placements stay clean and parametric.
3. **Gate 3 — Additive → Subtractive → Dress-Up Order:**
   - Base solids & bosses FIRST
   - Shell / pockets / mounting holes SECOND
   - Fillets, chamfers, and cosmetic drafts LAST (prevents broken edge references when earlier features change).
4. **Gate 4 — Numeric Metrology Check:** Verify `measure` (volume, bounding box, body count) against hand-calculated analytic formula (error < 0.5%).
5. **Gate 5 — Visual & Manufacturing Sign-off:** Multi-angle `screenshot` audit + export production formats (`.step` + `.stl`/`.3mf` + `.dxf` + `.sc`).
