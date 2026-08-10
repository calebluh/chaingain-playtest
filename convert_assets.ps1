# convert_assets.ps1
# Convert vector SVG assets to raster PNG assets for Love2D

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edgePath)) {
    $edgePath = "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
}

$assets = @(
    @{ svg = "assets/images/cards/card_hb_dive.svg"; png = "assets/images/cards/card_hb_dive.png"; w = 512; h = 640 },
    @{ svg = "assets/images/blinds/blind_blitz.svg"; png = "assets/images/blinds/blind_blitz.png"; w = 256; h = 256 },
    @{ svg = "assets/images/ui/ui_audible_icon.svg"; png = "assets/images/ui/ui_audible_icon.png"; w = 128; h = 128 },
    @{ svg = "assets/images/ui/ui_cap_coin.svg"; png = "assets/images/ui/ui_cap_coin.png"; w = 128; h = 128 },
    @{ svg = "assets/images/ui/ui_down_marker.svg"; png = "assets/images/ui/ui_down_marker.png"; w = 128; h = 128 }
)

Write-Host "Organizing asset directories and converting SVGs to PNGs..." -ForegroundColor Green

foreach ($item in $assets) {
    $svgFile = Resolve-Path $item.svg -ErrorAction SilentlyContinue
    $pngFile = [System.IO.Path]::Combine((Get-Location).Path, $item.png)

    if ($svgFile) {
        $parentDir = [System.IO.Path]::GetDirectoryName($pngFile)
        if (-not (Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }
        
        Write-Host "Rendering $($item.svg) -> $($item.png) ($($item.w)x$($item.h))..."
        
        # Use Edge headless screenshot to render crisp SVG to PNG
        $tempHtml = [System.IO.Path]::Combine($env:TEMP, "render_svg.html")
        $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
<style>
  body { margin: 0; padding: 0; background: transparent; overflow: hidden; }
  img { width: $($item.w)px; height: $($item.h)px; display: block; }
</style>
</head>
<body>
  <img src="file:///$($svgFile.Path.Replace('\', '/'))" />
</body>
</html>
"@
        Set-Content -Path $tempHtml -Value $htmlContent -Encoding UTF8

        if (Test-Path $edgePath) {
            Start-Process -FilePath $edgePath -ArgumentList "--headless", "--disable-gpu", "--screenshot=`"$pngFile`"", "--window-size=$($item.w),$($item.h)", "`"file:///$tempHtml`"" -Wait -WindowStyle Hidden
        } else {
            Write-Host "Edge executable not found at $edgePath" -ForegroundColor Yellow
        }
    }
}

Write-Host "Done! Assets converted and placed in assets/images/" -ForegroundColor Green
