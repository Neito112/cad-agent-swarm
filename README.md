# CAD Agent Swarm (`cad-agent-swarm`)

> **Multi-Sub-Agent ("Ant Colony") CAD Automation Suite for SolidCraft (3D) & CADCraft (2D)**
> Live Visual Agent Cursor on every drawing step · 10 Specialist Sub-Agents · 50–90% Token Optimization · Ultra-Detailed 3D & 2D Engineering Playbooks.

---

## For AI Agents: Auto-Install This Full Suite

If you are an AI agent (Antigravity, Claude Code, Gemini CLI, Codex, OpenCode, Hermes), read **[`AGENT_INSTALL.md`](./AGENT_INSTALL.md)** and run the automated installer directly:

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

## What You Get

| Module | What It Does |
| --- | --- |
| **Live Visual Agent Cursor** | Enables SolidCraft's native `ui.agent_cursor` (`show: true`, `follow_camera: true`, `speed: 1.5`) so every draw/sketch/extrude/fillet glides the cursor to the toolbar button & geometry pick with click ripples. |
| **SolidCraft (3D) + CADCraft (2D) MCP** | Auto-registers `solidcraft` (with `--compact`!), `cadcraft`, and `cadcraft-live` (`--connect 127.0.0.1:7979 --lazy`) across Antigravity, Claude Code, and Gemini CLI. |
| **10-Agent "Ant Colony" Swarm** | 10 specialist sub-agents (`~/.claude/agents/cad-*.md`) + 3-wave parallel orchestration skill (`cad-visual-cursor-swarm`) for Antigravity & Claude Code. |
| **Token Optimization Suite** | `--compact` MCP responses (50–70% savings), filtered `inspect_design`, smart batching, plus integration guides for **RTK**, **Headroom**, **TokenSave**, and **FreeLLMAPI**. |
| **Ultra-Detailed CAD Playbooks** | Complete 3D parametric modeling & 2D technical drawing reference guides (ISO/DIN M2–M12 tables, FDM/SLA tolerances, sheet-metal K-factors, CADCraft 457-command drafting workflow, GD&T, layers, viewports). |
| **6 Official SolidCraft Skills** | Auto-syncs `solidcraft-modeling`, `solidcraft-editing`, `solidcraft-checking`, `solidcraft-mechanisms`, `solidcraft-sheetmetal`, and `solidcraft-reporting` from `tangency-labs/solidcraft`. |

---

## Repository Structure

```text
cad-agent-swarm/
├── README.md
├── AGENT_INSTALL.md                  # Machine-readable auto-install protocol for AI agents
├── install.ps1                       # 1-command Windows installer
├── install.sh                        # 1-command macOS/Linux installer
├── agents/                           # 10 specialist CAD sub-agents (.claude/agents/)
│   ├── cad-swarm-orchestrator.md
│   ├── cad-cursor-choreographer.md
│   ├── cad-parametric-architect.md
│   ├── cad-sketcher-2d.md
│   ├── cad-solid-modeler.md
│   ├── cad-sheetmetal-specialist.md
│   ├── cad-mechanism-assembler.md
│   ├── cad-geometry-qa.md
│   ├── cad-visual-reviewer.md
│   └── cad-export-bom.md
├── skills/
│   ├── cad-visual-cursor-swarm/      # Live cursor + 3-wave multi-sub-agent swarm
│   ├── cad-token-optimizer/          # Token-saving protocols + RTK/Headroom/FreeLLMAPI
│   └── cad-drafting-3d-playbook/     # Ultra-detailed 3D & 2D engineering reference guides
│       ├── SKILL.md
│       └── references/
│           ├── solidcraft-3d-guide.md
│           └── cadcraft-2d-guide.md
└── scripts/
    ├── enable-solidcraft-cursor.ps1  # Live-enables ui.agent_cursor on running SolidCraft
    └── launch-cadcraft-live.bat      # Launches CADCraft with --control 7979 for live MCP
```

## Quick Verification After Install

1. **SolidCraft Live Mode:** Open SolidCraft → **Preferences → Assistant → Agents through MCP → Enable "Let AI agents connect"**.
2. **CADCraft Live Mode:** Run `scripts/launch-cadcraft-live.bat` (or `cadcraft --control 7979`).
3. **Reload MCP / Skills** in Antigravity or Claude Code, then ask:
   > *"Use the CAD visual cursor swarm to design an L-bracket 80×50×40mm, 5mm thick, 4× M5 mounting holes, R3 fillets, verify volume, and export STEP + DXF."*

## License

MIT
