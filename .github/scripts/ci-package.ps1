param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Dev", "Stable")]
    [string]$Mode,

    [switch]$Zip,
    [switch]$Installer,
    [switch]$Arm64Preview,
    [string]$InnoCompiler,
    [string]$DistRoot
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$packageScript = Join-Path $repoRoot "package.ps1"

if (-not (Test-Path -LiteralPath $packageScript -PathType Leaf)) {
    throw "Upstream packaging script not found: $packageScript"
}

$packageArgs = @()

# Development builds run tests in dedicated workflow steps so x86 failures can
# remain visible without blocking the rolling dev pre-release. Stable builds
# keep the upstream default: all package.ps1 regression tests are blocking.
if ($Mode -eq "Dev") {
    $packageArgs += "-SkipTests"
}

if ($Zip) { $packageArgs += "-Zip" }
if ($Installer) { $packageArgs += "-Installer" }
if ($Arm64Preview) { $packageArgs += "-Arm64Preview" }

if (-not [string]::IsNullOrWhiteSpace($InnoCompiler)) {
    $packageArgs += @("-InnoCompiler", $InnoCompiler)
}
if (-not [string]::IsNullOrWhiteSpace($DistRoot)) {
    $packageArgs += @("-DistRoot", $DistRoot)
}

Write-Host "CI packaging mode: $Mode"
Write-Host "Calling upstream script: $packageScript"
Write-Host "Arguments: $($packageArgs -join ' ')"

try {
    & $packageScript @packageArgs
} catch {
    Write-Error "CI packaging failed in $Mode mode: $($_.Exception.Message)"
    exit 1
}

if (-not $?) {
    throw "package.ps1 returned an unsuccessful status in $Mode mode."
}
