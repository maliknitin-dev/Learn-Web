# Serves this folder at http://127.0.0.1:8765/
# Run in a terminal:  .\serve.ps1
# Stop: close the terminal, or press Ctrl+C

$root = $PSScriptRoot
$port = 8766
$url = "http://127.0.0.1:$port/"

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add($url)
try {
  $listener.Start()
} catch {
  Write-Host "Could not start on port $port. Is another server already using it?"
  Write-Host $_
  exit 1
}

Write-Host "Serving $root"
Write-Host "Open $url  (Ctrl+C to stop)"

while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $path = [Uri]::UnescapeDataString($ctx.Request.Url.LocalPath.TrimStart('/'))
  if ([string]::IsNullOrWhiteSpace($path)) { $path = 'index.html' }
  $full = Join-Path $root $path
  if (Test-Path $full -PathType Leaf) {
    $ext = [IO.Path]::GetExtension($full).ToLower()
    $type = switch ($ext) {
      '.html' { 'text/html; charset=utf-8' }
      '.css'  { 'text/css; charset=utf-8' }
      default { 'application/octet-stream' }
    }
    $bytes = [IO.File]::ReadAllBytes($full)
    $ctx.Response.ContentType = $type
    $ctx.Response.StatusCode = 200
    $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
  } else {
    $ctx.Response.StatusCode = 404
  }
  $ctx.Response.Close()
}
