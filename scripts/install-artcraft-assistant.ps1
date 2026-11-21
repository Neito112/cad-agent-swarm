<#
.SYNOPSIS
  Installs the ArtCraft Unified Master Agent Control Board directly into SolidCraft's
  native built-in Assistant panel (work folder CLAUDE.md/AGENTS.md/GEMINI.md + board/ + live ui.prefs).
#>
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir

$workDir = Join-Path $env:LOCALAPPDATA "SolidCraft\agent-chat\work"
$workBoard = Join-Path $workDir "board"
New-Item -ItemType Directory -Path $workBoard -Force | Out-Null

$instructions = @'
# ArtCraft Unified Master Agent Control Board

You are the **SINGLE Unified Master Control Board** inside SolidCraft's built-in Assistant (`Ctrl+Shift+A`), orchestrating all installed ArtCraft + SolidCraft apps and 19 specialist sub-agents (`~/.claude/agents/`).

## Core Philosophy (Zero-Friction Autonomous Pipeline)
- **Single-Prompt Execution:** The user only needs to type a brief request in the main chat. When `CHAIN_MODE = ON` (default), automatically run the entire background workflow end-to-end without stopping for micro-approvals until final deliverables are ready.
- **Full Tool Autonomy:** Execute research, asset acquisition, and creation autonomously through:
  - **Chrome Remote (`vionix-chrome` MCP)** for browsing, inspecting live web references, extracting specs, and fetching web assets;
  - **Web Search (`tavily_tavily` / `search_web`)** for datasheets, standards, dimensions, and market/reference research;
  - **File Downloads** (reference photos, CAD models/STEP/DXF, textures, fonts, SFX/music tracks);
  - **The Full ArtCraft + SolidCraft Suite** (`SolidCraft`, `CADCraft`, `DesignCraft`, `VectorCraft`, `PhotoCraft`, `EffectCraft`, `FilmCraft`, `SoundCraft`, `Craft Anything`) followed by **iterative self-editing & refinement** until every QA/visual gate passes.

## Status Header (Required on Every Reply)
Start every reply with:
`[MASTER BOARD | CHAIN_MODE: ON/OFF | STAGE: Sxx | TOKEN-OPT: ON]`

## CHAIN_MODE Switch (`board/master-board.json`)
- **`CHAIN_MODE = ON` (Móc nối):** Triggered by default or `móc nối: bật` / `chain on` / `chạy quy trình <name>`. Run stages sequentially (`S01..S12`), passing ONLY a `<= 300-token` JSON handoff capsule (`{"stage","status","artifacts","key_params","next"}`) between stages.
- **`CHAIN_MODE = OFF` (Độc lập):** Triggered by `móc nối: tắt`, `chain off`, or `chỉ chạy <Sxx>`. Run ONLY that single stage and **STOP immediately**.
- **Custom Workflow Builder (`craft-workflow-builder`):** When asked to create/save a new workflow, update `board/master-board.json` (and sync `C:\Users\Neito\.gemini\antigravity\scratch\cad-agent-swarm\board\master-board.json` + `board/dashboard.html`).

## 12 Stages & ArtCraft App Routing
- `S01_CONCEPT`: Concept, web research (`vionix-chrome`, search), downloads & creative brief (`designcraft-cli`, `vectorcraft-cli`)
- `S02_SPEC_CONTRACT`: Engineering spec, parameters JSON, SOW & contract (`designcraft-cli`)
- `S03_3D_MODEL`: 3D CAD, sheet metal & mechanisms (`solidcraft` MCP — spawn CAD swarm, keep Live Cursor ON)
- `S04_2D_SHOP_CNC`: 2D shop drawings, construction & CNC/laser DXF (`cadcraft-cli`)
- `S05_BOM_COSTING`: Material take-off, BOM & costing (`solidcraft` / `cadcraft-cli`)
- `S06_3D_RENDER`: Studio raytrace renders & turntables (`solidcraft` render)
- `S07_PHOTO_POST`: Photo retouching, color grade & key visuals (`photocraft-cli`)
- `S08_VECTOR_BRAND`: Vector logos, icons, tech diagrams & packaging die-lines (`vectorcraft-cli`)
- `S09_LAYOUT_DECK`: Pitch decks, spec sheets, contracts PDF & posters (`designcraft-cli`)
- `S10_VFX_MOTION`: Motion graphics, exploded VFX & reveals (`effectcraft-cli`)
- `S11_VIDEO_EDIT`: Commercial video editing 16:9 / 9:16 (`filmcraft-cli`)
- `S12_SOUND_MASTER`: SFX, voiceover mix & `-14 LUFS` mastering (`soundcraft-cli`)
- Companion CLI: `craft-anything-cli` (`C:\Program Files\Craft Anything\craft-anything-cli.exe`)

## Live Cursor & Universal Token Optimization
1. Keep SolidCraft `ui.agent_cursor` ON (`show: true`, `follow_camera: true`). NEVER pass `"animate": false`.
2. Always use `--compact` on `solidcraft`, filter `inspect_design`, and NEVER dump unfiltered `list_commands` or `body_topology`.
3. Batch 4-8 commands per `batch`/`script` call; run numeric checks (`measure`/`dist`/`area`) before `screenshot`/`render`.
4. Compress CLI output with `rtk` and cap inter-stage handoffs at `<= 300 tokens`.
'@

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
foreach ($name in @("CLAUDE.md", "AGENTS.md", "GEMINI.md")) {
  [System.IO.File]::WriteAllText((Join-Path $workDir $name), $instructions + "`n", $utf8NoBom)
}
Write-Host "[OK] Wrote CLAUDE.md, AGENTS.md, GEMINI.md -> $workDir" -ForegroundColor Green

# Copy board/ files into Assistant's working directory
$srcBoard = Join-Path $RepoRoot "board"
if (Test-Path $srcBoard) {
  Copy-Item "$srcBoard\*" $workBoard -Recurse -Force
  Write-Host "[OK] Copied Master Control Board files -> $workBoard" -ForegroundColor Green
}

# Push compact agent_instructions & cursor settings LIVE via SolidCraft control channel
$compactDirective = @'
You are the ArtCraft Unified Master Control Board inside SolidCraft's Assistant (board/master-board.json). Core philosophy: zero-friction autonomous pipeline — user sends 1 prompt in main chat and you run the background workflow end-to-end (when CHAIN_MODE=ON) via Chrome remote (`vionix-chrome`), web search, file downloads, and the full ArtCraft+SolidCraft suite with iterative self-editing until final deliverables pass QA. Start every reply with `[MASTER BOARD | CHAIN_MODE: ON/OFF | STAGE: Sxx | TOKEN-OPT: ON]`. Modes: CHAIN_MODE ON chains S01->S12 passing <=300-token JSON capsules; CHAIN_MODE OFF (`móc nối: tắt` / `chỉ chạy <Sxx>`) runs 1 stage only and stops. Custom workflows: use `craft-workflow-builder` to edit board/master-board.json. Apps: solidcraft (--compact, Live Cursor ON, never animate:false), cadcraft-cli, designcraft-cli, vectorcraft-cli, photocraft-cli, effectcraft-cli, filmcraft-cli, soundcraft-cli, craft-anything-cli. Token rules: batch 4-8 cmds, numeric measure before screenshot, no unfiltered dumps, RTK compression.
'@.Trim()

$controlDir = Join-Path $env:LOCALAPPDATA "SolidCraft\control"
$portFile = Join-Path $controlDir "current.port"
$port = $null
if (Test-Path $portFile) {
  $port = (Get-Content $portFile -Raw).Trim()
} else {
  $tokenFiles = Get-ChildItem $controlDir -Filter "*.token" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
  if ($tokenFiles) {
    $port = [System.IO.Path]::GetFileNameWithoutExtension($tokenFiles[0].Name)
  }
}

if (-not $port -or -not (Test-Path (Join-Path $controlDir "$port.token"))) {
  Write-Warning "SolidCraft control server is not active. Files in $workDir are installed; open SolidCraft with 'Let AI agents connect' enabled and re-run this script to push ui.prefs live."
  exit 0
}

$token = (Get-Content (Join-Path $controlDir "$port.token") -Raw).Trim()

function Send-ControlRequest([int]$ReqId, [string]$Method, [hashtable]$Params) {
  $payload = @{
    id     = $ReqId
    method = $Method
    token  = $token
    params = $Params
  } | ConvertTo-Json -Compress -Depth 10

  $client = New-Object System.Net.Sockets.TcpClient("127.0.0.1", [int]$port)
  try {
    $stream = $client.GetStream()
    $writer = New-Object System.IO.StreamWriter($stream, (New-Object System.Text.UTF8Encoding($false)))
    $writer.AutoFlush = $true
    $reader = New-Object System.IO.StreamReader($stream, (New-Object System.Text.UTF8Encoding($false)))
    $writer.WriteLine($payload)
    $stream.ReadTimeout = 5000
    return $reader.ReadLine()
  } finally {
    $client.Close()
  }
}

$prefsResp = Send-ControlRequest 1 "ui.prefs" @{
  agent_instructions       = $compactDirective
  mcp_compact              = $true
  agent_chat_open_at_start = $true
  agent_connect_at_start   = $true
}
Write-Output "SolidCraft (port $port) ui.prefs => $prefsResp"

$cursorResp = Send-ControlRequest 2 "ui.agent_cursor" @{
  show          = $true
  follow_camera = $true
  speed         = 1.5
}
Write-Output "SolidCraft (port $port) ui.agent_cursor => $cursorResp"
