<#
  Phase 0 - Windows dev machine prep
  Run ONCE, elevated. Reboot afterwards.

  This is the only step of the whole setup that needs administrator rights.
  Everything it does:
    1. Enables three Windows features (WSL2 + the Android emulator's hypervisor)
    2. Enables NTFS long path support
    3. Enables Developer Mode (lets you create symlinks without admin)
    4. Adds Windows Defender exclusions for dev folders and build processes

  Safe to run more than once. Nothing here is destructive.
#>

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------- guard rails
$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
  ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
  Write-Host ""
  Write-Host "  This script must run as Administrator." -ForegroundColor Red
  Write-Host "  Right-click it and choose 'Run with PowerShell' as admin, or run:" -ForegroundColor Yellow
  Write-Host "    Start-Process powershell -Verb RunAs -ArgumentList '-NoExit','-File','$PSCommandPath'" -ForegroundColor Yellow
  Write-Host ""
  exit 1
}

function Write-Step($text) {
  Write-Host ""
  Write-Host "=== $text " -ForegroundColor Cyan
}
function Write-Ok($text)   { Write-Host "  [ok]   $text" -ForegroundColor Green }
function Write-Skip($text) { Write-Host "  [skip] $text" -ForegroundColor DarkGray }
function Write-Warn2($text){ Write-Host "  [warn] $text" -ForegroundColor Yellow }

$needsReboot = $false

# ------------------------------------------------------------ pre-flight check
# DISM refuses to change ANY optional feature while Windows has servicing
# operations in flight, and it reports that transitional state as
# "The component store has been corrupted" (0x80073712) - which is misleading.
# Bail out early with something actionable instead.
Write-Step "Pre-flight: pending servicing operations"

$pendingReasons = @()
if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') {
  $pendingReasons += 'Component Based Servicing has a reboot pending'
}
if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\PackagesPending') {
  $pendingReasons += 'Packages are staged but not yet installed'
}
if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') {
  $pendingReasons += 'Windows Update requires a reboot'
}

if ($pendingReasons.Count -gt 0) {
  Write-Host ""
  Write-Host "  Cannot continue - Windows is mid-update:" -ForegroundColor Red
  foreach ($r in $pendingReasons) { Write-Host "    - $r" -ForegroundColor Yellow }
  Write-Host ""
  Write-Host "  Fix: install any pending updates, then REBOOT, then re-run this script." -ForegroundColor Cyan
  Write-Host "         start ms-settings:windowsupdate" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "  Enabling features now would fail with 0x80073712 and look like disk" -ForegroundColor DarkGray
  Write-Host "  corruption when it is really just an unfinished update." -ForegroundColor DarkGray
  Write-Host ""
  exit 1
}
Write-Ok "No pending servicing operations"

# ------------------------------------------------- 1. Windows optional features
# VirtualMachinePlatform      -> required by WSL2
# Microsoft-Windows-Subsystem-Linux -> the WSL feature itself
# HypervisorPlatform (WHPX)   -> what the Android emulator uses for hardware
#                                acceleration. Required here because Windows 11
#                                virtualization-based security already has the
#                                hypervisor running, which rules out AEHD/HAXM.
Write-Step "Windows features"

$features = @(
  'VirtualMachinePlatform',
  'Microsoft-Windows-Subsystem-Linux',
  'HypervisorPlatform'
)

# Each feature is attempted independently: a failure on one must not abort the
# harmless registry/Defender work further down.
$failedFeatures = @()

foreach ($f in $features) {
  try {
    $state = Get-WindowsOptionalFeature -Online -FeatureName $f -ErrorAction Stop
    if ($state.State -eq 'Enabled') {
      Write-Skip "$f already enabled"
    } else {
      $result = Enable-WindowsOptionalFeature -Online -FeatureName $f -All -NoRestart -ErrorAction Stop
      Write-Ok "$f enabled"
      if ($result.RestartNeeded) { $needsReboot = $true }
    }
  }
  catch {
    $failedFeatures += $f
    Write-Warn2 "$f FAILED - $($_.Exception.Message)"
  }
}

# ------------------------------------------------------------- 2. Long paths
# Windows defaults to a 260-character path limit. Gradle caches, node_modules
# and Android build intermediates blow past that routinely.
Write-Step "NTFS long path support"

$fsKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem'
$current = (Get-ItemProperty -Path $fsKey -Name LongPathsEnabled -ErrorAction SilentlyContinue).LongPathsEnabled

if ($current -eq 1) {
  Write-Skip "LongPathsEnabled already 1"
} else {
  Set-ItemProperty -Path $fsKey -Name LongPathsEnabled -Value 1 -Type DWord
  Write-Ok "LongPathsEnabled set to 1"
  $needsReboot = $true
}

# --------------------------------------------------------- 3. Developer Mode
# Allows creating symbolic links as a normal user. Needed for dotfile managers,
# `npm link`, and a handful of build tools that symlink instead of copying.
Write-Step "Developer Mode (unprivileged symlinks)"

$devKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
if (-not (Test-Path $devKey)) { New-Item -Path $devKey -Force | Out-Null }
$devCurrent = (Get-ItemProperty -Path $devKey -Name AllowDevelopmentWithoutDevLicense -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense

if ($devCurrent -eq 1) {
  Write-Skip "Developer Mode already on"
} else {
  Set-ItemProperty -Path $devKey -Name AllowDevelopmentWithoutDevLicense -Value 1 -Type DWord
  Write-Ok "Developer Mode enabled"
}

# ---------------------------------------------------- 4. Defender exclusions
# Gradle and npm create tens of thousands of small files per build. Real-time
# scanning each one is the single largest source of slow builds on Windows.
#
# TRADEOFF: files under these paths are no longer scanned in real time. Be
# deliberate about what you clone into C:\dev and what you execute from it.
# Remove any exclusion later with Remove-MpPreference -ExclusionPath '<path>'
Write-Step "Windows Defender exclusions"

$home2 = $env:USERPROFILE

$exclusionPaths = @(
  'C:\dev',                                       # all source code
  "$home2\.gradle",                               # Gradle caches + daemon
  "$home2\.android",                              # avd images, adb keys
  "$home2\.m2",                                   # Maven repo, if ever used
  "$home2\.konan",                                # Kotlin/Native (KMP) toolchain
  "$home2\AppData\Local\Android\Sdk",             # Android SDK + emulator
  "$home2\AppData\Local\Temp\gradle"              # Gradle scratch space
)

$exclusionProcesses = @(
  'java.exe',                   # Gradle, Kotlin compiler, most JVM tooling
  'javaw.exe',
  'kotlin-daemon.exe',
  'studio64.exe',               # Android Studio
  'adb.exe',                    # device bridge
  'qemu-system-x86_64.exe',     # the emulator itself
  'git.exe',
  'node.exe'
)

try {
  $mp = Get-MpPreference

  foreach ($p in $exclusionPaths) {
    if ($mp.ExclusionPath -contains $p) {
      Write-Skip "path $p"
    } else {
      Add-MpPreference -ExclusionPath $p
      Write-Ok "path $p"
    }
  }

  foreach ($proc in $exclusionProcesses) {
    if ($mp.ExclusionProcess -contains $proc) {
      Write-Skip "process $proc"
    } else {
      Add-MpPreference -ExclusionProcess $proc
      Write-Ok "process $proc"
    }
  }
}
catch {
  Write-Warn2 "Could not set Defender exclusions: $($_.Exception.Message)"
  Write-Warn2 "This is non-fatal. Third-party antivirus or a group policy may be managing Defender."
}

# ------------------------------------------------------------------- summary
Write-Step "Done"

if ($failedFeatures.Count -gt 0) {
  Write-Host "  These features could NOT be enabled:" -ForegroundColor Red
  foreach ($f in $failedFeatures) { Write-Host "    - $f" -ForegroundColor Yellow }
  Write-Host ""
  Write-Host "  The registry and Defender changes above still applied." -ForegroundColor DarkGray
  Write-Host "  Report the error text to Claude before retrying." -ForegroundColor Cyan
  Write-Host ""
  exit 1
}

if ($needsReboot) {
  Write-Host "  A REBOOT IS REQUIRED before WSL will work." -ForegroundColor Yellow
  Write-Host "  Reboot, then tell Claude 'Phase 0 done' to continue with Phase 1." -ForegroundColor Yellow
} else {
  Write-Host "  No reboot needed - everything was already in place." -ForegroundColor Green
  Write-Host "  Tell Claude 'Phase 0 done' to continue with Phase 1." -ForegroundColor Green
}
Write-Host ""
