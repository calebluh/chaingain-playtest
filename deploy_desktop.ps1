# deploy_desktop.ps1
Write-Host "Building Chain Gain Standalone EXE for Windows..." -ForegroundColor Cyan

# 1. Terminate any running game processes to release file locks
Stop-Process -Name "ChainGain" -ErrorAction SilentlyContinue
Stop-Process -Name "love" -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

# 2. Clean old builds
if (Test-Path "balatrofb.love") { Remove-Item "balatrofb.love" -Force }
if (Test-Path "desktop_build") { Remove-Item "desktop_build" -Recurse -Force }
if (Test-Path "ChainGain_Windows.zip") { Remove-Item "ChainGain_Windows.zip" -Force }

# 3. Package resources into a .love archive
Write-Host "Packaging resources into balatrofb.love..." -ForegroundColor Yellow
Compress-Archive -Path "src", "assets", "main.lua", "conf.lua" -DestinationPath "balatrofb.zip" -Force
Rename-Item -Path "balatrofb.zip" -NewName "balatrofb.love"

# 4. Download Love2D redistribution files if not cached locally
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

# 5. Create standalone build directory
New-Item -ItemType Directory -Path "desktop_build" -Force | Out-Null

# 6. Copy DLLs and license text
Copy-Item "love_dist/extracted/love-11.5-win64/*.dll" "desktop_build/"
Copy-Item "love_dist/extracted/love-11.5-win64/license.txt" "desktop_build/"

# 7. Fuse love.exe + balatrofb.love -> ChainGain.exe
Write-Host "Fusing binaries into ChainGain.exe..." -ForegroundColor Yellow
cmd /c "copy /b love_dist\extracted\love-11.5-win64\love.exe+balatrofb.love desktop_build\ChainGain.exe" | Out-Null

# 8. Zip the folder for distribution
Write-Host "Compressing standalone folder into ChainGain_Windows.zip..." -ForegroundColor Yellow
Compress-Archive -Path "desktop_build" -DestinationPath "ChainGain_Windows.zip" -Force

Write-Host "Build complete! Standalone package created at ChainGain_Windows.zip" -ForegroundColor Green
Write-Host "Your friends can extract ChainGain_Windows.zip and run ChainGain.exe to play!" -ForegroundColor Yellow
Write-Host ""
Write-Host "NOTE: If Windows Defender / Smart App Control blocks ChainGain.exe, tell your friends to:" -ForegroundColor Cyan
Write-Host "  1. Right-click 'ChainGain.exe' -> Select 'Properties'." -ForegroundColor Cyan
Write-Host "  2. Check the 'Unblock' box at the bottom -> Click Apply/OK." -ForegroundColor Cyan
Write-Host "  3. Alternatively, install LÖVE 11.5 (love2d.org) and double-click the 'balatrofb.love' file directly to bypass Windows SmartScreen warnings completely." -ForegroundColor Cyan
