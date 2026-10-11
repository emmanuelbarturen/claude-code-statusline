#!/usr/bin/env bash
# Statusline de Claude Code — estilo PAI, etiquetas en español.
# Lee el JSON que Claude Code pasa por stdin y dibuja 3 filas + 2 separadores:
#   TAREA · SKILLS · AGENTES
#   CONTEXTO (barra semáforo)
#   USO 5H · SEMANA · modelo (effort)
set -u

# ---------- colores ----------
C_CYAN=$'\e[36m'
C_BLUE=$'\e[94m'
C_WHITE=$'\e[97m'
C_BOLD=$'\e[1m'
C_DIM=$'\e[90m'
C_GREEN=$'\e[38;5;82m'
C_AMBER=$'\e[38;5;214m'
C_RED=$'\e[38;5;203m'
C_RESET=$'\e[0m'
C_TAREA=$'\e[38;2;57;102;217m'     # palabra TAREA
C_LABEL2=$'\e[38;2;151;163;185m'   # SKILLS, AGENTES, 5H, SEMANA
C_AT=$'\e[38;2;78;86;95m'          # la @ de las horas
C_CONTEXTO=$'\e[38;2;176;183;242m' # palabra CONTEXTO

# ---------- entrada ----------
input=$(cat)
model="" effort="" session_name="" cur_dir="" ctx_pct="0"
fh_pct="" fh_reset="" sd_pct="" sd_reset="" transcript=""

IFS=$'\x1f' read -r model effort session_name cur_dir ctx_pct fh_pct fh_reset sd_pct sd_reset transcript < <(
  printf '%s' "$input" | jq -r '[
    (.model.display_name // ""),
    (.effort.level // ""),
    (.session_name // ""),
    (.workspace.current_dir // .cwd // ""),
    (.context_window.used_percentage // 0),
    (.rate_limits.five_hour.used_percentage // ""),
    (.rate_limits.five_hour.resets_at // ""),
    (.rate_limits.seven_day.used_percentage // ""),
    (.rate_limits.seven_day.resets_at // ""),
    (.transcript_path // "")
  ] | map(tostring) | join("\u001f")' 2>/dev/null
) || true

# ---------- ancho ----------
cols=${COLUMNS:-80}
[[ "$cols" =~ ^[0-9]+$ ]] || cols=80
(( cols < 40 )) && cols=80
(( cols > 120 )) && cols=120

# ---------- helpers ----------
to_int() {            # "27.4" -> 27 ; "" -> 0
  local v=${1:-0}
  v=${v%%.*}
  [[ "$v" =~ ^[0-9]+$ ]] || v=0
  printf '%s' "$v"
}

level_color() {       # semáforo por porcentaje
  local p; p=$(to_int "$1")
  if   (( p < 50 )); then printf '%s' "$C_GREEN"
  elif (( p < 80 )); then printf '%s' "$C_AMBER"
  else                    printf '%s' "$C_RED"
  fi
}

pct_colored() {       # "27" -> 27% en su color
  local p; p=$(to_int "$1")
  printf '%s%s%%%s' "$(level_color "$p")" "$p" "$C_RESET"
}

bar() {               # 40 celdas, marcas en 50% (20) y 80% (32)
  local p; p=$(to_int "$1")
  local cells=40 filled i out="" col
  filled=$(( (p * cells + 50) / 100 ))
  (( filled > cells )) && filled=$cells
  col=$(level_color "$p")
  for (( i = 0; i < cells; i++ )); do
    if   (( i < filled )); then out+="${col}●"
    elif (( i == 20 ));    then out+="${C_AMBER}◉"
    elif (( i == 32 ));    then out+="${C_RED}◉"
    else                        out+="${C_DIM}○"
    fi
  done
  printf '%s%s' "$out" "$C_RESET"
}

fmt_reset() {         # epoch -> HOY@HH:MM | MIÉ@HH:MM
  local e=${1:-}
  [[ "$e" =~ ^[0-9]+$ ]] || { printf ''; return; }
  local day hhmm dow today
  if day=$(date -r "$e" +%Y-%m-%d 2>/dev/null); then
    hhmm=$(date -r "$e" +%H:%M); dow=$(date -r "$e" +%u)
  else
    day=$(date -d "@$e" +%Y-%m-%d 2>/dev/null) || { printf ''; return; }
    hhmm=$(date -d "@$e" +%H:%M); dow=$(date -d "@$e" +%u)
  fi
  today=$(date +%Y-%m-%d)
  if [[ "$day" == "$today" ]]; then
    printf 'HOY%s@%s%s' "$C_AT" "$C_AMBER" "$hhmm"
  else
    local names=(LUN MAR MIÉ JUE VIE SÁB DOM)
    printf '%s%s@%s%s' "${names[$((dow - 1))]}" "$C_AT" "$C_AMBER" "$hhmm"
  fi
}

sep_line() {
  local i out=""
  for (( i = 0; i < cols; i++ )); do out+="┈"; done
  printf '%s%s%s' "$C_DIM" "$out" "$C_RESET"
}

# ---------- skills / agentes de la sesión ----------
skills=0 agents=0
if [[ -n "$transcript" && -r "$transcript" ]]; then
  skills=$(grep -o '"name":"Skill","input":{[^}]*}' "$transcript" 2>/dev/null \
           | grep -o '"skill":"[^"]*"' | sort -u | wc -l | tr -d ' ')
  agents=$(grep -o '"subagent_type":"[^"]*"' "$transcript" 2>/dev/null \
           | sort -u | wc -l | tr -d ' ')
fi

# ---------- fila 1: tarea ----------
task=$session_name
[[ -z "$task" && -n "$cur_dir" ]] && task=$(basename "$cur_dir")
[[ -z "$task" ]] && task="—"
tail1=" │ SKILLS: ${skills} │ AGENTES: ${agents}"
max_task=$(( cols - 7 - ${#tail1} ))
(( max_task < 8 )) && max_task=8
if (( ${#task} > max_task )); then task="${task:0:max_task-1}…"; fi

row1="${C_TAREA}TAREA:${C_RESET} ${C_BOLD}${C_WHITE}${task}${C_RESET}"
row1+="${C_DIM} │ ${C_LABEL2}SKILLS:${C_RESET} ${C_WHITE}${skills}${C_RESET}"
row1+="${C_DIM} │ ${C_LABEL2}AGENTES:${C_RESET} ${C_WHITE}${agents}${C_RESET}"

# ---------- fila 2: contexto ----------
row2="${C_CONTEXTO}CONTEXTO:${C_RESET} $(bar "$ctx_pct")  $(pct_colored "$ctx_pct")"

# ---------- fila 3: uso + modelo ----------
row3="${C_CYAN}USO:${C_RESET} "
if [[ -z "$fh_pct" && -z "$sd_pct" ]]; then
  row3+="${C_DIM}—${C_RESET}"
else
  parts=()
  if [[ -n "$fh_pct" ]]; then
    r=$(fmt_reset "$fh_reset")
    parts+=("${C_LABEL2}5H:${C_RESET} $(pct_colored "$fh_pct")${r:+ ${C_AMBER}↻${r}${C_RESET}}")
  fi
  if [[ -n "$sd_pct" ]]; then
    r=$(fmt_reset "$sd_reset")
    parts+=("${C_LABEL2}SEMANA:${C_RESET} $(pct_colored "$sd_pct")${r:+ ${C_AMBER}↻${r}${C_RESET}}")
  fi
  joined=""
  for p in "${parts[@]}"; do
    [[ -n "$joined" ]] && joined+="${C_DIM} │ ${C_RESET}"
    joined+="$p"
  done
  row3+="$joined"
fi
if [[ -n "$model" ]]; then
  row3+="${C_DIM} │ ${C_RESET}${C_BLUE}${model}${C_RESET}"
  [[ -n "$effort" ]] && row3+=" ${C_DIM}(${effort})${C_RESET}"
fi

printf '%s\n' "$row1" "$(sep_line)" "$row2" "$(sep_line)" "$row3"
exit 0
