# Revisa docs/wiki/ con las reglas de Morelo Wiki y, si se pasa un rango de
# commits, que un cambio de código traiga su entrada en docs/wiki/cambios.md.
# Plantilla: morelo-wiki/plantillas-producto/scripts/verificar-wiki.ps1
#
#   pwsh scripts/verificar-wiki.ps1                       solo formato
#   pwsh scripts/verificar-wiki.ps1 -Base origin/main     formato + ¿falta la entrada?

param(
  [string]$Base = "",
  [string]$Cabeza = "HEAD",
  [string]$Evento = "",
  [string]$Etiquetas = ""
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$wiki = Join-Path $root "docs/wiki"
$ficha = Join-Path $wiki "ficha.md"
$cambios = Join-Path $wiki "cambios.md"
$errores = [System.Collections.Generic.List[string]]::new()
$avisos = [System.Collections.Generic.List[string]]::new()
$enActions = [bool]$env:GITHUB_ACTIONS

function Leer([string]$ruta) {
  ((Get-Content -Raw -Encoding utf8 $ruta) -replace "^﻿", "") -replace "`r", ""
}

# Quita bloques de código para no revisar ejemplos
function SinCodigo([string]$texto) {
  [regex]::Replace($texto, '(?ms)^(```|~~~).*?^\1[^\n]*$', '')
}

function RevisarComun([string]$nombre, [string]$texto) {
  $prosa = SinCodigo $texto
  $secretos = @(
    @{ p = '(?i)\b(password|pwd|passwd)\s*=\s*[^;\s`<{]{4,}'; d = 'contraseña en una cadena de conexión' },
    @{ p = 'ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}'; d = 'token de GitHub' },
    @{ p = '\bsk-[A-Za-z0-9_-]{20,}'; d = 'clave de API' },
    @{ p = 'AKIA[0-9A-Z]{16}'; d = 'clave de AWS' },
    @{ p = '-----BEGIN [A-Z ]*PRIVATE KEY-----'; d = 'clave privada' }
  )
  foreach ($s in $secretos) {
    if ($prosa -match $s.p) { $errores.Add("${nombre}: parece contener un secreto ($($s.d)). Quítalo y rota la clave si era real.") }
  }
  if ($prosa -match '(?<![\w/`])[A-Za-z]:\\[\w .\\-]+') {
    $avisos.Add("${nombre}: tiene una ruta de un PC ($($Matches[0])). Usa rutas del repo.")
  }

  # Medios locales referenciados que no existen en docs/wiki/
  foreach ($m in [regex]::Matches($prosa, '\]\((?:\./)?(media/[^)\s"#?]+)')) {
    $ruta = Join-Path $wiki ([uri]::UnescapeDataString($m.Groups[1].Value))
    if (-not (Test-Path $ruta)) { $errores.Add("${nombre}: no existe docs/wiki/$($m.Groups[1].Value)") }
  }
}

# ── ficha.md ────────────────────────────────────────────
if (-not (Test-Path $ficha)) {
  $errores.Add("Falta docs/wiki/ficha.md (la ficha que publica Morelo Wiki).")
} else {
  $t = Leer $ficha
  $primera = ($t -split "`n" | Where-Object { $_.Trim() } | Select-Object -First 1)
  if ($primera -notmatch '^# \S') { $errores.Add("ficha.md: la primera línea debe ser el título «# Nombre del producto».") }
  if ($t -notmatch '(?m)^\|\s*\*\*Estado\*\*\s*\|') { $errores.Add("ficha.md: falta la fila «| **Estado** | … |» en la tabla de la ficha.") }
  if ($t -notmatch '(?m)^\|\s*\*\*(Repo|Front|API)\*\*\s*\|') { $avisos.Add("ficha.md: falta la fila **Repo** (o **Front** / **API**).") }
  if ($t -notmatch '(?m)^\|\s*\*\*(Stack|Front|API)\*\*\s*\|') { $avisos.Add("ficha.md: falta la fila **Stack**.") }
  if ($t -notmatch '(?m)^\|\s*\*\*Última revisión\*\*\s*\|\s*\d{4}-\d{2}-\d{2}') { $avisos.Add("ficha.md: falta la fila **Última revisión** con fecha YYYY-MM-DD.") }
  RevisarComun "ficha.md" $t
}

# ── cambios.md ──────────────────────────────────────────
if (-not (Test-Path $cambios)) {
  $errores.Add("Falta docs/wiki/cambios.md (historial de cambios de la ficha).")
} else {
  $t = Leer $cambios
  $prosa = SinCodigo $t
  $fechaAnterior = $null
  $entradas = [regex]::Split($prosa, '(?m)^(?=## )') | Where-Object { $_ -match '^## ' }
  if (-not $entradas) { $avisos.Add("cambios.md: no tiene entradas «## YYYY-MM-DD — Título».") }
  foreach ($entrada in $entradas) {
    $titulo = ($entrada -split "`n")[0]
    if ($titulo -notmatch '^## (\d{4}-\d{2}-\d{2}) [—–-] \S') {
      $errores.Add("cambios.md: «$titulo» debe ser «## YYYY-MM-DD — Título» (la wiki arma la línea de tiempo con eso).")
      continue
    }
    $fecha = $Matches[1]
    if ($fechaAnterior -and $fecha -gt $fechaAnterior) {
      $errores.Add("cambios.md: «$titulo» está debajo de una entrada más antigua. Lo más reciente va arriba.")
    }
    $fechaAnterior = $fecha
    foreach ($parte in '**Antes:**', '**Ahora:**', '**Por qué importa:**') {
      if (-not $entrada.Contains($parte)) { $avisos.Add("cambios.md: «$titulo» no tiene $parte") }
    }
  }
  RevisarComun "cambios.md" $t
}

# ── ¿El cambio de código trae su entrada? ───────────────
$sinBase = -not $Base -or $Base -match '^0+$'
if (-not $sinBase) {
  git rev-parse --verify --quiet "$Base^{commit}" *> $null
  if ($LASTEXITCODE -ne 0) { $sinBase = $true; $avisos.Add("No encontré el commit base $Base; solo se revisó el formato.") }
}

if (-not $sinBase) {
  $archivos = @(git diff --name-only "$Base" "$Cabeza")
  $noCodigo = @(
    '^docs/', '\.mdx?$', '^\.github/', '^\.cursor/', '^\.claude/', '^\.agents/', '^\.codex/',
    '^\.opencode/', '^\.vscode/', '^\.idea/', '^openspec/', '^scripts/(sync|verificar)-wiki\.ps1$',
    '(^|/)(package-lock\.json|pnpm-lock\.yaml|yarn\.lock|bun\.lockb?|packages\.lock\.json)$',
    '^\.git(ignore|attributes)$', '^\.editorconfig$', '^LICENSE'
  )
  $codigo = @($archivos | Where-Object { $f = $_; -not ($noCodigo | Where-Object { $f -match $_ }) })
  $tocaCambios = $archivos -contains 'docs/wiki/cambios.md'

  if ($codigo.Count -gt 0 -and -not $tocaCambios) {
    $mensajes = (git log --format=%B "$Base..$Cabeza") -join "`n"
    $omitido = $mensajes -match '(?i)\[sin wiki\]' -or (($Etiquetas -split ',') -contains 'sin-wiki')
    $ejemplos = ($codigo | Select-Object -First 5) -join ', '
    $texto = "Cambian $($codigo.Count) archivo(s) de código ($ejemplos) y docs/wiki/cambios.md no tiene entrada nueva."
    if ($omitido) {
      Write-Host "Wiki: se omitió la entrada por «[sin wiki]» / etiqueta sin-wiki."
    } elseif ($Evento -eq 'pull_request') {
      $errores.Add("$texto Añade la entrada (skill documentar-wiki) o, si no cambia nada visible, etiqueta el PR «sin-wiki».")
    } else {
      $avisos.Add("$texto Documenta el cambio en el próximo commit.")
    }
  }
}

# ── Resultado ───────────────────────────────────────────
foreach ($a in $avisos) { if ($enActions) { Write-Host "::warning title=Wiki::$a" } else { Write-Host "AVISO  $a" } }
foreach ($e in $errores) { if ($enActions) { Write-Host "::error title=Wiki::$e" } else { Write-Host "ERROR  $e" } }

if ($errores.Count -gt 0) {
  Write-Host "Wiki: $($errores.Count) error(es), $($avisos.Count) aviso(s)."
  exit 1
}
Write-Host "Wiki: docs/wiki al día ($($avisos.Count) aviso(s))."
