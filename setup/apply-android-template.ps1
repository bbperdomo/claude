<#
  Applies the Android Claude bundle to an Android project:
    - AGENTS.md / CLAUDE.md / .gitattributes / .worktreeinclude from templates\android
    - project-scope plugins from the bbperdomo marketplace
    - Google's core Android skills into <project>\.claude\skills

  Usage:
    .\setup\apply-android-template.ps1 -Project C:\dev\projects\MyApp
    .\setup\apply-android-template.ps1 -Project C:\dev\projects\MyApp -Force   # overwrite template files

  Existing files are left alone unless -Force is given. Safe to re-run.
#>
param(
  [Parameter(Mandatory)] [string]$Project,
  [string]$Name,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'

$Project = (Resolve-Path $Project).Path
if (-not (Test-Path (Join-Path $Project 'settings.gradle.kts')) -and -not (Test-Path (Join-Path $Project 'settings.gradle'))) {
  throw "$Project doesn't look like a Gradle project root (no settings.gradle[.kts])"
}
if (-not $Name) { $Name = Split-Path $Project -Leaf }

$template = Join-Path (Split-Path $PSScriptRoot -Parent) 'templates\android'

# Plugins enabled for every Android project
$plugins = @('android-dev@bbperdomo', 'chrisbanes-compose@bbperdomo')

# Google's official skills. Niche ones (Wear, TV, XR, Cast, CameraX, Billing,
# Play policy audits, etc.) are added per project when needed:
#   android skills add <skill> --agent=claude-code --project=.
$googleSkills = @(
  'android-cli',
  'agp-9-upgrade',
  'edge-to-edge',
  'navigation-3',
  'testing-setup',
  'android-profiler',
  'r8-analyzer',
  'android-intent-security'
)

Write-Host "== Template files -> $Project" -ForegroundColor Cyan
foreach ($f in 'AGENTS.md', 'CLAUDE.md', '.gitattributes', '.worktreeinclude') {
  $dst = Join-Path $Project $f
  if ((Test-Path $dst) -and -not $Force) { Write-Host "  [keep]  $f (exists)"; continue }
  $text = Get-Content (Join-Path $template $f) -Raw
  $text = $text -replace '\{\{PROJECT_NAME\}\}', $Name
  [IO.File]::WriteAllText($dst, $text, (New-Object Text.UTF8Encoding($false)))
  Write-Host "  [write] $f"
}

Write-Host "== Project-scope plugins" -ForegroundColor Cyan
Push-Location $Project
try {
  foreach ($p in $plugins) {
    claude plugin install $p --scope project | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "installing $p failed" }
    Write-Host "  [ok]    $p"
  }
}
finally { Pop-Location }

Write-Host "== Google Android skills" -ForegroundColor Cyan
foreach ($s in $googleSkills) {
  # android.exe (1.0.16261425) crashes on exit with 0xC0000409 AFTER a
  # successful install, so verify by the file on disk, not the exit code.
  android skills add $s --agent=claude-code --project=$Project *> $null
  $ok = Test-Path (Join-Path $Project ".claude\skills\$s\SKILL.md")
  if ($ok) { Write-Host "  [ok]    $s" } else { Write-Host "  [FAIL]  $s" -ForegroundColor Red }
}

Write-Host ""
Write-Host "Done. Fill in the {{placeholders}} in AGENTS.md, then commit .claude\, AGENTS.md, CLAUDE.md," -ForegroundColor Green
Write-Host ".gitattributes and .worktreeinclude so every clone gets the same setup." -ForegroundColor Green
exit 0   # don't leak android.exe's crash-on-exit code to the caller
