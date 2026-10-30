$Architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
$Platform = if ($Architecture -eq "Arm64") { "windows-arm64" } else { "windows-x64" }
$Target = Join-Path $PSScriptRoot "..\bin\trim-cli-$Platform.exe"

$SkipValue = $false
foreach ($Argument in $args) {
  if ($SkipValue) {
    $SkipValue = $false
    continue
  }
  if ($Argument -in @("--host", "--port", "--profile", "--scheme")) {
    $SkipValue = $true
    continue
  }
  if ($Argument.StartsWith("-")) {
    continue
  }
  if ($Argument -eq "media") {
    Write-Error "Media commands are not available in this skill package."
    exit 2
  }
  break
}

# 桌面端设置页注入的连接参数：未显式传参时补默认值
$HasHost = $false
$HasPort = $false
$HasScheme = $false
foreach ($Argument in $args) {
  if ($Argument -eq "--host" -or $Argument -like "--host=*") { $HasHost = $true }
  if ($Argument -eq "--port" -or $Argument -like "--port=*") { $HasPort = $true }
  if ($Argument -eq "--scheme" -or $Argument -like "--scheme=*") { $HasScheme = $true }
}

$Injected = @()
if (-not $HasHost -and $env:FNOS_HOST) { $Injected += @("--host", $env:FNOS_HOST) }
if (-not $HasPort -and $env:FNOS_PORT) { $Injected += @("--port", $env:FNOS_PORT) }
if (-not $HasScheme -and $env:FNOS_SCHEME) { $Injected += @("--scheme", $env:FNOS_SCHEME) }

if (-not (Test-Path $Target)) {
  Write-Error "Missing packaged binary: $Target"
  exit 1
}

& $Target @($Injected + $args)
exit $LASTEXITCODE
