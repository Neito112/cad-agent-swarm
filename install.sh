#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "=== ArtCraft Unified Studio & CAD Swarm Installer (macOS / Linux) ==="

find_bin() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    command -v "$name"
    return
  fi
  for p in "/usr/local/bin/$name" "$HOME/.cargo/bin/$name" "$HOME/.local/bin/$name"; do
    if [ -x "$p" ]; then
      echo "$p"
      return
    fi
  done
  echo ""
}

SOLIDCRAFT_CLI="$(find_bin solidcraft-cli)"
CADCRAFT_CLI="$(find_bin cadcraft-cli)"
DESIGNCRAFT_CLI="$(find_bin designcraft-cli)"
VECTORCRAFT_CLI="$(find_bin vectorcraft-cli)"
PHOTOCRAFT_CLI="$(find_bin photocraft-cli)"
EFFECTCRAFT_CLI="$(find_bin effectcraft-cli)"
FILMCRAFT_CLI="$(find_bin filmcraft-cli)"
SOUNDCRAFT_CLI="$(find_bin soundcraft-cli)"

echo "solidcraft : ${SOLIDCRAFT_CLI:-NOT FOUND}"
echo "cadcraft   : ${CADCRAFT_CLI:-NOT FOUND}"
echo "designcraft: ${DESIGNCRAFT_CLI:-NOT FOUND}"
echo "vectorcraft: ${VECTORCRAFT_CLI:-NOT FOUND}"
echo "photocraft : ${PHOTOCRAFT_CLI:-NOT FOUND}"
echo "effectcraft: ${EFFECTCRAFT_CLI:-NOT FOUND}"
echo "filmcraft  : ${FILMCRAFT_CLI:-NOT FOUND}"
echo "soundcraft : ${SOUNDCRAFT_CLI:-NOT FOUND}"

# Register all detected ArtCraft + SolidCraft MCP servers
if command -v node >/dev/null 2>&1; then
  SOLIDCRAFT_CLI="$SOLIDCRAFT_CLI" \
  CADCRAFT_CLI="$CADCRAFT_CLI" \
  DESIGNCRAFT_CLI="$DESIGNCRAFT_CLI" \
  VECTORCRAFT_CLI="$VECTORCRAFT_CLI" \
  PHOTOCRAFT_CLI="$PHOTOCRAFT_CLI" \
  EFFECTCRAFT_CLI="$EFFECTCRAFT_CLI" \
  FILMCRAFT_CLI="$FILMCRAFT_CLI" \
  SOUNDCRAFT_CLI="$SOUNDCRAFT_CLI" \
  node - <<'EOF'
const fs = require('fs');
const path = require('path');
const os = require('os');

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
  const add = (key, cmd, args) => {
    if (!cmd) return;
    data.mcpServers[key] = { command: cmd, args, ...(includeType ? { type: 'stdio' } : {}) };
  };

  add('solidcraft', process.env.SOLIDCRAFT_CLI, ['mcp', '--compact']);
  add('cadcraft', process.env.CADCRAFT_CLI, ['mcp']);
  add('cadcraft-live', process.env.CADCRAFT_CLI, ['mcp', '--connect', '127.0.0.1:7979', '--lazy']);
  add('designcraft', process.env.DESIGNCRAFT_CLI, ['mcp']);
  add('vectorcraft', process.env.VECTORCRAFT_CLI, ['mcp']);
  add('photocraft', process.env.PHOTOCRAFT_CLI, ['mcp']);
  add('effectcraft', process.env.EFFECTCRAFT_CLI, ['mcp']);
  add('filmcraft', process.env.FILMCRAFT_CLI, ['mcp']);
  add('soundcraft', process.env.SOUNDCRAFT_CLI, ['mcp']);

  fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n', 'utf8');
  console.log('[OK] Updated MCP config:', filePath);
}
EOF
fi

# Install Master Control Board -> ~/.cad-agent-swarm/board/
INSTALL_HOME="$HOME/.cad-agent-swarm"
if [ -d "$REPO_ROOT/board" ] && [ "$REPO_ROOT" != "$INSTALL_HOME" ]; then
  mkdir -p "$INSTALL_HOME/board"
  cp -R "$REPO_ROOT"/board/* "$INSTALL_HOME/board/"
  echo "[OK] Installed Master Control Board -> $INSTALL_HOME/board"
fi

# Install 4 custom skills to Antigravity and Claude Code
for TARGET in "$HOME/.gemini/config/skills" "$HOME/.claude/skills"; do
  mkdir -p "$TARGET"
  for SKILL_DIR in "$REPO_ROOT"/skills/*/; do
    NAME="$(basename "$SKILL_DIR")"
    rm -rf "$TARGET/$NAME"
    cp -R "$SKILL_DIR" "$TARGET/$NAME"
  done
  echo "[OK] Installed custom ArtCraft/CAD skills -> $TARGET"
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
  echo "[OK] Synced 6 official SolidCraft skills (10 skills total per client)"
fi

# Install all 19 specialist sub-agents
mkdir -p "$HOME/.claude/agents"
cp "$REPO_ROOT"/agents/*.md "$HOME/.claude/agents/"
echo "[OK] Installed $(ls -1 "$REPO_ROOT"/agents/*.md | wc -l) specialist sub-agents -> $HOME/.claude/agents"

echo "Done! Open ~/.cad-agent-swarm/board/dashboard.html and reload MCP / start a new chat session."
