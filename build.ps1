# Packs src/ into dist/FlatlineBroker-<version>.zip, laid out like the game folder.
# Entries are written by hand: Windows PowerShell's Compress-Archive stores
# backslash paths, which some mod managers and unzip tools mishandle.
param([string]$Version = (Get-Content (Join-Path $PSScriptRoot "VERSION")).Trim())

Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem

$src = Join-Path $PSScriptRoot "src"
$dist = Join-Path $PSScriptRoot "dist"
$zip = Join-Path $dist "FlatlineBroker-$Version.zip"

New-Item -ItemType Directory -Force $dist | Out-Null
Remove-Item $zip -ErrorAction SilentlyContinue

$archive = [System.IO.Compression.ZipFile]::Open($zip, [System.IO.Compression.ZipArchiveMode]::Create)
try {
  Get-ChildItem $src -Recurse -File | ForEach-Object {
    $entry = $_.FullName.Substring($src.Length + 1).Replace('\', '/')
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $_.FullName, $entry) | Out-Null
  }
} finally {
  $archive.Dispose()
}
$zip
