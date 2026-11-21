# AGENT_INSTALL.md — Automated Installation Protocol for AI Agents

> **Audience:** Autonomous AI coding agents (Google Antigravity, Claude Code, Gemini CLI, Codex, OpenCode, Hermes).
> Follow these steps in order to install the **complete ArtCraft Unified Studio & CAD Swarm** stack automatically.

---

## Step 1 — Clone or Update This Repository

**Windows (PowerShell):**
```powershell
$repo = "$env:USERPROFILE\.cad-agent-swarm"
if (Test-Path "$repo\.git") {
  git -C $repo pull --ff-only
} else {
  git clone https://github.com/Neito112/cad-agent-swarm.git $repo
}
```

**macOS / Linux:**
```bash
REPO="$HOME/.cad-agent-swarm"
if [ -d "$REPO/.git" ]; then
  git -C "$REPO" pull --ff-only
else
  git clone https://github.com/Neito112/cad-agent-swarm.git "$REPO"
fi
```

---

## Step 2 — Run the Automated Installer

**Windows (PowerShell):**
```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.cad-agent-swarm\install.ps1"
```

**macOS / Linux:**
```bash
bash "$HOME/.cad-agent-swarm/install.sh"
```

What the installer automatically does:
1. **Detects all 9 ArtCraft + SolidCraft CLIs** (`solidcraft-cli`, `cadcraft-cli`, `designcraft-cli`, `vectorcraft-cli`, `photocraft-cli`, `effectcraft-cli`, `filmcraft-cli`, `soundcraft-cli`, `craft-anything-cli`).
2. **Registers all 10+ MCP servers** (including `solidcraft --compact`, `cadcraft-live`, `craft-anything`, and preserves/shares `vionix-chrome` Chrome Remote) across:
   - Antigravity: `~/.gemini/config/mcp_config.json`
   - Claude Code: `~/.claude.json`
   - Gemini CLI: `~/.gemini/settings.json`
3. **Installs the Unified Master Control Board** (`board/master-board.json` + `board/dashboard.html`) to `~/.cad-agent-swarm/board/` **AND embeds it directly into SolidCraft/ArtCraft's native Assistant panel (`Ctrl+Shift+A`)** (`%LOCALAPPDATA%\SolidCraft\agent-chat\work\{CLAUDE.md,AGENTS.md,GEMINI.md,board\}` + live `ui.prefs` `agent_instructions`).
4. **Enables Zero-Friction Autonomous Main Chat:** A single user prompt triggers background end-to-end execution (`CHAIN_MODE = ON`) using Chrome Remote (`vionix-chrome`), web search, file downloads, and the ArtCraft + SolidCraft suite with iterative self-editing.
5. **Installs all 10 skills** into `~/.gemini/config/skills/` and `~/.claude/skills/`:
   - 4 studio/swarm/token/playbook skills: `craft-master-board`, `cad-visual-cursor-swarm`, `cad-token-optimizer`, `cad-drafting-3d-playbook`
   - 6 official SolidCraft skills synced from `https://github.com/tangency-labs/solidcraft`
6. **Installs all 19 specialist sub-agents** (`agents/*.md`) into `~/.claude/agents/`:
   - Board & Workflow: `craft-master-board`, `craft-workflow-builder`
   - Concept / Spec / Render / Photo / Vector / Layout / Video+VFX+Sound: `craft-concept-director`, `craft-spec-contract`, `craft-studio-renderer`, `craft-photo-retoucher`, `craft-vector-brand`, `craft-layout-publisher`, `craft-vfx-film-sound`
   - 3D/2D CAD Swarm (10): `cad-swarm-orchestrator`, `cad-cursor-choreographer`, `cad-parametric-architect`, `cad-sketcher-2d`, `cad-solid-modeler`, `cad-sheetmetal-specialist`, `cad-mechanism-assembler`, `cad-geometry-qa`, `cad-visual-reviewer`, `cad-export-bom`
7. **Installs RTK (Rust Token Killer)** globally + configures Claude Code hooks for 60–90% CLI output compression.
8. **Activates Live Agent Cursor** (`ui.agent_cursor`: `show: true`, `follow_camera: true`, `speed: 1.5`) on any running SolidCraft instance.

---

## Step 3 — Operating the Single Master Control Board

- **`CHAIN_MODE = ON` (Móc nối):** Runs workflow stages sequentially via `craft-master-board`, passing only a `<= 300-token` JSON handoff capsule between stages.
- **`CHAIN_MODE = OFF` (Độc lập):** Runs ONLY the single requested stage (`S01`..`S12`) and stops immediately.
- **Custom Workflows:** Delegate to `craft-workflow-builder` whenever the user requests a new workflow pipeline; it persists the new workflow to `board/master-board.json` and `board/dashboard.html`.

---

## Step 4 — Post-Install Verification Checklist

Verify and report each item before completing:
- [ ] All detected ArtCraft/SolidCraft MCP servers exist in MCP config files, and `solidcraft` uses `"--compact"`.
- [ ] All 10 skill folders exist in `~/.gemini/config/skills/` and `~/.claude/skills/`.
- [ ] All 19 `*.md` sub-agents exist in `~/.claude/agents/`.
- [ ] `board/master-board.json` parses cleanly and `board/dashboard.html` opens without error.
- [ ] `rtk --version` succeeds on `PATH`.
- [ ] Remind the user to reload MCP servers / start a new chat session to activate all 9 MCP servers and skills.
