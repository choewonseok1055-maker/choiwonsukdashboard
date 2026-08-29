# 브랜드 경영 현황판 로컬 서버  ->  http://localhost:8090/
param([int]$Port = 8090, [string]$Root = "D:\Dashboard")

$rootFull = [System.IO.Path]::GetFullPath($Root)

# index = 폴더에서 가장 큰 .html (데이터가 내장된 현황판 파일) - 비ASCII 파일명 하드코딩 회피
$indexFile = Get-ChildItem -LiteralPath $Root -Filter *.html |
  Sort-Object Length -Descending | Select-Object -First 1

$mime = @{}
$mime['.html'] = 'text/html; charset=utf-8'
$mime['.htm']  = 'text/html; charset=utf-8'
$mime['.css']  = 'text/css; charset=utf-8'
$mime['.js']   = 'application/javascript; charset=utf-8'
$mime['.json'] = 'application/json; charset=utf-8'
$mime['.png']  = 'image/png'
$mime['.jpg']  = 'image/jpeg'
$mime['.svg']  = 'image/svg+xml'
$mime['.ico']  = 'image/x-icon'
$mime['.woff2']= 'font/woff2'

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
try { $listener.Start() }
catch {
  Write-Host ("Cannot bind port {0}: {1}" -f $Port, $_.Exception.Message)
  Write-Host "(already running? open http://localhost:$Port/ )"
  Start-Sleep 8
  exit 1
}

Write-Host ""
Write-Host "  ============================================"
Write-Host ("   Dashboard:  http://localhost:{0}/" -f $Port)
Write-Host ("   index    :  {0}" -f $indexFile.Name)
Write-Host "   Stop     :  close this window"
Write-Host "  ============================================"
Write-Host ""

while ($listener.IsListening) {
  try { $ctx = $listener.GetContext() } catch { break }
  $req = $ctx.Request
  $res = $ctx.Response
  $status = 200
  try {
    $rel = [Uri]::UnescapeDataString($req.Url.AbsolutePath).TrimStart('/')
    $rel = $rel -replace '/', '\'

    if ([string]::IsNullOrWhiteSpace($rel) -or $rel -eq 'index.html') {
      $target = $indexFile.FullName
    } else {
      $target = [System.IO.Path]::GetFullPath((Join-Path $rootFull $rel))
    }

    if ($null -eq $target -or -not $target.StartsWith($rootFull)) {
      $status = 403
      $bytes = [System.Text.Encoding]::UTF8.GetBytes('403')
      $res.ContentType = 'text/plain; charset=utf-8'
    }
    elseif (Test-Path -LiteralPath $target -PathType Leaf) {
      $bytes = [System.IO.File]::ReadAllBytes($target)
      $ext = [System.IO.Path]::GetExtension($target).ToLower()
      if ($mime.ContainsKey($ext)) { $res.ContentType = $mime[$ext] } else { $res.ContentType = 'application/octet-stream' }
    }
    else {
      $status = 404
      $bytes = [System.Text.Encoding]::UTF8.GetBytes('404 Not Found')
      $res.ContentType = 'text/plain; charset=utf-8'
    }

    $res.StatusCode = $status
    $res.Headers.Add('Cache-Control', 'no-store')
    $res.ContentLength64 = $bytes.Length
    $res.OutputStream.Write($bytes, 0, $bytes.Length)
    Write-Host ("{0}  {1}  {2}" -f (Get-Date -Format 'HH:mm:ss'), $status, $req.Url.AbsolutePath)
  }
  catch {
    Write-Host ("ERR  {0}" -f $_.Exception.Message)
    try { $res.StatusCode = 500 } catch {}
  }
  finally {
    try { $res.OutputStream.Close() } catch {}
  }
}
$listener.Stop()
