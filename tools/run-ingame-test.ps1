# Launches the game, lets the CET test mod (tools/cet/flatline_test) auto-load
# the last save and run, and screenshots every "SHOT:<name>" marker it logs.
param([int]$TimeoutSec = 480)

$game = "C:\Program Files (x86)\Steam\steamapps\common\Cyberpunk 2077"
$log = "$game\bin\x64\plugins\cyber_engine_tweaks\mods\flatline_test\flatline_test.log"
$ctl = Join-Path $PSScriptRoot "gamectl.ps1"

if (-not (Get-Process Cyberpunk2077 -ErrorAction SilentlyContinue)) {
  Remove-Item $log -ErrorAction SilentlyContinue
  Start-Process "$game\bin\x64\Cyberpunk2077.exe" -ArgumentList "--launcher-skip", "-skipStartScreen" -WorkingDirectory "$game\bin\x64"
}

$seen = 0
$deadline = (Get-Date).AddSeconds($TimeoutSec)
while ((Get-Date) -lt $deadline) {
  Start-Sleep -Milliseconds 500
  if (-not (Get-Process Cyberpunk2077 -ErrorAction SilentlyContinue)) { "GAME EXITED"; break }
  if (-not (Test-Path $log)) { continue }
  $lines = @(Get-Content $log)
  for ($i = $seen; $i -lt $lines.Count; $i++) {
    $l = $lines[$i]
    $l
    if ($l -like "SHOT:*") { Start-Sleep -Milliseconds 1200; & $ctl -Shot $l.Substring(5) | Out-Null }
  }
  $seen = $lines.Count
  if ($lines -contains "== done") {
    Start-Sleep 3
    & $ctl -Key 0x49 -Wait 3 -Shot "14_inventory" | Out-Null   # I: open inventory
    "inventory captured"
    break
  }
}
