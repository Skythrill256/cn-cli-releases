$ErrorActionPreference = "Stop"

$baseUrl = if ($env:CN_RELEASE_BASE_URL) {
  $env:CN_RELEASE_BASE_URL
} else {
  "https://skythrill256.github.io/cn-cli-releases"
}

$version = if ($env:CN_VERSION) {
  $env:CN_VERSION
} else {
  ((Invoke-WebRequest -UseBasicParsing -Uri "$baseUrl/latest").Content).Trim()
}

$arch = if ($env:PROCESSOR_ARCHITEW6432) {
  $env:PROCESSOR_ARCHITEW6432
} else {
  $env:PROCESSOR_ARCHITECTURE
}

$platform = if ($arch -eq "ARM64") {
  "win32-arm64"
} else {
  "win32-x64"
}

$installDir = if ($env:CN_INSTALL_DIR) {
  $env:CN_INSTALL_DIR
} else {
  Join-Path $env:LOCALAPPDATA "cn-cli\bin"
}

$gzipPath = Join-Path $env:TEMP "cn.exe.gz"
$exePath = Join-Path $installDir "cn.exe"

New-Item -ItemType Directory -Force -Path $installDir | Out-Null
Invoke-WebRequest -UseBasicParsing -Uri "$baseUrl/$version/$platform/cn.exe.gz" -OutFile $gzipPath

Add-Type -AssemblyName System.IO.Compression
$source = [System.IO.File]::OpenRead($gzipPath)
try {
  $target = [System.IO.File]::Create($exePath)
  try {
    $gzip = New-Object -TypeName System.IO.Compression.GZipStream -ArgumentList $source, ([System.IO.Compression.CompressionMode]::Decompress)
    try {
      $gzip.CopyTo($target)
    } finally {
      $gzip.Dispose()
    }
  } finally {
    $target.Dispose()
  }
} finally {
  $source.Dispose()
}

Remove-Item -Force $gzipPath

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if (-not $userPath) {
  $userPath = ""
}

if (($userPath -split ";") -notcontains $installDir) {
  $newPath = ($userPath.TrimEnd(";") + ";" + $installDir).Trim(";")
  [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
}

if (($env:Path -split ";") -notcontains $installDir) {
  $env:Path = "$installDir;$env:Path"
}

& $exePath --version
