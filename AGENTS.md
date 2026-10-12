# Reglas para agentes — Morelo-Dev

## Wiki sincronizada (obligatorio)

Este repo publica su ficha en Morelo Wiki desde `docs/wiki/`. Un cambio que altere comportamiento, API, datos, configuración, dependencias principales o deploy **no está terminado** hasta que:

1. `docs/wiki/ficha.md` describe el estado actual y su **Última revisión** tiene la fecha de hoy.
2. `docs/wiki/cambios.md` tiene una entrada nueva arriba: `## YYYY-MM-DD — Título` con **Antes**, **Ahora** y **Por qué importa**.
3. Los dos van en el mismo commit o PR que el código.

Cómo escribirla: skill `documentar-wiki` en `.cursor/skills/documentar-wiki/SKILL.md` (misma copia en `.claude/skills/documentar-wiki/` cuando el repo versiona `.claude/`).

- Escribe desde el código: nada que no exista hoy. Sin secretos ni rutas de tu PC.
- Capturas y clips en `docs/wiki/media/`. Nunca inventes capturas ni IDs de video: deja `> **Captura pendiente:** …`.
- Al llegar a `main` o `master`, el Action **Sync wiki** publica solo. No edites `morelo-wiki` ni Cloudflare a mano.
- El check **Wiki al día** falla en un PR que cambia código sin entrada en `cambios.md`. Si de verdad no aplica, etiqueta el PR `sin-wiki` o pon `[sin wiki]` en el commit.
- Commits con autor y committer `Morelo-Dev <112214536+Morelo-Dev@users.noreply.github.com>`, sin `Co-authored-by` ni trailers de agentes o IA.
- Una rama ya fusionada en `main` o `master` se borra en GitHub y en local (`git push origin --delete <rama>` y `git branch -d <rama>`), después de comprobar que no le quedan commits fuera de la rama principal.
