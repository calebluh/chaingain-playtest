param(
    [switch]$NoServe
)

# deploy_web.ps1
Write-Host "Building Chain Gain for the Web..." -ForegroundColor Cyan

# 1. Clean up old builds
if (Test-Path "balatrofb.love") { Remove-Item "balatrofb.love" -Force }
if (Test-Path "web_build") { Remove-Item "web_build" -Recurse -Force }

# 2. Package into a .love file (Using tar.exe for POSIX forward slashes required by love.js)
Write-Host "Zipping project into balatrofb.love with POSIX forward-slash paths..."
if (Get-Command tar.exe -ErrorAction SilentlyContinue) {
    tar.exe -a -c -f balatrofb.zip src assets main.lua conf.lua
} else {
    Get-ChildItem -Path "src", "assets", "main.lua", "conf.lua" | Compress-Archive -DestinationPath "balatrofb.zip" -Force
}
if (Test-Path "balatrofb.love") { Remove-Item "balatrofb.love" -Force }
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
