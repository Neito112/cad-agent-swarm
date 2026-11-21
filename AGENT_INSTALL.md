# AGENT_INSTALL.md — Automated Installation Protocol for AI Agents

> **Audience:** Autonomous AI coding agents (Google Antigravity, Claude Code, Gemini CLI, Codex, OpenCode, Hermes).
> Follow these steps in order to install the **complete** `cad-agent-swarm` stack without asking unnecessary questions.

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
1. **Detects binaries:** Locates `solidcraft-cli` and `cadcraft-cli` (checks `PATH` + default install locations on Windows/macOS/Linux).
2. **Configures MCP servers with `--compact` token-saving mode** in:
   - Antigravity: `~/.gemini/config/mcp_config.json`
   - Claude Code: `~/.claude.json`
   - Gemini CLI: `~/.gemini/settings.json`
   Registers:
   - `solidcraft`: `solidcraft-cli mcp --compact`
   - `cadcraft`: `cadcraft-cli mcp`
   - `cadcraft-live`: `cadcraft-cli mcp --connect 127.0.0.1:7979 --lazy`
3. **Installs all 9 skills** into `~/.gemini/config/skills/` and `~/.claude/skills/`:
   - 3 swarm/optimization/playbook skills from this repo:
     - `cad-visual-cursor-swarm`
     - `cad-token-optimizer`
     - `cad-drafting-3d-playbook`
   - 6 official SolidCraft skills synced from `https://github.com/tangency-labs/solidcraft` (`skills/`):
     - `solidcraft-modeling`, `solidcraft-editing`, `solidcraft-checking`, `solidcraft-mechanisms`, `solidcraft-sheetmetal`, `solidcraft-reporting`
4. **Installs all 10 specialist sub-agents** (`agents/cad-*.md`) into `~/.claude/agents/`.
5. **Activates Live Agent Cursor** on any currently running SolidCraft desktop instance (`ui.agent_cursor`: `show: true`, `follow_camera: true`, `speed: 1.5`).

---

## Step 3 — Optional Extra Token-Saving Tools

If the user also wants maximum CLI/proxy token compression, install these open-source companions:

1. **RTK (Rust Token Killer)** — 60–90% shell/CLI output compression:
   - Repo: `https://github.com/rtk-ai/rtk`
   - Install (Cargo): `cargo install --git https://github.com/rtk-ai/rtk` (or download prebuilt release binary and run `rtk init -g` for Claude Code hooks).
2. **FreeLLMAPI** — Free multi-provider router + built-in prompt compression:
   - Repo: `https://github.com/tashfeenahmed/freellmapi`
   - Point Claude Code with `npx freellmapi setup-claude --url http://127.0.0.1:3001`.
3. **Headroom / TokenSave** — JSON & codebase graph token reducers:
   - `https://github.com/headroomlabs-ai/headroom`
   - `https://github.com/aovestdipaperino/tokensave`

---

## Step 4 — Post-Install Verification Checklist (Run Before Reporting Done)

Verify each item and report the exact status to the user:
- [ ] `solidcraft`, `cadcraft`, `cadcraft-live` exist in MCP config files and `solidcraft` includes `"--compact"`.
- [ ] All 9 skill folders exist in `~/.gemini/config/skills/` and `~/.claude/skills/`.
- [ ] All 10 `cad-*.md` agent files exist in `~/.claude/agents/`.
- [ ] If SolidCraft is open with MCP enabled, `enable-solidcraft-cursor.ps1` returns `{"ok":true,"result":{"follow_camera":true,"show":true,"speed":1.5}}`.
- [ ] Remind the user to reload MCP servers / start a new chat session to activate newly added tools and skills.
