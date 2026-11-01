# Test helper: focus the game window, send input, capture the screen.
# Usage: gamectl.ps1 -Shot name | -Key VK [-Hold ms] | -Click x,y | -Focus
param([string]$Shot, [int[]]$Key, [int]$Hold = 80, [int[]]$Click, [switch]$Focus, [int]$Wait = 0)

Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type @"
using System; using System.Runtime.InteropServices;
public static class W {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
  [DllImport("user32.dll")] public static extern uint MapVirtualKey(uint code, uint type);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(uint f, int x, int y, uint d, UIntPtr e);
}
"@

$p = Get-Process Cyberpunk2077 -ErrorAction SilentlyContinue | Select-Object -First 1
if ($Focus -or $Key -or $Click) {
  if (-not $p) { throw "game not running" }
  # Windows only lets the foreground process hand off focus; an Alt tap lifts the lock.
  [W]::keybd_event(0x12, 0, 0, [UIntPtr]::Zero); [W]::keybd_event(0x12, 0, 2, [UIntPtr]::Zero)
  [W]::ShowWindow($p.MainWindowHandle, 9) | Out-Null
  [W]::SetForegroundWindow($p.MainWindowHandle) | Out-Null
  Start-Sleep -Milliseconds 400
}
foreach ($vk in $Key) {
  $scan = [byte][W]::MapVirtualKey($vk, 0)
  [W]::keybd_event([byte]$vk, $scan, 0x8, [UIntPtr]::Zero)          # scancode down
  Start-Sleep -Milliseconds $Hold
  [W]::keybd_event([byte]$vk, $scan, 0xA, [UIntPtr]::Zero)          # scancode up
  Start-Sleep -Milliseconds 250
}
if ($Click) {
  [W]::SetCursorPos($Click[0], $Click[1]) | Out-Null
  Start-Sleep -Milliseconds 200
  [W]::mouse_event(0x2, 0, 0, 0, [UIntPtr]::Zero); Start-Sleep -Milliseconds 80
  [W]::mouse_event(0x4, 0, 0, 0, [UIntPtr]::Zero)
}
if ($Wait) { Start-Sleep -Seconds $Wait }
if ($Shot) {
  $dir = Join-Path $PSScriptRoot "..\screenshots"
  New-Item -ItemType Directory -Force $dir | Out-Null
  $b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
  $bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
  [System.Drawing.Graphics]::FromImage($bmp).CopyFromScreen($b.Location, [System.Drawing.Point]::Empty, $b.Size)
  $out = Join-Path (Resolve-Path $dir) "$Shot.png"
  $bmp.Save($out); $out
}
