$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$requiredFiles = @(
    "package.json",
    "README.md",
    "CHANGELOG.md",
    "LICENSE.md",
    "CONTRIBUTING.md",
    "Runtime/JorisHoef.ObjectSelection.CoreState.asmdef",
    "Runtime/ObjectSelectionCoreStateBridge.cs",
    "Tests/EditMode/JorisHoef.ObjectSelection.CoreState.Tests.asmdef",
    "Samples~/CoreStateBridgeSample/JorisHoef.ObjectSelection.CoreState.Samples.CoreStateBridgeSample.asmdef",
    "Samples~/CoreStateBridgeSample/CoreStateBridgeSample.unity"
)

$requiredDirectories = @(
    "Runtime",
    "Tests/EditMode",
    "Samples~/CoreStateBridgeSample",
    "Tools",
    ".github/workflows"
)

foreach ($directory in $requiredDirectories) {
    $path = Join-Path $root $directory
    if (-not (Test-Path -LiteralPath $path -PathType Container)) {
        throw "Missing required directory: $directory"
    }
}

foreach ($file in $requiredFiles) {
    $path = Join-Path $root $file
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing required file: $file"
    }
}

$package = Get-Content -LiteralPath (Join-Path $root "package.json") -Raw | ConvertFrom-Json
if ($package.name -ne "com.jorishoef.objectselection-corestate-bridge") {
    throw "Unexpected package name: $($package.name)"
}

if ($package.displayName -ne "JorisHoef ObjectSelection CoreState Bridge") {
    throw "Unexpected package display name: $($package.displayName)"
}

if ($package.version -notmatch "^\d+\.\d+\.\d+$") {
    throw "Package version must be semver MAJOR.MINOR.PATCH: $($package.version)"
}

if ($package.dependencies."com.jorishoef.object-selection" -ne "1.0.0") {
    throw "Package must depend on com.jorishoef.object-selection 1.0.0"
}

if ($package.dependencies."com.jorishoef.core.state" -ne "1.0.0") {
    throw "Package must depend on com.jorishoef.core.state 1.0.0"
}

$runtimeAsmdef = Get-Content -LiteralPath (Join-Path $root "Runtime/JorisHoef.ObjectSelection.CoreState.asmdef") -Raw | ConvertFrom-Json
if ($runtimeAsmdef.name -ne "JorisHoef.ObjectSelection.CoreState") {
    throw "Unexpected runtime asmdef name: $($runtimeAsmdef.name)"
}

if ($runtimeAsmdef.references -notcontains "JorisHoef.ObjectSelection") {
    throw "Runtime asmdef must reference JorisHoef.ObjectSelection"
}

if ($runtimeAsmdef.references -notcontains "JorisHoef.Core.State") {
    throw "Runtime asmdef must reference JorisHoef.Core.State"
}

$testAsmdef = Get-Content -LiteralPath (Join-Path $root "Tests/EditMode/JorisHoef.ObjectSelection.CoreState.Tests.asmdef") -Raw | ConvertFrom-Json
if ($testAsmdef.references -notcontains "JorisHoef.ObjectSelection.CoreState") {
    throw "Tests asmdef must reference JorisHoef.ObjectSelection.CoreState"
}

$sampleAsmdef = Get-Content -LiteralPath (Join-Path $root "Samples~/CoreStateBridgeSample/JorisHoef.ObjectSelection.CoreState.Samples.CoreStateBridgeSample.asmdef") -Raw | ConvertFrom-Json
if ($sampleAsmdef.references -notcontains "JorisHoef.ObjectSelection.CoreState") {
    throw "Sample asmdef must reference JorisHoef.ObjectSelection.CoreState"
}

$forbiddenReferences = @(
    "GenericUIItems",
    "APIHelper",
    "SessionHelper",
    "UnityEngine.UI",
    "UnityEngine.EventSystems",
    "UnityEngine.UIElements",
    "ServiceLocator"
)

$sourceFiles = Get-ChildItem -LiteralPath $root -Recurse -File -Filter "*.cs" |
    Where-Object { $_.FullName -notmatch "\\Tests\\" }
foreach ($sourceFile in $sourceFiles) {
    $content = Get-Content -LiteralPath $sourceFile.FullName -Raw
    foreach ($forbiddenReference in $forbiddenReferences) {
        if ($content -match [regex]::Escape($forbiddenReference)) {
            throw "Source file $($sourceFile.Name) contains forbidden reference: $forbiddenReference"
        }
    }
}

$forbiddenProjectScaffolding = @("Assets", "Packages", "ProjectSettings")
foreach ($directory in $forbiddenProjectScaffolding) {
    $path = Join-Path $root $directory
    if (Test-Path -LiteralPath $path -PathType Container) {
        throw "Package repository should not contain Unity project scaffolding directory: $directory"
    }
}

$generatedArtifacts = Get-ChildItem -LiteralPath $root -Recurse -Force -File |
    Where-Object { $_.Name -match "\.(unitypackage|zip|tar|tgz)$" }
if ($generatedArtifacts.Count -gt 0) {
    throw "Generated artifacts are present in the package repository."
}

Write-Host "JorisHoef ObjectSelection CoreState Bridge package validation passed."
