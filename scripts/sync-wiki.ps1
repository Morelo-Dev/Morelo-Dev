# Sync wiki → morelo-wiki
# Copia docs/wiki/ (ficha, cambios y media/) al hub y deja un rastro de commit.
# Plantilla: morelo-wiki/plantillas-producto/scripts/sync-wiki.ps1

param(
  [string]$WikiRepo = "Morelo-Dev/morelo-wiki",
  [string]$ProjectSlug = "morelo-dev",
  [string]$WorkDir = ""
)

$ErrorActionPreference = "Stop"

function Sync-WikiRebase {
  param([string]$Slug)

  # En un rebase, --theirs es el commit de este producto y --ours es main ya actualizado.
  $propios = @(
    "docs/proyectos/$Slug.md",
    "docs/proyectos/$Slug-cambios.md"
  )

  git rebase origin/main
  if ($LASTEXITCODE -eq 0) { return $true }

  for ($paso = 1; $paso -le 30; $paso++) {
    $conflictos = @(git diff --name-only --diff-filter=U)
    if ($conflictos.Count -eq 0) { return $false }

    foreach ($ruta in $conflictos) {
      $norm = ($ruta -replace '\\', '/').Trim()
      if ($propios -contains $norm -or $norm -like "docs/proyectos/media/$Slug/*") {
        git checkout --theirs -- $ruta
      } else {
        git checkout --ours -- $ruta
      }
      if ($LASTEXITCODE -ne 0) { return $false }
      git add -- $ruta
      if ($LASTEXITCODE -ne 0) { return $false }
    }

    git -c core.editor=true rebase --continue
    if ($LASTEXITCODE -eq 0) { return $true }

    $estado = git status 2>&1 | Out-String
    if ($estado -match 'No changes|nothing to commit|no changes') {
      git rebase --skip
      if ($LASTEXITCODE -eq 0) { return $true }
    }
  }

  return $false
}

$token = $env:WIKI_SYNC_TOKEN
if (-not $token) { $token = $env:GITHUB_TOKEN }
if (-not $token) { $token = $env:GH_TOKEN }
if (-not $token) {
  Write-Error "Falta WIKI_SYNC_TOKEN (o GITHUB_TOKEN) con permiso write al repo morelo-wiki."
}

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$wikiSrc = Join-Path $root "docs/wiki"
$fichaSrc = Join-Path $wikiSrc "ficha.md"
$cambiosSrc = Join-Path $wikiSrc "cambios.md"
$mediaSrc = Join-Path $wikiSrc "media"

if (-not (Test-Path $fichaSrc)) { Write-Error "No existe $fichaSrc" }

$tmp = if ($WorkDir) { $WorkDir } else { Join-Path ([System.IO.Path]::GetTempPath()) "morelo-wiki-sync-$ProjectSlug" }
if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
New-Item -ItemType Directory -Path $tmp | Out-Null

$cloneUrl = "https://x-access-token:${token}@github.com/${WikiRepo}.git"
git clone --depth 1 --branch main $cloneUrl $tmp
if ($LASTEXITCODE -ne 0) { Write-Error "git clone failed" }

$destFicha = Join-Path $tmp "docs/proyectos/$ProjectSlug.md"
$destCambios = Join-Path $tmp "docs/proyectos/$ProjectSlug-cambios.md"
$destMedia = Join-Path $tmp "docs/proyectos/media/$ProjectSlug"

Copy-Item $fichaSrc $destFicha -Force
if (Test-Path $cambiosSrc) {
  Copy-Item $cambiosSrc $destCambios -Force
}

# Medios: espejo de docs/wiki/media/ (lo que se borra aquí se borra en la wiki)
if (Test-Path $destMedia) { Remove-Item $destMedia -Recurse -Force }
if (Test-Path $mediaSrc) {
  Get-ChildItem $mediaSrc -Recurse -File |
    Where-Object { $_.Extension -notin '.md', '.mdx' } |
    ForEach-Object {
      $relativo = [System.IO.Path]::GetRelativePath($mediaSrc, $_.FullName)
      $destino = Join-Path $destMedia $relativo
      New-Item -ItemType Directory -Force -Path (Split-Path $destino) | Out-Null
      Copy-Item $_.FullName $destino -Force
    }
}

Push-Location $tmp
try {
  git config user.name "morelo-wiki-sync[bot]"
  git config user.email "112214536+Morelo-Dev@users.noreply.github.com"
  git add -A -- "docs/proyectos"

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
    git fetch --depth=200 origin main
    if ($LASTEXITCODE -ne 0) { Start-Sleep -Seconds $intento; continue }
    if (-not (Sync-WikiRebase -Slug $ProjectSlug)) {
      $rebaseEnCurso = git rev-parse --git-path rebase-merge 2>$null
      if ($rebaseEnCurso -and (Test-Path $rebaseEnCurso)) { git rebase --abort }
      Start-Sleep -Seconds $intento
      continue
    }
  }
  if (-not $pushed) {
    git push origin main
    if ($LASTEXITCODE -eq 0) { $pushed = $true }
  }
  if (-not $pushed) { Write-Error "git push failed" }
  Write-Host "Wiki actualizada: $msg"
}
finally {
  Pop-Location
}
