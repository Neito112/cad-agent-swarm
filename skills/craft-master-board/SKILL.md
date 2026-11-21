---
name: craft-master-board
description: >-
  Single Unified Master Control Board for the entire ArtCraft + SolidCraft
  creative & engineering studio (SolidCraft, CADCraft, DesignCraft, VectorCraft,
  PhotoCraft, EffectCraft, FilmCraft, SoundCraft). Controls 12 lifecycle stages
  with CHAIN_MODE (ON = auto-chain sequentially; OFF = run 1 stage only),
  delegates custom workflow creation to craft-workflow-builder, and enforces
  universal token optimization on every agent chat frame.
---

# ArtCraft Unified Master Agent Control Board

You are operating through the **SINGLE Master Control Board** (`board/master-board.json`).
Never scatter orchestration across ad-hoc plans. Every task maps cleanly to the 12-stage board.

---

## 0. Core Philosophy (Zero-Friction Autonomous Pipeline)

- **Main Chat Simplicity:** The user only sends a brief request in the main chat. When `CHAIN_MODE = ON`, run the entire background workflow end-to-end automatically until final deliverables are produced — do not stall asking for step-by-step confirmation.
- **Full Autonomous Toolkit:** Research, source, download, create, and iteratively refine using:
  - **Chrome Remote (`vionix-chrome` MCP)** for browsing, web extraction, and live web assets;
  - **Web Search (`tavily_tavily` / `search_web`)** for technical specs, standards, and references;
  - **Direct File Downloads** (datasheets, reference photos, STEP/DXF models, textures, audio/SFX);
  - **The Full ArtCraft + SolidCraft Suite** (`SolidCraft`, `CADCraft`, `DesignCraft`, `VectorCraft`, `PhotoCraft`, `EffectCraft`, `FilmCraft`, `SoundCraft`, `Craft Anything`) followed by **iterative edit-and-verify loops** until quality gates pass.

---

## 1. The Chain Mode Switch (`CHAIN_MODE: ON / OFF`)

Before executing ANY stage, check the requested mode (or default in `board/master-board.json`):

- **`CHAIN_MODE = ON` (Trạng thái MÓC NỐI — BẬT):**
  - Execute the selected workflow's stages **sequentially in order** (with parallel sub-agent waves *inside* each stage).
  - After each stage completes, emit a **Compact Handoff Capsule (`<= 300 tokens`)**:
    ```json
    {"stage":"S03_3D_MODEL","status":"DONE","artifacts":["out/part.sc","out/part.step"],"key_params":{"W":80,"D":50,"H":40},"next":"S04_2D_SHOP_CNC"}
    ```
  - Pass ONLY that capsule (never raw chat logs!) to the next stage's agent and continue automatically until the final stage completes.
- **`CHAIN_MODE = OFF` (Trạng thái ĐỘC LẬP — TẮT):**
  - Execute **ONLY** the single requested stage (e.g., `S04_2D_SHOP_CNC` or `S07_PHOTO_POST`).
  - Save its output artifacts and **STOP immediately** — do NOT trigger downstream stages.

---

## 2. The 12 Master Stages & ArtCraft MCP Mapping

| Stage | Purpose | Primary Agent | ArtCraft MCP |
| --- | --- | --- | --- |
| `S01_CONCEPT` | Concept, moodboard, creative brief | `craft-concept-director` | `designcraft`, `vectorcraft` |
| `S02_SPEC_CONTRACT` | Engineering spec, SOW, client contract | `craft-spec-contract` | `designcraft` |
| `S03_3D_MODEL` | 3D CAD, sheet metal, mechanisms (Live Cursor!) | `cad-swarm-orchestrator` (+7 CAD ants) | `solidcraft` (`--compact`) |
| `S04_2D_SHOP_CNC` | 2D shop drawings, construction, CNC/laser DXF | `cad-sketcher-2d` | `cadcraft`, `cadcraft-live` |
| `S05_BOM_COSTING` | Material take-off, BOM, cost estimate | `cad-export-bom` | `solidcraft`, `cadcraft` |
| `S06_3D_RENDER` | Photorealistic studio raytrace renders | `craft-studio-renderer` | `solidcraft` |
| `S07_PHOTO_POST` | Retouching, color grading, ad key visuals | `craft-photo-retoucher` | `photocraft` |
| `S08_VECTOR_BRAND` | Logos, icons, packaging die-lines, SVG diagrams | `craft-vector-brand` | `vectorcraft` |
| `S09_LAYOUT_DECK` | Pitch decks, spec booklets, contracts, posters | `craft-layout-publisher` | `designcraft` |
| `S10_VFX_MOTION` | Motion graphics, exploded VFX, product reveals | `craft-vfx-film-sound` | `effectcraft` |
| `S11_VIDEO_EDIT` | Commercial video editing (16:9, 9:16 Reels) | `craft-vfx-film-sound` | `filmcraft` |
| `S12_SOUND_MASTER` | SFX, voiceover mix, commercial audio mastering | `craft-vfx-film-sound` | `soundcraft` |

---

## 3. Custom Workflow Creation (`craft-workflow-builder`)

Whenever the user asks for a **new / custom workflow** (e.g., *"Tạo quy trình riêng cho nội thất showroom"* or *"Add a workflow for Kickstarter launch"*):
- Delegate directly to **`craft-workflow-builder`**.
- It defines the custom stage sequence, artifact contracts, and token budget, then writes the new workflow into `board/master-board.json` so it is immediately selectable on the Master Board.

---

## 4. Universal Token-Saving Protocol (Mandatory on EVERY Agent Chat)

Every single agent & sub-agent chat frame MUST obey these 5 rules:
1. **Compact Handoffs (`<= 300 tokens`):** Pass only structured JSON artifact paths + key numbers between stages — NEVER paste raw conversation history or full command catalogs.
2. **Compact MCP + RTK:** Always use `solidcraft` with `--compact`, filter `inspect_design` by name, and let RTK compress shell output (60–90% savings).
3. **Batch Smartly:** Group 4–8 related CAD/ArtCraft commands per `batch` / `script` call (keeps Live Agent Cursor smooth while cutting round-trip prompt tokens by 5–8×).
4. **Numeric QA Before Vision:** Run `measure` / `dist` / `area` (~150 tokens) before taking `screenshot` / `render` (~1.5k image tokens).
5. **Model Tiering:** Use fast/cheap models for BOMs, tables, formatting, and coordinate math; reserve frontier models for complex 3D assemblies, creative direction, and final review.
