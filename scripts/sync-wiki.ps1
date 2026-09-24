# Sync wiki → morelo-wiki
# Copia docs/wiki/* al hub y deja un rastro de commit.

param(
  [string]$WikiRepo = "Morelo-Dev/morelo-wiki",
  [string]$ProjectSlug = "morelo-dev",
  [string]$WorkDir = ""
)

$ErrorActionPreference = "Stop"

$token = $env:WIKI_SYNC_TOKEN
if (-not $token) { $token = $env:GITHUB_TOKEN }
if (-not $token) { $token = $env:GH_TOKEN }
if (-not $token) {
  Write-Error "Falta WIKI_SYNC_TOKEN (o GITHUB_TOKEN) con permiso write al repo morelo-wiki."
}

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$wikiSrc = Join-Path $root "docs\wiki"
$fichaSrc = Join-Path $wikiSrc "ficha.md"
$cambiosSrc = Join-Path $wikiSrc "cambios.md"

if (-not (Test-Path $fichaSrc)) { Write-Error "No existe $fichaSrc" }

$tmp = if ($WorkDir) { $WorkDir } else { Join-Path ([System.IO.Path]::GetTempPath()) "morelo-wiki-sync-$ProjectSlug" }
if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
New-Item -ItemType Directory -Path $tmp | Out-Null

$cloneUrl = "https://x-access-token:${token}@github.com/${WikiRepo}.git"
git clone --depth 1 --branch main $cloneUrl $tmp
if ($LASTEXITCODE -ne 0) { Write-Error "git clone failed" }

$destFicha = Join-Path $tmp "docs\proyectos\$ProjectSlug.md"
$destCambios = Join-Path $tmp "docs\proyectos\$ProjectSlug-cambios.md"

Copy-Item $fichaSrc $destFicha -Force
if (Test-Path $cambiosSrc) {
  Copy-Item $cambiosSrc $destCambios -Force
}

Push-Location $tmp
try {
  git config user.name "morelo-wiki-sync[bot]"
  git config user.email "112214536+Morelo-Dev@users.noreply.github.com"
  git add "docs/proyectos/$ProjectSlug.md"
  if (Test-Path $destCambios) { git add "docs/proyectos/$ProjectSlug-cambios.md" }

  $status = git status --porcelain
  if (-not $status) {
    Write-Host "Sin cambios en la wiki."
    return
  }

  $msg = $env:SYNC_COMMIT_MESSAGE
  if ($msg) {
    $msg = ($msg -split "`n")[0].Trim()
    if ($msg.Length -gt 72) { $msg = $msg.Substring(0, 72).Trim() }
  }
  if (-not $msg) {
    $sha = $env:GITHUB_SHA
    if ($sha -and $sha.Length -ge 7) { $sha = $sha.Substring(0, 7) }
    $msg = "docs($ProjectSlug): sync ficha desde producto"
    if ($sha) { $msg = "$msg ($sha)" }
  }

  git commit -m $msg
  if ($LASTEXITCODE -ne 0) { Write-Error "git commit failed" }

  $pushed = $false
  for ($intento = 1; $intento -le 6; $intento++) {
    git push origin main
    if ($LASTEXITCODE -eq 0) { $pushed = $true; break }
    Write-Host "main de la wiki avanzó; reintento $intento"
    git fetch --depth=50 origin main
    if ($LASTEXITCODE -ne 0) { Start-Sleep -Seconds $intento; continue }
    git rebase origin/main
    if ($LASTEXITCODE -ne 0) {
      git rebase --abort
      Start-Sleep -Seconds $intento
      continue
    }
  }
  if (-not $pushed) { Write-Error "git push failed" }
  Write-Host "Wiki actualizada: $msg"
}
finally {
  Pop-Location
}
