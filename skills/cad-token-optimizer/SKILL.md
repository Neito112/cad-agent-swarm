---
name: cad-token-optimizer
description: >-
  Token-saving discipline and tool stack for SolidCraft (3D) and CADCraft (2D)
  AI agents. Cuts CAD MCP and shell token burn by 50-90% using --compact mode,
  filtered inspection, on-demand skill_reference, smart batching, and companion
  compressors (RTK, Headroom, TokenSave, FreeLLMAPI).
---

# CAD Token Optimizer Playbook

CAD sessions can easily waste 100k+ tokens on unfiltered command catalogs, raw topology dumps, and verbose CLI logs. Follow these mandatory rules to cut token consumption by **50–90%** without losing geometric precision or live cursor visibility.

---

## 1. SolidCraft MCP Token-Saving Rules (50–70% Savings)

1. **Always run with `--compact` (or `SOLIDCRAFT_MCP_COMPACT=1`)**
   - Un-pretty-prints tool JSON replies.
   - Summarizes sketches in `inspect_design` instead of dumping every primitive.
   - Enables `sketches: ["Sketch1"]` and `bodies: ["Body1"]` filters on `inspect_design`.
2. **NEVER call unfiltered `list_commands` or full `body_topology`**
   - `list_commands` returns hundreds of schemas (~15k–40k tokens).
   - Instead, call `describe_command` ONLY for the 1–2 commands whose exact parameter names you need, or call `skill_reference` for targeted topics.
   - Only call `body_topology` on a specific named body when edge/face pick coordinates are genuinely ambiguous.
3. **Smart Batching (Sweet Spot: 4–8 Commands per `batch`)**
   - Single-command `execute` loops multiply round-trip prompt overhead (10 calls = 10× conversation context re-sent!).
   - Giant 80-command batches hide errors and make the live cursor hard to debug.
   - **Optimal pattern:** Group one logical feature per `batch` (e.g., `sketch.create` + 4 lines + constraints + `sketch.close` + `solid.extrude` = 1 `batch` call). SolidCraft's Agent Cursor still animates every command inside the batch!
4. **Verify Numerically First, Screenshot Selectively**
   - `measure` costs ~150 tokens and catches 95% of math/cut/volume bugs immediately.
   - `screenshot` costs ~1,000–2,000 image tokens — use it at **stage milestones** (base solid, post-cuts, final assembly), not after every single line segment.
5. **Compute All Math Upfront in Wave 1**
   - Have `cad-parametric-architect` compute every coordinate, clearance, and expected volume in one pass before touching CAD tools, preventing trial-and-error undo/redo loops.

---

## 2. CADCraft (2D) Token-Saving Rules

1. **Pre-plan all layers and entity coordinates as compact JSON arrays** before calling drafting commands.
2. **Avoid redundant `list`/`entities` full-drawing dumps** on large DXF/DWG files — filter by layer (`qselect`) or query specific extents (`status`, `dist`, `area`).
3. **Run `overkill`, `purge`, `audit`** only once at the end before `exportpdf` / `saveas`.

---

## 3. Multi-Sub-Agent Token Isolation ("Ant Colony" Advantage)

- **Context isolation:** Heavy research (ISO fastener tables, reading reference guides, inspecting 10 screenshots) stays inside short-lived sub-agents. Only concise JSON/Markdown summaries (~200–500 tokens) return to the orchestrator.
- **Model tiering:**
  - Use **fast/cheap models** (`flash`, `glm-5.3-flash`, `haiku`, local `ollama`) for repetitive coordinate math, BOM formatting, and QA checks.
  - Reserve **frontier models** for complex 3D kinematic assemblies, organic lofts/sweeps, and tricky boolean debugging.

---

## 4. Complementary Open-Source Token-Saving Tools

| Tool | Repo | What It Compresses | Typical Savings |
| --- | --- | --- | --- |
| **SolidCraft `--compact`** | `tangency-labs/solidcraft` | MCP JSON & `inspect_design` output | 50–70% |
| **RTK (Rust Token Killer)** | `rtk-ai/rtk` | Shell/CLI output (`git`, `cargo`, `pytest`, logs) via Claude Code hooks | 60–90% |
| **Headroom** | `headroomlabs-ai/headroom` | JSON-heavy tool payloads & RAG chunks | 60–95% |
| **TokenSave** | `aovestdipaperino/tokensave` | Local semantic code graph replacing blind `grep`/`Read` | 60–80% |
| **FreeLLMAPI** | `tashfeenahmed/freellmapi` | Prompt compression pipeline + free multi-provider routing | 30–60% + $0 API |
