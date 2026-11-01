# Test helper: relative mouse motion for the game's menu cursor, which ignores
# absolute cursor positioning. Usage: gamemouse.ps1 -Dx 250 -Dy 60 [-Click]
param([int]$Dx = 0, [int]$Dy = 0, [switch]$Click)
Add-Type @"
using System; using System.Runtime.InteropServices;
public static class GM { [DllImport("user32.dll")] public static extern void mouse_event(uint f, int x, int y, uint d, UIntPtr e); }
"@
$steps = 10
for ($i = 0; $i -lt $steps; $i++) {
  [GM]::mouse_event(0x1, [int]($Dx / $steps), [int]($Dy / $steps), 0, [UIntPtr]::Zero)
  Start-Sleep -Milliseconds 15
}
if ($Click) {
  Start-Sleep -Milliseconds 150
  [GM]::mouse_event(0x2, 0, 0, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 80
  [GM]::mouse_event(0x4, 0, 0, 0, [UIntPtr]::Zero)
}
