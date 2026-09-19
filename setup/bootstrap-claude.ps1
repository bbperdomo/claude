<#
  Recreates the user-scope Claude Code setup on a Windows machine.
  Prereqs: Claude Code CLI installed, and gh logged in (for a private marketplace repo).

  Usage:
    .\setup\bootstrap-claude.ps1                          # marketplace from GitHub
    .\setup\bootstrap-claude.ps1 -MarketplaceSource C:\dev\claude   # from a local clone (dev machine)

  Safe to re-run. An existing ~/.claude/CLAUDE.md is kept unless -Force.
#>
param(
  [string]$MarketplaceSource = 'bbperdomo/claude',
  [switch]$Force
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent

function Step($t) { Write-Host "== $t" -ForegroundColor Cyan }

Step 'Marketplaces'
$known = (claude plugin marketplace list | Out-String)
if ($known -notmatch 'claude-plugins-official') { claude plugin marketplace add anthropics/claude-plugins-official }
if ($known -notmatch '(?m)^\s*>\s*bbperdomo\s*$') { claude plugin marketplace add $MarketplaceSource }

Step 'User-scope plugins (on in every project)'
# Stack-specific plugins are NOT installed here. They're enabled per project
# (see setup\apply-android-template.ps1).
foreach ($p in 'superpowers@claude-plugins-official', 'context7@claude-plugins-official') {
  claude plugin install $p --scope user
}

Step 'Personal CLAUDE.md'
$dst = Join-Path $env:USERPROFILE '.claude\CLAUDE.md'
if ((Test-Path $dst) -and -not $Force) {
  Write-Host "  [keep] $dst exists (use -Force to overwrite)"
} else {
  Copy-Item (Join-Path $repoRoot 'user\CLAUDE.md') $dst -Force
  Write-Host "  [write] $dst"
}

Step 'Result'
claude plugin list
