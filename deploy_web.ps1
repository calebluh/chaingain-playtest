param(
    [switch]$NoServe
)

# deploy_web.ps1
Write-Host "Building Chain Gain for the Web..." -ForegroundColor Cyan

# 1. Clean up old builds
if (Test-Path "balatrofb.love") { Remove-Item "balatrofb.love" -Force }
if (Test-Path "web_build") { Remove-Item "web_build" -Recurse -Force }

# 2. Package into a .love file with guaranteed POSIX forward-slash entries
Write-Host "Zipping project into balatrofb.love with explicit POSIX forward-slash paths..."
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

if (Test-Path "balatrofb.love") { Remove-Item "balatrofb.love" -Force }
if (Test-Path "balatrofb.zip") { Remove-Item "balatrofb.zip" -Force }

$zip = [System.IO.Compression.ZipFile]::Open((Join-Path (Get-Location).Path "balatrofb.zip"), [System.IO.Compression.ZipArchiveMode]::Create)
$basePath = (Get-Location).Path
$targets = @("src", "assets", "main.lua", "conf.lua")

foreach ($target in $targets) {
    if (Test-Path $target -PathType Container) {
        $files = Get-ChildItem -Path $target -Recurse -File
        foreach ($file in $files) {
            $relPath = $file.FullName.Substring($basePath.Length + 1).Replace("\", "/")
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName, $relPath) | Out-Null
        }
    } elseif (Test-Path $target -PathType Leaf) {
        $file = Get-Item $target
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName, $file.Name) | Out-Null
    }
}
$zip.Dispose()

Rename-Item -Path "balatrofb.zip" -NewName "balatrofb.love" -Force

# 3. Compile to WebAssembly using love.js
Write-Host "Compiling to WebAssembly via love.js (this may take a moment)..." -ForegroundColor Cyan
# Using npx to automatically fetch and run Davidobot's love.js (without -c for standard WebGL GitHub Pages compatibility)
npx -y --package=love.js love.js.cmd balatrofb.love web_build -t "Chain Gain"

if (-not (Test-Path "web_build")) {
    Write-Host "Error: Web build failed. 'web_build' directory does not exist." -ForegroundColor Red
    exit 1
}

# 3.4 Inject Cross-Origin Isolation Service Worker for GitHub Pages SharedArrayBuffer support
if (Test-Path "web_build/index.html") {
    Write-Host "Creating local coi-serviceworker.js for same-origin GitHub Pages deployment..." -ForegroundColor Yellow
    $coiJsCode = @'
/*! coi-serviceworker v0.1.7 - Guido Zufolo (MIT) */
if (typeof window !== "undefined") {
    const n = navigator;
    if (n.serviceWorker) {
        n.serviceWorker.register("coi-serviceworker.js").then(
            (registration) => {
                if (registration.active && !n.serviceWorker.controller) {
                    window.location.reload();
                }
                registration.addEventListener("updatefound", () => {
                    window.location.reload();
                });
            },
            (err) => {
                console.error("COOP/COEP Service Worker failed to register:", err);
            }
        );
        n.serviceWorker.addEventListener("controllerchange", () => {
            window.location.reload();
        });
    }
} else {
    self.addEventListener("install", () => self.skipWaiting());
    self.addEventListener("activate", (event) => event.waitUntil(self.clients.claim()));

    self.addEventListener("fetch", (event) => {
        const request = event.request;
        if (request.cache === "only-if-cached" && request.mode !== "same-origin") {
            return;
        }

        event.respondWith(
            fetch(request)
                .then((response) => {
                    if (response.status === 0) {
                        return response;
                    }

                    const newHeaders = new Headers(response.headers);
                    newHeaders.set("Cross-Origin-Opener-Policy", "same-origin");
                    newHeaders.set("Cross-Origin-Embedder-Policy", "credentialless");

                    return new Response(response.body, {
                        status: response.status,
                        statusText: response.statusText,
                        headers: newHeaders,
                    });
                })
                .catch((e) => console.error(e))
        );
    });
}
'@
    Set-Content "web_build/coi-serviceworker.js" $coiJsCode -NoNewline

    $html = Get-Content "web_build/index.html" -Raw
    $coiScript = '<script src="coi-serviceworker.js"></script>'
    if (-not $html.Contains("coi-serviceworker")) {
        $html = $html.Replace("<head>", "<head>`n    $coiScript")
        Set-Content "web_build/index.html" $html -NoNewline
    }
}

# 3.45 Disable IndexedDB stale package caching and add cache buster to game.data in game.js
$ts = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
if (Test-Path "web_build/game.js") {
    Write-Host "Bypassing stale IndexedDB cache and cache-busting game.data in game.js..." -ForegroundColor Yellow
    $gameJs = Get-Content "web_build/game.js" -Raw
    $gameJs = $gameJs -replace 'if \((false && )?useCached\) \{', 'if (false && useCached) {'
    $gameJs = $gameJs -replace "var REMOTE_PACKAGE_BASE = 'game\.data(\?v=\d+)?';", ("var REMOTE_PACKAGE_BASE = 'game.data?v=" + $ts + "';")
    Set-Content "web_build/game.js" $gameJs -NoNewline
}

# 3.48 Inject Mobile Landscape & PWA WebApp Support (Manifest + Orientation Prompt + Touch CSS)
if (Test-Path "web_build/index.html") {
    Write-Host "Configuring PWA WebApp & Mobile Landscape optimization..." -ForegroundColor Yellow
    
    # Create manifest.json
    $manifestJson = @'
{
  "name": "Chain Gain",
  "short_name": "ChainGain",
  "start_url": "./index.html",
  "display": "standalone",
  "orientation": "landscape",
  "background_color": "#0b0d13",
  "theme_color": "#00c3ff",
  "icons": [
    {
      "src": "favicon.ico",
      "sizes": "192x192 512x512",
      "type": "image/png"
    }
  ]
}
'@
    Set-Content "web_build/manifest.json" $manifestJson -NoNewline

    $html = Get-Content "web_build/index.html" -Raw
    $pwaMeta = @'
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
    <meta name="mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
    <meta name="apple-mobile-web-app-title" content="Chain Gain">
    <link rel="manifest" href="manifest.json">
    <style>
      html, body {
        margin: 0; padding: 0; width: 100vw; height: 100vh;
        background-color: #0b0d13; overflow: hidden;
        touch-action: none; user-select: none;
        -webkit-user-select: none; -webkit-touch-callout: none;
      }
      #canvas {
        width: 100vw; height: 100vh; object-fit: contain;
        display: block; margin: auto;
      }
      #rotate-prompt {
        display: none; position: fixed; top: 0; left: 0;
        width: 100vw; height: 100vh; background: #0f141f;
        color: #00c3ff; font-family: system-ui, sans-serif;
        font-size: 20px; font-weight: bold; z-index: 99999;
        text-align: center; box-sizing: border-box; padding-top: 35vh;
      }
      @media screen and (orientation: portrait) and (max-width: 900px) {
        #rotate-prompt { display: block; }
      }
    </style>
'@
    if (-not $html.Contains("manifest.json")) {
        $html = $html.Replace("<head>", "<head>`n$pwaMeta")
    }
    
    $rotatePromptDiv = '<div id="rotate-prompt">🏈 <b>CHAIN GAIN</b><br><br>🔄 Please rotate your phone/tablet to <b>Landscape Mode</b> to play!</div>'
    if (-not $html.Contains("rotate-prompt")) {
        $html = $html.Replace("<body>", "<body>`n$rotatePromptDiv")
    }

    # 3.49 Add timestamp cache buster to script tags & purge IndexedDB in index.html
    $html = $html -replace 'src="game\.js(\?v=\d+)?"', ('src="game.js?v=' + $ts + '"')
    $html = $html -replace 'src="love\.js(\?v=\d+)?"', ('src="love.js?v=' + $ts + '"')
    $html = $html -replace 'src="coi-serviceworker\.js(\?v=\d+)?"', ('src="coi-serviceworker.js?v=' + $ts + '"')

    $purgeDbScript = @'
    <script>
      if (window.indexedDB) {
        try { window.indexedDB.deleteDatabase('/balatrofb'); } catch(e){}
        try { window.indexedDB.deleteDatabase('/game'); } catch(e){}
      }
    </script>
'@
    if (-not $html.Contains("deleteDatabase")) {
        $html = $html.Replace("<head>", "<head>`n$purgeDbScript")
    }
    
    Set-Content "web_build/index.html" $html -NoNewline
}

# 3.5 Inject game icon as browser tab favicon
if (Test-Path "assets/icon.png") {
    Copy-Item "assets/icon.png" "web_build/favicon.ico" -Force
}

# 3.6 Automatically publish web_build to GitHub Pages gh-pages branch
$remoteUrl = (git config --get remote.origin.url)
if ($remoteUrl) {
    Write-Host "Deploying compiled web build directly to GitHub Pages (gh-pages)..." -ForegroundColor Yellow
    Push-Location web_build
    try {
        git init -q
        git checkout -B gh-pages
        git remote add origin $remoteUrl.Trim() 2>$null
        git add .
        git commit -m "Automated GitHub Pages Deployment" -q
        git push origin gh-pages --force
        Write-Host "GitHub Pages deployment complete!" -ForegroundColor Green
    } finally {
        Pop-Location
    }
}

Write-Host "Build complete! Output is in the 'web_build' folder." -ForegroundColor Green

if (-not $NoServe) {
    Write-Host "Starting local web server on http://localhost:8000..." -ForegroundColor Cyan
    Write-Host "Please open this URL in Chrome on your remote desktop for smooth rendering." -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to stop the server." -ForegroundColor Red

    # 4. Start the local server
    npx serve -l 8000 web_build
}
