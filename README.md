# ArtCraft Unified Studio & CAD Agent Swarm (`cad-agent-swarm`)

> **1 Single Master Agent Control Board for All 8 ArtCraft + SolidCraft Applications**
> Concept · Spec & Contracts · Live-Cursor 3D CAD · 2D Shop & CNC DXF · BOM & Costing · Studio Raytrace Renders · Photo Retouch · Vector & Packaging · Editorial PDF/Decks · VFX Motion · Commercial Video · Mastered Audio — with **`CHAIN_MODE` (ON / OFF)** and **Universal Token Optimization on every chat frame**.

---

## For AI Agents: 1-Command Auto-Install

Read **[`AGENT_INSTALL.md`](./AGENT_INSTALL.md)** and run the automated installer:

**Windows (PowerShell):**
```powershell
git clone https://github.com/Neito112/cad-agent-swarm.git "$env:USERPROFILE\.cad-agent-swarm"
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.cad-agent-swarm\install.ps1"
```

**macOS / Linux (Bash):**
```bash
git clone https://github.com/Neito112/cad-agent-swarm.git ~/.cad-agent-swarm
bash ~/.cad-agent-swarm/install.sh
```

---

## Single Master Control Board (`board/master-board.json` + Built-in ArtCraft Assistant)

The Unified Master Control Board is installed **both** as a standalone interactive board ([`board/dashboard.html`](./board/dashboard.html)) **and directly inside SolidCraft / ArtCraft's native Assistant panel (`Ctrl+Shift+A`)** via `%LOCALAPPDATA%\SolidCraft\agent-chat\work\` + live `ui.prefs`:

- **Zero-Friction Autonomous Main Chat:** Type a single prompt in the main chat and the background pipeline runs end-to-end automatically (when `CHAIN_MODE = ON`) — browsing & scraping via **Chrome Remote (`vionix-chrome`)**, running **Web Search**, downloading reference files/assets, and driving the **full ArtCraft + SolidCraft suite** with iterative self-editing until final deliverables pass QA.
- **`CHAIN_MODE = ON` (Móc nối):** Runs every stage in the active workflow sequentially, passing only a **`<= 300-token` JSON handoff capsule** between stages until final delivery.
- **`CHAIN_MODE = OFF` (Độc lập):** Runs **ONLY** the single clicked/requested stage (`S01`..`S12`), saves its artifacts, and stops immediately.
- **Custom Workflow Builder (`craft-workflow-builder`):** Dedicated sub-agent whose sole job is creating custom multi-stage workflows tailored to your project and persisting them into `board/master-board.json`.
- **Companion Tools Registered:** All 8 ArtCraft + SolidCraft apps (9 MCP entries) + **`craft-anything`** MCP (`craft-anything-cli mcp`) + **`vionix-chrome`** Chrome Remote across Antigravity, Claude Code, and Gemini CLI.

### The 12 Master Pipeline Stages

| Stage | Scope | Primary Agent | ArtCraft / SolidCraft MCP |
| --- | --- | --- | --- |
| `S01_CONCEPT` | Concept, creative brief, moodboard | `craft-concept-director` | `designcraft`, `vectorcraft` |
| `S02_SPEC_CONTRACT` | Engineering spec, parameters, SOW & contract | `craft-spec-contract` | `designcraft` |
| `S03_3D_MODEL` | 3D parametric CAD, sheet metal, mechanisms (**Live Agent Cursor!**) | `cad-swarm-orchestrator` (+7 CAD ants) | `solidcraft` (`--compact`) |
| `S04_2D_SHOP_CNC` | 2D shop drawings, construction plans, CNC/laser DXF | `cad-sketcher-2d` | `cadcraft`, `cadcraft-live` |
| `S05_BOM_COSTING` | Material take-off, BOM CSV, cost estimate | `cad-export-bom` | `solidcraft`, `cadcraft` |
| `S06_3D_RENDER` | Photorealistic studio raytrace renders & turntables | `craft-studio-renderer` | `solidcraft` |
| `S07_PHOTO_POST` | Color grading, retouching, key visuals & ad banners | `craft-photo-retoucher` | `photocraft` |
| `S08_VECTOR_BRAND` | Logos, icons, technical vector diagrams, packaging die-lines | `craft-vector-brand` | `vectorcraft` |
| `S09_LAYOUT_DECK` | Pitch decks, spec sheets, contracts PDF, print posters | `craft-layout-publisher` | `designcraft` |
| `S10_VFX_MOTION` | Motion graphics, exploded VFX, kinetic product reveals | `craft-vfx-film-sound` | `effectcraft` |
| `S11_VIDEO_EDIT` | Commercial video editing (`16:9` & `9:16` Reels) | `craft-vfx-film-sound` | `filmcraft` |
| `S12_SOUND_MASTER` | SFX, voiceover mix & `-14 LUFS` mastered audio | `craft-vfx-film-sound` | `soundcraft` |

### 7 Built-in Preset Workflows (Plus Unlimited Custom Workflows)
1. `full-product-launch`: `S01 -> S02 -> S03 -> S04 -> S05 -> S06 -> S07 -> S08 -> S09 -> S10 -> S11 -> S12`
2. `cnc-manufacturing-pack`: `S01 -> S02 -> S03 -> S04 -> S05`
3. `architectural-shop-drawings`: `S01 -> S02 -> S04 -> S05 -> S09`
4. `ad-commercial-video`: `S01 -> S06 -> S07 -> S10 -> S11 -> S12`
5. `brand-packaging-kit`: `S01 -> S08 -> S03 -> S06 -> S07 -> S09`
6. `client-proposal-contract`: `S01 -> S02 -> S05 -> S09`
7. `3d-print-prototype`: `S01 -> S03 -> S05 -> S06`

---

## Universal Token Optimization (Every Agent Chat Frame)

Every one of the **19 sub-agents** and **10 skills** enforces:
- **`solidcraft --compact` MCP mode** (50–70% smaller JSON + sketch/body summaries)
- **RTK (Rust Token Killer)** global CLI hook (60–90% shell output compression)
- **`<= 300-token` stage handoff capsules** (paths + key params only, zero raw log forwarding)
- **No unfiltered `list_commands` / `body_topology` dumps**
- **Numeric metrology checks (`measure`/`dist`/`area`) before image screenshots/renders**
- **Model tiering** (fast/cheap models for math/BOMs/formatting; frontier models for 3D assembly & creative direction)

---

## Repository Contents

- `board/master-board.json` & `board/dashboard.html` — Single Unified Control Board + interactive UI
- `launcher-patch/` — Native Rust (`egui 0.37`) patch embedding the Master Board Assistant chat panel directly inside **ArtCraft Launcher**'s main window (`Ctrl+Shift+A` / `AI ASSISTANT` button)
- `agents/` — **19 specialist sub-agents** (10 CAD swarm ants + 9 ArtCraft studio/board agents including `craft-master-board` and `craft-workflow-builder`)
- `skills/` — `craft-master-board`, `cad-visual-cursor-swarm`, `cad-token-optimizer`, `cad-drafting-3d-playbook` (+ installer syncs 6 official SolidCraft skills = **10 skills total**)
- `scripts/` — `install-artcraft-assistant.ps1` (embeds Master Board into SolidCraft Assistant), `enable-solidcraft-cursor.ps1` (live cursor activator) & `launch-cadcraft-live.bat`
- `install.ps1` & `install.sh` — Full auto-installer registering all 9 ArtCraft + SolidCraft MCP servers (`+ craft-anything` + `vionix-chrome`) across Antigravity, Claude Code, and Gemini CLI.

## License

MIT
