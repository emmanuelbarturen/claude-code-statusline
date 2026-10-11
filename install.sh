#!/usr/bin/env bash
# Instala la statusline en ~/.claude y la registra en ~/.claude/settings.json
set -euo pipefail
command -v jq >/dev/null || { echo "Necesitas jq (brew install jq)"; exit 1; }
DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
mkdir -p ~/.claude
cp "$DIR/statusline.sh" ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
S=~/.claude/settings.json
[[ -f "$S" ]] || echo '{}' > "$S"
cp "$S" "$S.bak"
jq '. + {statusLine: {type: "command", command: "~/.claude/statusline.sh"}}' "$S.bak" > "$S"
echo "Listo: ~/.claude/statusline.sh instalado y registrado en $S (copia previa en $S.bak)."
echo "Reinicia Claude Code para verla."
