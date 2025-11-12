# Fix flutter_bluetooth_serial plugin namespace issue on Windows
# Run this script if you encounter namespace errors when building on Windows

$pluginPath = "$env:USERPROFILE\.pub-cache\hosted\pub.dev\flutter_bluetooth_serial-0.4.0\android\build.gradle"

if (-Not (Test-Path $pluginPath)) {
    Write-Host "Error: Plugin build.gradle not found at: $pluginPath" -ForegroundColor Red
    exit 1
}

Write-Host "Backing up original build.gradle..." -ForegroundColor Yellow
Copy-Item $pluginPath "$pluginPath.backup"

# Check if namespace already exists
$content = Get-Content $pluginPath -Raw
if ($content -match "namespace") {
    Write-Host "Namespace already exists in build.gradle" -ForegroundColor Green
    exit 0
}

Write-Host "Adding namespace to build.gradle..." -ForegroundColor Yellow

# Read the file line by line
$lines = Get-Content $pluginPath
$newLines = @()
$namespaceAdded = $false

foreach ($line in $lines) {
    $newLines += $line
    if ($line -match "^android \{" -and -not $namespaceAdded) {
        $newLines += '    namespace = "io.github.edufolly.flutterbluetoothserial"'
        $namespaceAdded = $true
    }
}

# Write back to file
$newLines | Set-Content $pluginPath

Write-Host "Done! Namespace added successfully." -ForegroundColor Green
Write-Host "Backup saved at: $pluginPath.backup" -ForegroundColor Cyan
