# 생기부 면접 준비기 - Node.js가 없을 때 쓰는 대체 웹서버 (윈도우 기본 PowerShell만 사용)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$ports = @(8731, 8732, 8733, 8734, 8735)

$mime = @{
  '.html' = 'text/html; charset=utf-8'
  '.js'   = 'text/javascript; charset=utf-8'
  '.json' = 'application/json; charset=utf-8'
  '.webmanifest' = 'application/manifest+json; charset=utf-8'
  '.png'  = 'image/png'
  '.svg'  = 'image/svg+xml'
  '.ico'  = 'image/x-icon'
  '.txt'  = 'text/plain; charset=utf-8'
  '.css'  = 'text/css; charset=utf-8'
}

$listener = New-Object System.Net.HttpListener
$port = $null
foreach ($p in $ports) {
  try {
    $listener.Prefixes.Clear()
    $listener.Prefixes.Add("http://127.0.0.1:$p/")
    $listener.Start()
    $port = $p
    break
  } catch {
    try { $listener.Close() } catch {}
    $listener = New-Object System.Net.HttpListener
  }
}

if ($null -eq $port) {
  Write-Host '사용 가능한 포트를 찾지 못했습니다. 실행 중인 다른 창을 닫고 다시 시도해 주세요.'
  exit 1
}

$url = "http://127.0.0.1:$port/"
Write-Host ''
Write-Host '  생기부 면접 준비기가 실행되었습니다.'
Write-Host "  주소: $url"
Write-Host ''
Write-Host '  * 주소창 오른쪽의 설치 아이콘 또는 화면 위쪽 [앱 설치] 버튼으로 설치하세요.'
Write-Host '  * 이 창을 닫으면 앱이 멈춥니다. 설치 후에는 닫아도 됩니다.'
Write-Host ''
Start-Process $url

while ($listener.IsListening) {
  try {
    $ctx = $listener.GetContext()
    $rel = [System.Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath)
    if ($rel -eq '/') { $rel = '/index.html' }
    $file = Join-Path $root ($rel -replace '^/', '' -replace '/', '\')

    if ((Test-Path $file -PathType Leaf) -and ((Resolve-Path $file).Path).StartsWith((Resolve-Path $root).Path)) {
      $ext = [System.IO.Path]::GetExtension($file).ToLower()
      $ct = $mime[$ext]
      if (-not $ct) { $ct = 'application/octet-stream' }
      $bytes = [System.IO.File]::ReadAllBytes($file)
      $ctx.Response.ContentType = $ct
      if ([System.IO.Path]::GetFileName($file) -eq 'sw.js') { $ctx.Response.Headers.Add('Cache-Control', 'no-cache') }
      $ctx.Response.StatusCode = 200
      $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $msg = [System.Text.Encoding]::UTF8.GetBytes("찾을 수 없습니다: $rel")
      $ctx.Response.StatusCode = 404
      $ctx.Response.ContentType = 'text/plain; charset=utf-8'
      $ctx.Response.OutputStream.Write($msg, 0, $msg.Length)
    }
    $ctx.Response.Close()
  } catch {
    # 개별 요청 오류는 무시하고 계속 대기합니다
  }
}
