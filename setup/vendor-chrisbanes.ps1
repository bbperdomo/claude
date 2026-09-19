<#
  Vendors a curated subset of github.com/chrisbanes/skills into
  plugins/chrisbanes-compose, pinned to one reviewed commit.

  Why vendor rather than reference it from the marketplace:
    Upstream ships a plugin.json with its own component list, so a marketplace
    entry can't narrow it to a subset (strict:false then conflicts). Copying the
    folders we want gives exact control. Upstream is Apache-2.0, so we keep its
    LICENSE and record provenance in VENDORED.md.

  To update:
    1. Review upstream changes since the current $Sha
         https://github.com/chrisbanes/skills/compare/<old>...<new>
    2. Re-run with -Sha <new commit>
    3. Diff the result in git, bump the version in plugin.json and in
       marketplace.json, then commit.
#>
param(
  [string]$Sha = '9d982e1d9f62211af2efb7c3ff34a898d693e0a7'
)

$ErrorActionPreference = 'Stop'

# Compose + Kotlin only. Left out: general workflow skills that overlap with
# superpowers (to-plan, implement-with-subagents, shepherd, grounded-writing,
# run-github-project, using-chrisbanes-skills), plus ones needing Python or
# aimed at library authors (gradle-run, release-kotlin-library).
$skills = @(
  'compose-animations',
  'compose-component-design',
  'compose-focus-navigation',
  'compose-performance',
  'compose-state-and-effects',
  'compose-ui-testing-patterns',
  'kotlin-api-design',
  'kotlin-concurrency-and-flow',
  'kotlin-control-flow',
  'android-benchmark-comparison'
)

$repoRoot = Split-Path $PSScriptRoot -Parent
$dest     = Join-Path $repoRoot 'plugins\chrisbanes-compose'
$tmp      = Join-Path ([IO.Path]::GetTempPath()) ("chrisbanes-" + [guid]::NewGuid().ToString('N').Substring(0,8))

try {
  git init -q $tmp
  git -C $tmp remote add origin https://github.com/chrisbanes/skills.git
  git -C $tmp fetch -q --depth 1 origin $Sha
  if ($LASTEXITCODE -ne 0) { throw "fetch of $Sha failed" }
  git -C $tmp checkout -q FETCH_HEAD

  # Refuse to vendor anything executable - these skills must be markdown only
  foreach ($s in $skills) {
    $src = Join-Path $tmp "skills\$s"
    if (-not (Test-Path $src)) { throw "skill '$s' not found at $Sha" }
    $exe = Get-ChildItem $src -Recurse -File | Where-Object { $_.Extension -match '^\.(sh|ps1|py|js|cmd|bat|exe)$' }
    if ($exe) { throw "skill '$s' contains executable files: $($exe.Name -join ', ')" }
  }

  # Replace the vendored skills wholesale so upstream deletions come through
  $skillsDir = Join-Path $dest 'skills'
  if (Test-Path $skillsDir) { Remove-Item -Recurse -Force $skillsDir }
  New-Item -ItemType Directory -Force $skillsDir | Out-Null
  foreach ($s in $skills) {
    Copy-Item -Recurse (Join-Path $tmp "skills\$s") (Join-Path $skillsDir $s)
    Write-Host "  [vendored] $s"
  }
  Copy-Item (Join-Path $tmp 'LICENSE') (Join-Path $dest 'LICENSE') -Force

  $date = git -C $tmp log -1 --format=%cs
  $list = ($skills | ForEach-Object { "- $_" }) -join "`n"
  @"
# Vendored from chrisbanes/skills

- Source: https://github.com/chrisbanes/skills
- Commit: $Sha ($date)
- License: Apache-2.0 (see LICENSE). Copyright Chris Banes; unmodified copies.
- Refresh: ``setup/vendor-chrisbanes.ps1 -Sha <commit>``

Included skills:
$list
"@ | Set-Content -Path (Join-Path $dest 'VENDORED.md') -Encoding UTF8

  Write-Host "Vendored $($skills.Count) skills at $Sha"
}
finally {
  if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
}
