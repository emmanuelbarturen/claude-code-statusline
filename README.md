# claude-code-statusline

Statusline para [Claude Code](https://code.claude.com) en español, inspirada en la de PAI: tres filas con lo esencial de la sesión y nada más.

![Statusline de Claude Code](docs/statusline.png)

## Qué muestra

| Fila | Dato | De dónde sale |
|---|---|---|
| **TAREA** | Nombre de la sesión (`/rename`, `--name` o el título que genera Claude Code). Si no hay, la carpeta actual. | `session_name`, `workspace.current_dir` |
| **SKILLS / AGENTES** | Cuántos skills y subagentes distintos entraron al contexto en esta sesión. | Se cuentan en el transcript (`transcript_path`) |
| **CONTEXTO** | Barra de 40 celdas con semáforo: verde < 50 %, ámbar 50–79 %, rojo ≥ 80 %. Las marcas `◉` señalan los umbrales. | `context_window.used_percentage` |
| **USO** | Consumo de la ventana de 5 h y de la semana, con hora de reinicio (`HOY@15:00`, `MIÉ@13:00`). | `rate_limits.five_hour`, `rate_limits.seven_day` |
| **Modelo (effort)** | Modelo en uso y nivel de esfuerzo entre paréntesis. | `model.display_name`, `effort.level` |

## Requisitos

- Claude Code 2.1 o superior.
- `bash` y [`jq`](https://jqlang.github.io/jq/) (`brew install jq`).
- macOS o Linux. Terminal con soporte de color de 24 bits (iTerm2, WezTerm, Kitty, Ghostty, Terminal.app moderno).

## Instalación

### Opción 1: pídeselo a Claude Code

Abre Claude Code y pega este prompt:

```text
Instala esta statusline en mi Claude Code:

1. Verifica que jq esté instalado; si no, instálalo con brew.
2. Descarga https://raw.githubusercontent.com/emmanuelbarturen/claude-code-statusline/main/statusline.sh
   en ~/.claude/statusline.sh y dale permiso de ejecución.
3. Haz una copia de seguridad de ~/.claude/settings.json y añade (sin borrar lo que ya hay):
   "statusLine": { "type": "command", "command": "~/.claude/statusline.sh" }
4. Prueba el script con una entrada simulada:
   echo '{"model":{"display_name":"Opus"},"session_name":"prueba","context_window":{"used_percentage":25}}' | ~/.claude/statusline.sh
5. Muéstrame el resultado y confirma que settings.json sigue siendo JSON válido.
```

La statusline aparece al terminar ese turno o en la siguiente sesión.

### Opción 2: manual

```bash
git clone https://github.com/emmanuelbarturen/claude-code-statusline.git
cd claude-code-statusline
./install.sh
```

El instalador copia `statusline.sh` a `~/.claude/`, hace una copia de seguridad de `~/.claude/settings.json` y añade:

```json
"statusLine": { "type": "command", "command": "~/.claude/statusline.sh" }
```

Reinicia Claude Code y aparece. Para probarla sin abrir Claude Code:

```bash
./preview.sh
```

## Banda sobre el prompt (opcional)

Un mod de Claude Code que dibuja una fila encima del prompt con la carpeta en la que trabaja la sesión y, a la derecha, la rama de git. Complementa la statusline: no la reemplaza.

```text
📁 ~/Sites/mi-proyecto                                     rama:main
```

Para instalarla, escribe esto en el prompt de Claude Code:

```text
/plugin install statusline-banda --marketplace emmanuelbarturen/claude-code-statusline
```

Responde `y` para añadir el marketplace y elige el alcance.

| Comando | Qué hace |
|---|---|
| `/banda off` | Oculta la banda. La elección se recuerda entre sesiones. |
| `/banda on` | La vuelve a mostrar. |
| `/banda` | Alterna entre oculta y visible. |

- La ruta dentro de tu carpeta personal se abrevia con `~`; si no cabe, se corta por el inicio.
- Sigue a la carpeta cuando cambia (`/cd` o un `cd` dentro de un turno).
- La rama solo aparece si la carpeta está dentro de un repositorio de git. Se actualiza al iniciar la sesión, al cambiar de carpeta y al terminar cada turno.
- Se dibuja en la terminal, la app de escritorio y el móvil; no en el panel de VS Code.
- Probada en Claude Code 2.1.325. El código está en [`banda/`](banda/) y sus pruebas corren con `claude plugin test banda`.

## Personalización

Todos los colores están al inicio de `statusline.sh`, en el bloque `# ---------- colores ----------`. Cada variable es una secuencia ANSI; las de 24 bits tienen la forma `\e[38;2;R;G;Bm`.

Otros ajustes rápidos:

- **Ancho de la barra**: `cells=40` dentro de la función `bar`.
- **Umbrales del semáforo**: la función `level_color` y las marcas `i == 20` / `i == 32` en `bar`.
- **Idioma de los días**: el array `names` en `fmt_reset`.

## Limitaciones

- La fila **USO** solo se llena en cuentas Pro o Max, que son las que reciben `rate_limits`. En otras cuentas muestra `USO: —`.
- **SKILLS** cuenta skills distintos, entren por la herramienta `Skill` o tecleados como `/nombre`. Los comandos internos (`/clear`, `/model`) no cuentan.
- **AGENTES** cuenta tipos distintos de subagente, no lanzamientos; uno lanzado sin tipo cuenta como `general-purpose`.
- Si Claude Code todavía no escribió el transcript de la sesión, los dos contadores quedan en 0.

## Licencia

MIT.
