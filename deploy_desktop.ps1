# deploy_desktop.ps1
Write-Host "Building Drive or Die Standalone EXE for Windows..." -ForegroundColor Cyan

# 1. Clean old builds
if (Test-Path "balatrofb.love") { Remove-Item "balatrofb.love" -Force }
if (Test-Path "desktop_build") { Remove-Item "desktop_build" -Recurse -Force }
if (Test-Path "DriveOrDie_Windows.zip") { Remove-Item "DriveOrDie_Windows.zip" -Force }

# 2. Package resources into a .love archive
Write-Host "Packaging resources into balatrofb.love..." -ForegroundColor Yellow
Compress-Archive -Path "src", "assets", "main.lua", "conf.lua" -DestinationPath "balatrofb.zip" -Force
Rename-Item -Path "balatrofb.zip" -NewName "balatrofb.love"

# 3. Download Love2D redistribution files if not cached locally
$loveZip = "love-11.5-win64.zip"
$loveUrl = "https://github.com/love2d/love/releases/download/11.5/love-11.5-win64.zip"

if (!(Test-Path "love_dist")) {
    New-Item -ItemType Directory -Path "love_dist" -Force | Out-Null
}

if (!(Test-Path "love_dist/extracted")) {
    Write-Host "Downloading Love2D binary distribution package..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $loveUrl -OutFile "love_dist/$loveZip"
    
    Write-Host "Extracting binaries..." -ForegroundColor Yellow
    Expand-Archive -Path "love_dist/$loveZip" -DestinationPath "love_dist/extracted" -Force
}

# 4. Create standalone build directory
New-Item -ItemType Directory -Path "desktop_build" -Force | Out-Null

# 5. Copy DLLs and license text
Copy-Item "love_dist/extracted/love-11.5-win64/*.dll" "desktop_build/"
Copy-Item "love_dist/extracted/love-11.5-win64/license.txt" "desktop_build/"

# 6. Fuse love.exe + balatrofb.love -> DriveOrDie.exe
Write-Host "Fusing binaries into DriveOrDie.exe..." -ForegroundColor Yellow
cmd /c "copy /b love_dist\extracted\love-11.5-win64\love.exe+balatrofb.love desktop_build\DriveOrDie.exe" | Out-Null

# 7. Zip the folder for distribution
Write-Host "Compressing standalone folder into DriveOrDie_Windows.zip..." -ForegroundColor Yellow
Compress-Archive -Path "desktop_build" -DestinationPath "DriveOrDie_Windows.zip" -Force

Write-Host "Build complete! Standalone package created at DriveOrDie_Windows.zip" -ForegroundColor Green
Write-Host "Your friends can extract DriveOrDie_Windows.zip and run DriveOrDie.exe to play!" -ForegroundColor Yellow
