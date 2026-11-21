---
name: cad-visual-cursor-swarm
description: >-
  Multi-sub-agent ("ant colony") CAD orchestration skill for SolidCraft (3D) and
  CADCraft (2D) that forces EVERY drawing operation to display the live visual
  Agent Cursor on the canvas/viewport. Use whenever drafting, modeling, editing,
  assembling, checking, or exporting in SolidCraft or CADCraft.
---

# CAD Visual-Cursor Multi-Sub-Agent Swarm ("Ant Colony")

This skill enforces **two mandatory rules** on every SolidCraft (3D) and CADCraft (2D) task:

1. **Always Show the Live Agent Cursor on Every Drawing Operation**
2. **Always Decompose & Fan Out Across Many Parallel Sub-Agents ("Đông như kiến cỏ")**

---

## 1. Visual Cursor Protocol (Mandatory)

### SolidCraft (3D)
SolidCraft's desktop app has a native **Agent Cursor** (`ui.agent_cursor`) that glides to every toolbar button, sketch entity, edge/face pick, and command with localized tooltips and click ripples.

**Before executing ANY drawing/modeling command:**
1. Ensure SolidCraft is running with **Preferences → Assistant → Agents through MCP → Let AI agents connect** enabled so `solidcraft` MCP bridges live to the desktop window.
2. Enable the live Agent Cursor (`show: true`, `follow_camera: true`, `speed: 1.5`) by running the bundled helper script:
   ```powershell
   powershell -ExecutionPolicy Bypass -File "C:\Users\Neito\.gemini\config\skills\cad-visual-cursor-swarm\scripts\enable-solidcraft-cursor.ps1" -Speed 1.5
   ```
3. **Never pass `"animate": false`** on `execute` or `batch` calls when the user is watching.
4. **Visible Step-by-Step Pacing:**
   - Group tightly-coupled sketch primitives into small readable batches (3–8 steps) rather than one opaque 80-step dump, so the cursor visibly visits each tool and geometry pick.
   - Frame the viewport with `view.camera` / `fit` after major features so the user watches the part grow cleanly.

### CADCraft (2D)
1. For live visual drafting, connect via the `cadcraft-live` MCP server (`--connect 127.0.0.1:7979 --lazy`), with CADCraft launched via `C:\Users\Neito\.gemini\antigravity\scratch\launch-cadcraft-live.bat` (`cadcraft.exe --control 7979`).
2. Keep `view.set` framed on the active drafting zone so every `line`, `circle`, `arc`, `offset`, `trim`, `hatch`, and `dimension` appears live on screen.

---

## 2. Multi-Sub-Agent Swarm Architecture ("Ant Colony")

Do **NOT** do everything sequentially in a single agent turn. Decompose every CAD request into parallel waves of specialized sub-agents:

### Wave 1 — Parallel Research, Math & Architecture (Spawn 3–5 Sub-Agents Simultaneously)
- **`cad-parametric-architect`**: Computes exact dimensions, parameter tables, tolerances, clearances, thread/fastener tables, and analytic volume/mass targets.
- **`cad-cursor-choreographer`**: Verifies live bridge connection, activates `ui.agent_cursor` (`show: true`, `follow_camera: true`), and plans camera framing waypoints.
- **`cad-standards-researcher`** (optional): Looks up ISO/DIN/ANSI fastener sizes, sheet-metal bend K-factors, bearing dimensions, or reference specs.
- **`cad-sketcher-2d` (planner)**: Designs 2D profile coordinates, sketch planes, and CADCraft layer/block structure.

### Wave 2 — Feature Execution (Coordinated Live Cursor Drawing)
Because live CAD documents mutate shared geometry state, **serialize geometry writes through the live cursor** while keeping sub-agents computing the next feature's coordinates, sketch profiles, and verification math in parallel:
- **`cad-sketcher-2d`**: Draws 2D sketches (SolidCraft) or 2D technical drawings (CADCraft).
- **`cad-solid-modeler`**: Executes 3D solids (extrude, revolve, loft, sweep, shell, boolean, fillet, chamfer, pattern).
- **`cad-sheetmetal-specialist`**: Executes base/edge/contour flanges, hems, folds, flat patterns, and bend tables.
- **`cad-mechanism-assembler`**: Places components, joints, motion links, closed loops, and contact sets.

### Wave 3 — Parallel Verification & Delivery (Spawn 3–4 Sub-Agents Simultaneously)
- **`cad-geometry-qa`**: Runs `measure`, checks volume/bounding-box against Wave 1 analytic formulas, checks parameter ranges (`solidcraft-checking`).
- **`cad-visual-reviewer`**: Takes multi-angle `screenshot`s (iso, front, top, section) and visually inspects for missing cuts, floating bodies, or bad fillets.
- **`cad-export-bom`**: Exports `.step`, `.stl`, `.3mf`, `.dxf`, `.sc` and generates BOM + parameter summary.

---

## 3. How to Spawn the Swarm

- **In Antigravity:**
  - Use `invoke_subagent` (multiple parallel calls in one turn) or `swarm` (`action: "add"`, `tasks: [...]`) or `run_workflow` to fan out Wave 1 and Wave 3 workers simultaneously.
  - Pair with the official installed skills: `solidcraft-modeling`, `solidcraft-editing`, `solidcraft-checking`, `solidcraft-mechanisms`, `solidcraft-sheetmetal`, `solidcraft-reporting`.
- **In Claude Code:**
  - Delegate in parallel to the installed specialist agents in `~/.claude/agents/cad-*.md` (`cad-swarm-orchestrator`, `cad-cursor-choreographer`, `cad-parametric-architect`, `cad-sketcher-2d`, `cad-solid-modeler`, `cad-sheetmetal-specialist`, `cad-mechanism-assembler`, `cad-geometry-qa`, `cad-visual-reviewer`, `cad-export-bom`).
