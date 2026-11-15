#!/usr/bin/env bash
# Comprueba los contadores SKILLS y AGENTES contra un transcript mínimo. Uso: tests/contadores.sh
set -eu
cd "$(dirname "$0")/.."
t=$(mktemp)
trap 'rm -f "$t"' EXIT

# 2 skills (ponytail por las dos vías cuenta una vez; /clear no cuenta) y 2 tipos de agente (uno sin tipo).
cat > "$t" <<'JSONL'
{"type":"assistant","message":{"content":[{"type":"tool_use","id":"a","name":"Skill","input":{"skill":"ponytail:ponytail"}}]}}
{"type":"user","message":{"content":"<command-message>ponytail:ponytail</command-message>\n<command-name>/ponytail:ponytail</command-name>"}}
{"type":"user","message":{"content":"<command-message>init</command-message>\n<command-name>/init</command-name>"}}
{"type":"user","message":{"content":"<command-name>/clear</command-name>\n            <command-message>clear</command-message>"}}
{"type":"assistant","message":{"content":[{"type":"tool_use","id":"b","name":"Agent","input":{"description":"x","prompt":"usa {llaves}","subagent_type":"Explore"}}]}}
{"type":"assistant","message":{"content":[{"type":"tool_use","id":"c","name":"Agent","input":{"description":"y","prompt":"sin tipo"}}]}}
{"type":"assistant","message":{"content":[{"type":"tool_use","id":"d","name":"Agent","input":{"description":"z","prompt":"otra vez","subagent_type":"Explore"}}]}}
JSONL

fila=$(jq -nc --arg t "$t" '{transcript_path:$t}' | bash statusline.sh | head -1 | sed $'s/\e\\[[0-9;]*m//g')
case "$fila" in
  *"SKILLS: 2 │ AGENTES: 2"*) echo "ok: $fila" ;;
  *) echo "FALLA: $fila"; exit 1 ;;
esac
