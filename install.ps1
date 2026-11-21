<#
.SYNOPSIS
  Automated installer for cad-agent-swarm (Windows).
  Installs SolidCraft & CADCraft MCP servers (--compact), Live Agent Cursor script,
  9 CAD skills (3 swarm/token/playbook + 6 official SolidCraft skills), and 10 Claude Code sub-agents.
#>
param(
  [switch]$SkipOfficialSolidCraftSkills,
  [switch]$SkipLiveCursorCheck
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "=== CAD Agent Swarm Installer (Windows) ===" -ForegroundColor Cyan

# 1. Detect SolidCraft & CADCraft CLI binaries
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

Write-Host "SolidCraft CLI: $(if ($solidcraftCli) { $solidcraftCli } else { 'NOT FOUND (skipped MCP)' })"
Write-Host "CADCraft CLI:   $(if ($cadcraftCli) { $cadcraftCli } else { 'NOT FOUND (skipped MCP)' })"

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
  if ($solidcraftCli) {
    $entry = @{ command = $solidcraftCli; args = @("mcp", "--compact") }
    if ($IncludeType) { $entry["type"] = "stdio" }
    $obj["mcpServers"]["solidcraft"] = $entry
  }
  if ($cadcraftCli) {
    $entry1 = @{ command = $cadcraftCli; args = @("mcp") }
    $entry2 = @{ command = $cadcraftCli; args = @("mcp", "--connect", "127.0.0.1:7979", "--lazy") }
    if ($IncludeType) { $entry1["type"] = "stdio"; $entry2["type"] = "stdio" }
    $obj["mcpServers"]["cadcraft"] = $entry1
    $obj["mcpServers"]["cadcraft-live"] = $entry2
  }
  $json = ($obj | ConvertTo-Json -Depth 20) + "`n"
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $json, $utf8NoBom)
  Write-Host "[OK] Updated MCP config: $Path" -ForegroundColor Green
}

Update-McpJson "$env:USERPROFILE\.gemini\config\mcp_config.json" $false
Update-McpJson "$env:USERPROFILE\.claude.json" $true
Update-McpJson "$env:USERPROFILE\.gemini\settings.json" $false

# 3. Install custom skills to Antigravity and Claude Code
$skillTargets = @(
  "$env:USERPROFILE\.gemini\config\skills",
  "$env:USERPROFILE\.claude\skills"
)
foreach ($target in $skillTargets) {
  New-Item -ItemType Directory -Path $target -Force | Out-Null
  foreach ($skillDir in (Get-ChildItem "$RepoRoot\skills" -Directory)) {
    $dest = Join-Path $target $skillDir.Name
    if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
    Copy-Item -Recurse $skillDir.FullName $dest
  }
  Write-Host "[OK] Installed 3 swarm/token/playbook skills -> $target" -ForegroundColor Green
}

# 4. Sync 6 official SolidCraft skills from tangency-labs/solidcraft
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
    Write-Host "[OK] Synced 6 official SolidCraft skills to Antigravity & Claude Code" -ForegroundColor Green
  } else {
    Write-Warning "git not found — skipped syncing official SolidCraft skills."
  }
}

# 5. Install 10 Claude Code specialist sub-agents
$agentsTarget = "$env:USERPROFILE\.claude\agents"
New-Item -ItemType Directory -Path $agentsTarget -Force | Out-Null
Copy-Item "$RepoRoot\agents\*.md" $agentsTarget -Force
Write-Host "[OK] Installed 10 CAD specialist sub-agents -> $agentsTarget" -ForegroundColor Green

# 6. Optional: Auto-install RTK (Rust Token Killer) for 60-90% CLI token savings
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

# 7. Enable Live Agent Cursor if SolidCraft is currently running
if (-not $SkipLiveCursorCheck) {
  $cursorScript = Join-Path $RepoRoot "scripts\enable-solidcraft-cursor.ps1"
  if (Test-Path $cursorScript) {
    try {
      & $cursorScript -Speed 1.5
    } catch {
      Write-Host "[INFO] SolidCraft desktop app is not listening right now. Enable 'Preferences > Assistant > Agents through MCP > Let AI agents connect' and re-run scripts\enable-solidcraft-cursor.ps1." -ForegroundColor Yellow
    }
  }
}

Write-Host "`nDone! Reload MCP servers / start a new chat session to activate all tools, skills, and sub-agents." -ForegroundColor Cyan
