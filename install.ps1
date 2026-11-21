<#
.SYNOPSIS
  Automated installer for cad-agent-swarm (Windows) — ArtCraft Unified Studio Edition.
  Installs all 9 ArtCraft + SolidCraft MCP servers (with --compact for SolidCraft),
  Unified Master Control Board (board/), Live Agent Cursor script,
  10 skills (4 custom + 6 official SolidCraft), 19 specialist sub-agents, and RTK.
#>
param(
  [switch]$SkipOfficialSolidCraftSkills,
  [switch]$SkipLiveCursorCheck
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "=== ArtCraft Unified Studio & CAD Swarm Installer (Windows) ===" -ForegroundColor Cyan

# 1. Detect all 8 ArtCraft + SolidCraft CLI binaries
function Find-Binary([string]$Name, [string[]]$Candidates) {
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  foreach ($c in $Candidates) {
    if (Test-Path $c) { return $c }
  }
  return $null
}

$solidcraftCli = Find-Binary "solidcraft-cli" @(
  "C:\Program Files\SolidCraft\solidcraft-cli.exe",
  "$env:LOCALAPPDATA\Programs\SolidCraft\solidcraft-cli.exe",
  "$env:USERPROFILE\.cargo\bin\solidcraft-cli.exe"
)
$cadcraftCli = Find-Binary "cadcraft-cli" @(
  "C:\Program Files\ArtCraft\CADCraft\cadcraft-cli.exe",
  "C:\Program Files\CADCraft\cadcraft-cli.exe",
  "$env:LOCALAPPDATA\Programs\CADCraft\cadcraft-cli.exe",
  "$env:USERPROFILE\.cargo\bin\cadcraft-cli.exe"
)
$designcraftCli = Find-Binary "designcraft-cli" @(
  "C:\Program Files\ArtCraft\DesignCraft\designcraft-cli.exe",
  "$env:LOCALAPPDATA\Programs\DesignCraft\designcraft-cli.exe"
)
$vectorcraftCli = Find-Binary "vectorcraft-cli" @(
  "C:\Program Files\ArtCraft\VectorCraft\vectorcraft-cli.exe",
  "$env:LOCALAPPDATA\Programs\VectorCraft\vectorcraft-cli.exe"
)
$photocraftCli = Find-Binary "photocraft-cli" @(
  "C:\Program Files\ArtCraft\PhotoCraft\photocraft-cli.exe",
  "$env:LOCALAPPDATA\Programs\PhotoCraft\photocraft-cli.exe"
)
$effectcraftCli = Find-Binary "effectcraft-cli" @(
  "C:\Program Files\ArtCraft\EffectCraft\effectcraft-cli.exe",
  "$env:LOCALAPPDATA\Programs\EffectCraft\effectcraft-cli.exe"
)
$filmcraftCli = Find-Binary "filmcraft-cli" @(
  "C:\Program Files\ArtCraft\FilmCraft\filmcraft-cli.exe",
  "$env:LOCALAPPDATA\Programs\FilmCraft\filmcraft-cli.exe"
)
$soundcraftCli = Find-Binary "soundcraft-cli" @(
  "C:\Program Files\ArtCraft\SoundCraft\soundcraft-cli.exe",
  "$env:LOCALAPPDATA\Programs\SoundCraft\soundcraft-cli.exe"
)
$craftAnythingCli = Find-Binary "craft-anything-cli" @(
  "C:\Program Files\Craft Anything\craft-anything-cli.exe",
  "$env:LOCALAPPDATA\Programs\Craft Anything\craft-anything-cli.exe"
)

$detected = [ordered]@{
  solidcraft      = $solidcraftCli
  cadcraft        = $cadcraftCli
  designcraft     = $designcraftCli
  vectorcraft     = $vectorcraftCli
  photocraft      = $photocraftCli
  effectcraft     = $effectcraftCli
  filmcraft       = $filmcraftCli
  soundcraft      = $soundcraftCli
  "craft-anything" = $craftAnythingCli
}
foreach ($kv in $detected.GetEnumerator()) {
  Write-Host ("{0,-12}: {1}" -f $kv.Key, $(if ($kv.Value) { $kv.Value } else { "NOT FOUND (skipped MCP)" }))
}

# 2. Update MCP configs (Antigravity, Claude Code, Gemini CLI) safely without BOM issues
function Update-McpJson([string]$Path, [bool]$IncludeType) {
  $parent = Split-Path -Parent $Path
  if (-not (Test-Path $parent)) { return }
  $obj = @{}
  if (Test-Path $Path) {
    $raw = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8).TrimStart([char]0xFEFF)
    if ($raw.Trim().Length -gt 0) {
      $obj = $raw | ConvertFrom-Json -AsHashtable
    }
  }
  if (-not $obj.ContainsKey("mcpServers") -or $null -eq $obj["mcpServers"]) {
    $obj["mcpServers"] = @{}
  }

  function Set-Server([string]$Key, [string]$Cmd, [string[]]$ServerArgs) {
    $entry = @{ command = $Cmd; args = $ServerArgs }
    if ($IncludeType) { $entry["type"] = "stdio" }
    $obj["mcpServers"][$Key] = $entry
  }

  if ($solidcraftCli)  { Set-Server "solidcraft"    $solidcraftCli  @("mcp", "--compact") }
  if ($cadcraftCli) {
    Set-Server "cadcraft"      $cadcraftCli @("mcp")
    Set-Server "cadcraft-live" $cadcraftCli @("mcp", "--connect", "127.0.0.1:7979", "--lazy")
  }
  if ($designcraftCli) { Set-Server "designcraft"   $designcraftCli @("mcp") }
  if ($vectorcraftCli) { Set-Server "vectorcraft"   $vectorcraftCli @("mcp") }
  if ($photocraftCli)  { Set-Server "photocraft"    $photocraftCli  @("mcp") }
  if ($effectcraftCli) { Set-Server "effectcraft"   $effectcraftCli @("mcp") }
  if ($filmcraftCli)     { Set-Server "filmcraft"      $filmcraftCli     @("mcp") }
  if ($soundcraftCli)    { Set-Server "soundcraft"     $soundcraftCli    @("mcp") }
  if ($craftAnythingCli) { Set-Server "craft-anything" $craftAnythingCli @("mcp") }

  $json = ($obj | ConvertTo-Json -Depth 20) + "`n"
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $json, $utf8NoBom)
  Write-Host "[OK] Updated MCP config (up to 10 ArtCraft/SolidCraft servers): $Path" -ForegroundColor Green
}

Update-McpJson "$env:USERPROFILE\.gemini\config\mcp_config.json" $false
Update-McpJson "$env:USERPROFILE\.claude.json" $true
Update-McpJson "$env:USERPROFILE\.gemini\settings.json" $false

# 3. Install Unified Master Control Board -> ~/.cad-agent-swarm/board/
$installHome = Join-Path $env:USERPROFILE ".cad-agent-swarm"
$boardSrc = Join-Path $RepoRoot "board"
$boardDst = Join-Path $installHome "board"
if ((Test-Path $boardSrc) -and ([System.IO.Path]::GetFullPath($RepoRoot).TrimEnd('\') -ne [System.IO.Path]::GetFullPath($installHome).TrimEnd('\'))) {
  New-Item -ItemType Directory -Path $boardDst -Force | Out-Null
  Copy-Item "$boardSrc\*" $boardDst -Recurse -Force
  Write-Host "[OK] Installed Master Control Board -> $boardDst" -ForegroundColor Green
} elseif (Test-Path $boardDst) {
  Write-Host "[OK] Master Control Board ready -> $boardDst" -ForegroundColor Green
}

# 4. Install custom skills (4 total: cad-visual-cursor-swarm, cad-token-optimizer, cad-drafting-3d-playbook, craft-master-board)
$skillTargets = @(
  "$env:USERPROFILE\.gemini\config\skills",
  "$env:USERPROFILE\.claude\skills"
)
$customSkills = Get-ChildItem "$RepoRoot\skills" -Directory
foreach ($target in $skillTargets) {
  New-Item -ItemType Directory -Path $target -Force | Out-Null
  foreach ($skillDir in $customSkills) {
    $dest = Join-Path $target $skillDir.Name
    if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
    Copy-Item -Recurse $skillDir.FullName $dest
  }
  Write-Host "[OK] Installed $($customSkills.Count) custom ArtCraft/CAD skills -> $target" -ForegroundColor Green
}

# 5. Sync 6 official SolidCraft skills from tangency-labs/solidcraft
if (-not $SkipOfficialSolidCraftSkills) {
  $git = Get-Command git -ErrorAction SilentlyContinue
  if ($git) {
    $tmp = Join-Path $env:TEMP "solidcraft-official-skills"
    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
    git clone --depth 1 --filter=blob:none --sparse https://github.com/tangency-labs/solidcraft.git $tmp | Out-Null
    Push-Location $tmp
    git sparse-checkout set skills | Out-Null
    Pop-Location
    $official = @('solidcraft-modeling','solidcraft-editing','solidcraft-checking','solidcraft-mechanisms','solidcraft-sheetmetal','solidcraft-reporting')
    foreach ($target in $skillTargets) {
      foreach ($s in $official) {
        $src = Join-Path "$tmp\skills" $s
        if (Test-Path $src) {
          $dest = Join-Path $target $s
          if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
          Copy-Item -Recurse $src $dest
        }
      }
    }
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "[OK] Synced 6 official SolidCraft skills (10 skills total per client)" -ForegroundColor Green
  } else {
    Write-Warning "git not found — skipped syncing official SolidCraft skills."
  }
}

# 6. Install all 19 specialist sub-agents (10 CAD + 9 ArtCraft Studio/Board)
$agentsTarget = "$env:USERPROFILE\.claude\agents"
New-Item -ItemType Directory -Path $agentsTarget -Force | Out-Null
$agentFiles = Get-ChildItem "$RepoRoot\agents" -Filter "*.md"
Copy-Item "$RepoRoot\agents\*.md" $agentsTarget -Force
Write-Host "[OK] Installed $($agentFiles.Count) specialist sub-agents -> $agentsTarget" -ForegroundColor Green

# 7. Auto-install RTK (Rust Token Killer) for 60-90% CLI token savings
if (-not (Get-Command rtk -ErrorAction SilentlyContinue)) {
  try {
    $rtkUrl = "https://github.com/rtk-ai/rtk/releases/download/v1.2.1/rtk-x86_64-pc-windows-msvc.zip"
    $rtkDest = "$env:LOCALAPPDATA\Programs\rtk"
    $rtkZip = "$env:TEMP\rtk-win.zip"
    curl.exe -sSL --fail -o $rtkZip $rtkUrl
    New-Item -ItemType Directory -Path $rtkDest -Force | Out-Null
    Expand-Archive -Path $rtkZip -DestinationPath $rtkDest -Force
    Remove-Item $rtkZip -Force
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $parts = $userPath -split ";" | Where-Object { $_ -ne "" }
    if ($parts -notcontains $rtkDest) {
      [Environment]::SetEnvironmentVariable("Path", (($parts + $rtkDest) -join ";"), "User")
    }
    $rtkBin = Get-ChildItem $rtkDest -Recurse -Filter "rtk.exe" | Select-Object -First 1
    if ($rtkBin) {
      & $rtkBin.FullName init -g --auto-patch | Out-Null
      Write-Host "[OK] Installed RTK (Rust Token Killer) + Claude Code hooks -> $($rtkBin.FullName)" -ForegroundColor Green
    }
  } catch {
    Write-Warning "RTK auto-install skipped: $($_.Exception.Message)"
  }
} else {
  Write-Host "[OK] RTK already installed" -ForegroundColor Green
}

# 8. Embed Master Board into SolidCraft/ArtCraft native Assistant & enable Live Agent Cursor
$assistantScript = Join-Path $RepoRoot "scripts\install-artcraft-assistant.ps1"
if (Test-Path $assistantScript) {
  if ($SkipLiveCursorCheck) {
    Write-Host "[INFO] Skipped live SolidCraft control push (-SkipLiveCursorCheck)." -ForegroundColor Yellow
  } else {
    try {
      & $assistantScript
    } catch {
      Write-Warning "SolidCraft Assistant live install warning: $($_.Exception.Message)"
    }
  }
}

Write-Host "`nDone! Open SolidCraft Assistant (Ctrl+Shift+A) or board\dashboard.html, and reload MCP / start a new chat to activate all 10+ servers, 10 skills, and 19 sub-agents." -ForegroundColor Cyan
