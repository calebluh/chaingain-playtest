# deploy_web.ps1
Write-Host "Building BalatroFB for the Web..." -ForegroundColor Cyan

# 1. Clean up old builds
if (Test-Path "balatrofb.love") { Remove-Item "balatrofb.love" -Force }
if (Test-Path "web_build") { Remove-Item "web_build" -Recurse -Force }

# 2. Package into a .love file
Write-Host "Zipping project into balatrofb.love..."
# We exclude node_modules, web_build, etc. just in case
Compress-Archive -Path "src", "assets", "main.lua", "conf.lua" -DestinationPath "balatrofb.zip" -Force
Rename-Item -Path "balatrofb.zip" -NewName "balatrofb.love"

# 3. Compile to WebAssembly using love.js
Write-Host "Compiling to WebAssembly via love.js (this may take a moment)..." -ForegroundColor Cyan
# Using npx to automatically fetch and run Davidobot's love.js
npx -y --package=love.js love.js.cmd balatrofb.love web_build -t "Chain Gain" -c

# 3.5 Inject game icon as browser tab favicon
if (Test-Path "assets/icon.png") {
    Copy-Item "assets/icon.png" "web_build/favicon.ico" -Force
}

Write-Host "Build complete! Output is in the 'web_build' folder." -ForegroundColor Green
Write-Host "Starting local web server on http://localhost:8000..." -ForegroundColor Cyan
Write-Host "Please open this URL in Chrome on your remote desktop for smooth rendering." -ForegroundColor Yellow
Write-Host "If you want to play from your local machine, run 'npx localtunnel --port 8000' in a separate terminal." -ForegroundColor Magenta
Write-Host "Press Ctrl+C to stop the server." -ForegroundColor Red

# 4. Start the local server
npx serve -l 8000 web_build
