param(
  [bool]$Show = $true,
  [bool]$FollowCamera = $true,
  [double]$Speed = 1.5
)

$controlDir = Join-Path $env:LOCALAPPDATA "SolidCraft\control"
$portFile = Join-Path $controlDir "current.port"

if (Test-Path $portFile) {
  $port = (Get-Content $portFile -Raw).Trim()
} else {
  $tokenFiles = Get-ChildItem $controlDir -Filter "*.token" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
  if (-not $tokenFiles) {
    Write-Error "No running SolidCraft control channel found in $controlDir. Enable Preferences > Assistant > Agents through MCP > Let AI agents connect."
    exit 1
  }
  $port = [System.IO.Path]::GetFileNameWithoutExtension($tokenFiles[0].Name)
}

$tokenFile = Join-Path $controlDir "$port.token"
if (-not (Test-Path $tokenFile)) {
  Write-Error "Control token file not found: $tokenFile"
  exit 1
}
$token = (Get-Content $tokenFile -Raw).Trim()

$payload = @{
  id     = 1
  method = "ui.agent_cursor"
  token  = $token
  params = @{
    show          = $Show
    follow_camera = $FollowCamera
    speed         = $Speed
  }
} | ConvertTo-Json -Compress

$client = New-Object System.Net.Sockets.TcpClient("127.0.0.1", [int]$port)
try {
  $stream = $client.GetStream()
  $writer = New-Object System.IO.StreamWriter($stream)
  $writer.AutoFlush = $true
  $reader = New-Object System.IO.StreamReader($stream)
  $writer.WriteLine($payload)
  $stream.ReadTimeout = 5000
  $response = $reader.ReadLine()
  Write-Output "SolidCraft (port $port) ui.agent_cursor => $response"
} finally {
  $client.Close()
}
