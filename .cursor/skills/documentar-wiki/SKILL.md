---
name: documentar-wiki
description: >-
  Crea o actualiza la ficha y el historial de cambios de este producto en Morelo
  Wiki (docs/wiki/) a partir del código. Úsalo siempre que un cambio afecte
  comportamiento, API, datos, configuración, dependencias principales o deploy,
  y cuando pidan documentar, actualizar la wiki, la ficha o cambios.md, hacer
  commit, proteger cambios o abrir un PR.
---

# documentar-wiki

Morelo Wiki publica lo que hay en `docs/wiki/` de este repo:

| Archivo                | Qué es                                                            |
| ---------------------- | ----------------------------------------------------------------- |
| `docs/wiki/ficha.md`   | El producto **hoy**: qué hace, cómo se arranca, cómo se despliega |
| `docs/wiki/cambios.md` | Historial: qué había antes, qué hay ahora y por qué importa       |
| `docs/wiki/media/`     | Capturas y clips cortos que usan los dos archivos                 |

Un push a `main` o `master` que toque `docs/wiki/**` lo publica solo (Action **Sync wiki**). No edites `morelo-wiki` ni Cloudflare a mano.

**Escribe desde el código.** Todo lo que diga la ficha se tiene que poder comprobar en el repo: comandos, rutas, variables, ramas y servicios que existen hoy. Lo viejo de la ficha solo vale si el código lo confirma.

## Cuándo es obligatorio

| Cambio                                             | `ficha.md`           | `cambios.md`                                                  |
| -------------------------------------------------- | -------------------- | ------------------------------------------------------------- |
| Comportamiento visible, flujo, pantalla o endpoint | Sección afectada     | Entrada nueva                                                 |
| Modelo de datos o migración                        | Arquitectura         | Entrada nueva                                                 |
| Comandos, scripts o variables de entorno           | Arranque / Variables | Entrada nueva                                                 |
| Deploy, hosting, dominio o rama principal          | Tabla + Deploy       | Entrada nueva                                                 |
| Stack o dependencia principal                      | Fila **Stack**       | Entrada nueva                                                 |
| Decisión difícil de revertir                       | Decisiones           | Entrada nueva                                                 |
| Refactor sin efecto, estilos, tests, typos         | No                   | No (`[sin wiki]` en el commit o etiqueta `sin-wiki` en el PR) |

La documentación va **en el mismo commit o PR** que el código. Un cambio sin su entrada no está terminado.

## Antes de escribir

1. Lee el diff (`git diff`, o `git log` desde la fecha de la última entrada de `cambios.md`).
2. Si `ficha.md` ya existe, edítala. No abras otro archivo ni dupliques secciones.
3. Ubica en el código cada cosa que vas a afirmar.

## Estructura de `ficha.md`

En este orden. Quita las secciones que no apliquen; no dejes «…» ni «pendiente» vacíos.

```md
# Nombre del producto

Una o dos frases: qué es, para quién y qué problema resuelve.

|                     |                                                                     |
| ------------------- | ------------------------------------------------------------------- |
| **Estado**          | Activo · Piloto · En pausa · Archivado                              |
| **Repo**            | [Morelo-Dev/repo](https://github.com/Morelo-Dev/repo) · rama `main` |
| **Stack**           | Tecnologías principales separadas por « · »                         |
| **Deploy**          | Dónde corre y su URL                                                |
| **Última revisión** | YYYY-MM-DD                                                          |

> **Cambios recientes:** [qué es nuevo respecto al estado anterior](cambios.md)

## Demo

## Qué hace

## Arquitectura

## Arranque local

## Variables de entorno

## Deploy

## Decisiones

## Fallos comunes

## Dónde se documenta
```

- **Tabla:** `Estado` es obligatoria (sin ella el CI falla). `Repo`, `Stack` y `Última revisión` también se piden; la wiki las muestra en el inicio. Si front y API viven en repos distintos, usa filas **Front** y **API** (`[repo](url) · stack · URL`).
- **Demo:** un video (enlace solo en su línea) o capturas de `media/`. Si aún no hay: `> **Demo pendiente:** qué debe mostrar.`
- **Qué hace:** solo lo implementado. Viñetas por capacidad; tabla solo para comparar roles o superficies.
- **Arquitectura:** piezas, datos e integraciones. Nombres reales de proyectos, carpetas y servicios.
- **Arranque local:** comandos copiables en bloques ` ```bash `, uno por línea, que existan en `package.json`, `Makefile`, `.csproj` o similar.
- **Variables de entorno:** tabla `Variable | Para qué | Dónde se define`. Solo nombres, nunca valores.
- **Deploy:** cómo se publica, desde qué rama y qué se revisa después.
- **Decisiones:** ADR cortos: `### YYYY-MM-DD — Título` con **Contexto**, **Decisión** y **Consecuencia**.
- **Fallos comunes:** tabla `Síntoma | Causa | Arreglo` con errores que pasaron de verdad.

## Entrada de `cambios.md`

```md
## YYYY-MM-DD — Título corto en presente

**Antes:** cómo era.

**Ahora:**

- qué cambió (una viñeta por cambio visible)

**Por qué importa:** para quién y qué resuelve.

---
```

- Va **arriba**, debajo del encabezado del archivo: lo más reciente primero.
- El título exacto `## YYYY-MM-DD — Título` (con raya «—») es obligatorio: la wiki arma con él la línea de tiempo y el pulso del inicio, y el CI lo revisa.
- Pon la misma fecha en **Última revisión** de la ficha.

## Cómo se escribe

- Español, en presente, frases cortas y concretas. Primero lo que importa.
- Prosa para el contexto, lista numerada solo para pasos que se siguen en orden, viñetas para opciones o capacidades. No conviertas todo en una sola lista.
- Comandos, rutas, variables, ramas y nombres de archivo en `código`.
- Avisos con cita: `> **Nota:**`, `> **Importante:**` (borra datos, afecta a otros o no se puede deshacer), `> **Advertencia:**`.
- Enlaces: a otras fichas con la ruta de la wiki (`/proyectos/slug`); a webs, con `https://`. La ficha se lee sola: no mandes a «abrir el archivo X del repo» en lugar de explicarlo.
- **Nunca**: secretos, cadenas de conexión, tokens, correos personales ni rutas de un PC (`C:\…`, `D:\…`). El CI falla si detecta un secreto.

## Imágenes y video

- Capturas y clips en `docs/wiki/media/`, en minúsculas y con guiones: `media/pedido-confirmado.png`. Videos propios cortos (MP4/WebM, menos de 25 MB); lo largo, en YouTube no listado, Loom, Vimeo o Drive.
- Imagen: `![Qué se ve](media/archivo.png "Pie opcional")`. El texto alternativo describe lo que se ve, no «captura 1».
- Video de YouTube, Vimeo, Loom o Drive: el enlace **solo en su línea** se ve como reproductor. Varios videos: una lista `- [Título](url) — descripción` se ve como lista de reproducción. Clip propio: `![Título](media/demo.mp4)`.
- **No inventes** capturas, diagramas de pantallas ni IDs de video, y no los generes con IA: salen de la app corriendo. Si falta: `> **Captura pendiente:** pantalla, qué debe verse y nombre previsto (media/x.png).`

## Antes del commit

1. ¿La ficha describe el estado actual, sin funciones que no existan?
2. ¿Hay entrada nueva arriba en `cambios.md` con el título exacto?
3. ¿**Última revisión** tiene la fecha de hoy?
4. ¿Los comandos, rutas y variables que nombras existen en el repo?
5. ¿Sin secretos ni rutas locales?
6. ¿Las imágenes existen en `docs/wiki/media/` y los videos van en su propia línea?
7. `pwsh scripts/verificar-wiki.ps1` termina sin errores.

## Commit y publicación

- Mismo commit o PR que el código; si no, un commit `docs(wiki): …` justo después.
- Autor y committer: `Morelo-Dev <112214536+Morelo-Dev@users.noreply.github.com>` (`--author` y `GIT_COMMITTER_NAME` / `GIT_COMMITTER_EMAIL`). No cambies `git config`.
- Nunca `Co-authored-by`, `--trailer` ni firmas de agentes o IA en commits y PR.
- Push solo si lo pidieron. Al llegar a `main` o `master`, **Sync wiki** publica la ficha; en cada PR, **Wiki al día** revisa que esté al día.
- Una rama ya fusionada en `main` o `master` se borra en GitHub y en local (`git push origin --delete <rama>` y `git branch -d <rama>`), después de comprobar que no le quedan commits fuera de la rama principal.
