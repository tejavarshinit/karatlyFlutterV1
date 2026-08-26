# ============================================================
#  Karatly - AAB post-processor: strip native debug symbols + re-sign
#  Usage:  powershell -ExecutionPolicy Bypass -File strip_aab.ps1
#  Input : build\app\outputs\bundle\release\app-release.aab  (2-ABI build)
#  Output: build\app\outputs\bundle\release\app-release-lite.aab (~21MB)
# ============================================================
$ErrorActionPreference = 'Stop'

$src  = Join-Path $PSScriptRoot "build\app\outputs\bundle\release\app-release.aab"
$dest = Join-Path $PSScriptRoot "build\app\outputs\bundle\release\app-release-lite.aab"
$jks  = "C:\Users\tejas\keystore\karatly-release.jks"
$storePass = "karatly181818"
$keyPass   = "karatly181818"
$alias     = "karatly"
$jarsigner = "C:\Program Files\Eclipse Adoptium\jdk-21.0.11.10-hotspot\bin\jarsigner.exe"

if (-not (Test-Path $src))  { Write-Host "ERROR: source AAB not found: $src"  -ForegroundColor Red; exit 1 }
if (-not (Test-Path $jks))  { Write-Host "ERROR: keystore not found: $jks"    -ForegroundColor Red; exit 1 }

$tmp = Join-Path $env:TEMP ("aab-lite-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmp | Out-Null

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$stripped = 0
$zip = [System.IO.Compression.ZipFile]::OpenRead($src)
$out = [System.IO.Compression.ZipFile]::Open($dest, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($e in $zip.Entries) {
        if ($e.FullName -like 'BUNDLE-METADATA/com.android.tools.build.debugsymbols/*') {
            $stripped++
            continue   # drop native debug symbols (diagnostic only)
        }
        # Drop old JAR signature files — jarsigner will regenerate them cleanly.
        if ($e.FullName -like 'META-INF/*.SF' -or
            $e.FullName -like 'META-INF/*.RSA' -or
            $e.FullName -like 'META-INF/*.DSA' -or
            $e.FullName -eq 'META-INF/MANIFEST.MF' -or
            $e.FullName -like 'META-INF/SIG-*') {
            continue
        }
        $newEntry = $out.CreateEntry($e.FullName, [System.IO.Compression.CompressionLevel]::Optimal)
        $inStream  = $e.Open()
        $outStream = $newEntry.Open()
        try { $inStream.CopyTo($outStream) } finally { $inStream.Dispose(); $outStream.Dispose() }
    }
} finally {
    $out.Dispose(); $zip.Dispose()
}
Write-Host "Stripped $stripped debug-symbol entries."

# Re-sign the modified AAB (JAR signing, like the original)
& $jarsigner -keystore $jks -storepass $storePass -keypass $keyPass -digestalg SHA-256 -sigalg SHA256withRSA $dest $alias 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host "ERROR: jarsigner failed" -ForegroundColor Red; exit 1 }

$sizeMB = [math]::Round((Get-Item $dest).Length / 1MB, 1)
Write-Host "DONE -> $dest  ($sizeMB MB)" -ForegroundColor Green
