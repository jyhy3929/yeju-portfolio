$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$port = 8080
$prefix = "http://localhost:$port/"

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)
try {
  $listener.Start()
} catch {
  Write-Host "Could not start server on port $port. Another program may be using it."
  Write-Host $_.Exception.Message
  Read-Host "Press Enter to close"
  exit
}

Write-Host "==============================================="
Write-Host " Server running at: $prefix"
Write-Host " Close this window to stop the server."
Write-Host "==============================================="
Start-Process $prefix

$mimeMap = @{
  ".html" = "text/html; charset=utf-8"
  ".css"  = "text/css"
  ".js"   = "application/javascript"
  ".png"  = "image/png"
  ".jpg"  = "image/jpeg"
  ".jpeg" = "image/jpeg"
  ".mp4"  = "video/mp4"
  ".mp3"  = "audio/mpeg"
  ".glb"  = "model/gltf-binary"
  ".ico"  = "image/x-icon"
}

while ($listener.IsListening) {
  $context = $listener.GetContext()
  $request = $context.Request
  $response = $context.Response
  try {
    $localPath = [System.Uri]::UnescapeDataString($request.Url.LocalPath)
    if ($localPath -eq "/") { $localPath = "/index.html" }
    $relative = $localPath.TrimStart("/") -replace "/", [System.IO.Path]::DirectorySeparatorChar
    $filePath = Join-Path $root $relative

    if (Test-Path $filePath -PathType Leaf) {
      $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
      $contentType = $mimeMap[$ext]
      if (-not $contentType) { $contentType = "application/octet-stream" }
      $bytes = [System.IO.File]::ReadAllBytes($filePath)
      $response.ContentType = $contentType
      $response.ContentLength64 = $bytes.Length
      $response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $response.StatusCode = 404
      $notFoundText = "404 Not Found: " + $localPath
      $msg = [System.Text.Encoding]::UTF8.GetBytes($notFoundText)
      $response.OutputStream.Write($msg, 0, $msg.Length)
    }
  } catch {
    try {
      $response.StatusCode = 500
      $errText = "500 Server Error"
      $msg = [System.Text.Encoding]::UTF8.GetBytes($errText)
      $response.OutputStream.Write($msg, 0, $msg.Length)
    } catch {}
  } finally {
    $response.OutputStream.Close()
  }
}
