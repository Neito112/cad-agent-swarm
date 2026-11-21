#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "=== CAD Agent Swarm Installer (macOS / Linux) ==="

SOLIDCRAFT_CLI="$(command -v solidcraft-cli || true)"
CADCRAFT_CLI="$(command -v cadcraft-cli || true)"

echo "SolidCraft CLI: ${SOLIDCRAFT_CLI:-NOT FOUND}"
echo "CADCraft CLI:   ${CADCRAFT_CLI:-NOT FOUND}"

# Update MCP JSON files using node or python3
if command -v node >/dev/null 2>&1; then
  SOLIDCRAFT_CLI="$SOLIDCRAFT_CLI" CADCRAFT_CLI="$CADCRAFT_CLI" node - <<'EOF'
const fs = require('fs');
const path = require('path');
const os = require('os');

const sc = process.env.SOLIDCRAFT_CLI;
const cc = process.env.CADCRAFT_CLI;

const targets = [
  [path.join(os.homedir(), '.gemini', 'config', 'mcp_config.json'), false],
  [path.join(os.homedir(), '.claude.json'), true],
  [path.join(os.homedir(), '.gemini', 'settings.json'), false],
];

for (const [filePath, includeType] of targets) {
  const dir = path.dirname(filePath);
  if (!fs.existsSync(dir)) continue;
  let data = {};
  if (fs.existsSync(filePath)) {
    const raw = fs.readFileSync(filePath, 'utf8').replace(/^\uFEFF/, '').trim();
    if (raw) data = JSON.parse(raw);
  }
  data.mcpServers = data.mcpServers || {};
  if (sc) {
    data.mcpServers.solidcraft = {
      command: sc,
      args: ['mcp', '--compact'],
      ...(includeType ? { type: 'stdio' } : {}),
    };
  }
  if (cc) {
    data.mcpServers.cadcraft = {
      command: cc,
      args: ['mcp'],
      ...(includeType ? { type: 'stdio' } : {}),
    };
    data.mcpServers['cadcraft-live'] = {
      command: cc,
      args: ['mcp', '--connect', '127.0.0.1:7979', '--lazy'],
      ...(includeType ? { type: 'stdio' } : {}),
    };
  }
  fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf8');
  console.log('[OK] Updated MCP config:', filePath);
}
EOF
fi

# Install skills to Antigravity and Claude Code
for TARGET in "$HOME/.gemini/config/skills" "$HOME/.claude/skills"; do
  mkdir -p "$TARGET"
  for SKILL_DIR in "$REPO_ROOT"/skills/*/; do
    NAME="$(basename "$SKILL_DIR")"
    rm -rf "$TARGET/$NAME"
    cp -R "$SKILL_DIR" "$TARGET/$NAME"
  done
  echo "[OK] Installed 3 swarm/token/playbook skills -> $TARGET"
done

# Sync 6 official SolidCraft skills
if command -v git >/dev/null 2>&1; then
  TMP_DIR="$(mktemp -d)"
  git clone --depth 1 --filter=blob:none --sparse https://github.com/tangency-labs/solidcraft.git "$TMP_DIR" >/dev/null 2>&1
  (cd "$TMP_DIR" && git sparse-checkout set skills >/dev/null 2>&1)
  for TARGET in "$HOME/.gemini/config/skills" "$HOME/.claude/skills"; do
    for S in solidcraft-modeling solidcraft-editing solidcraft-checking solidcraft-mechanisms solidcraft-sheetmetal solidcraft-reporting; do
      if [ -d "$TMP_DIR/skills/$S" ]; then
        rm -rf "$TARGET/$S"
        cp -R "$TMP_DIR/skills/$S" "$TARGET/$S"
      fi
    done
  done
  rm -rf "$TMP_DIR"
  echo "[OK] Synced 6 official SolidCraft skills"
fi

# Install 10 Claude Code specialist sub-agents
mkdir -p "$HOME/.claude/agents"
cp "$REPO_ROOT"/agents/*.md "$HOME/.claude/agents/"
echo "[OK] Installed 10 CAD specialist sub-agents -> $HOME/.claude/agents"

echo "Done! Reload MCP servers / start a new chat session to activate everything."
