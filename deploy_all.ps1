# deploy_all.ps1
# All-In-One Build and Deployment Script for Chain Gain
param(
    [string]$msg = "Automated deploy: desktop build, web gh-pages update, and main source sync"
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  CHAIN GAIN - ALL-IN-ONE MASTER DEPLOYMENT SCRIPT       " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Build Desktop Executable & Zip Package
Write-Host ">>> [STEP 1/3] Building Standalone Windows Desktop Package..." -ForegroundColor Yellow
if (Test-Path "deploy_desktop.ps1") {
    .\deploy_desktop.ps1
} else {
    Write-Host "Error: deploy_desktop.ps1 missing!" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 2: Build WebAssembly & Deploy to GitHub Pages (gh-pages)
Write-Host ">>> [STEP 2/3] Compiling WebAssembly & Deploying to gh-pages..." -ForegroundColor Yellow
if (Test-Path "deploy_web.ps1") {
    .\deploy_web.ps1 -NoServe
} else {
    Write-Host "Error: deploy_web.ps1 missing!" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 3: Stage, Commit, and Push Source Code to main Branch
Write-Host ">>> [STEP 3/3] Committing and Pushing Source Code to main..." -ForegroundColor Yellow
git add .
git commit -m $msg
git push origin main --force

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "  SUCCESS! ALL-IN-ONE DEPLOYMENT COMPLETE!                " -ForegroundColor Green
Write-Host "  - Desktop Executable: ChainGain_Windows.zip created" -ForegroundColor Green
Write-Host "  - Web Build: Force-pushed directly to 'gh-pages' branch" -ForegroundColor Green
Write-Host "  - Source Code: Force-pushed to 'main' branch" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
