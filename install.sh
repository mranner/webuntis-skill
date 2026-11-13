#!/bin/sh
# Verlinkt diesen Skill projektlokal nach <projekt>/.claude/skills/webuntis.
# Aufruf: sh install.sh /pfad/zum/projekt [/pfad/zum/projekt2 ...]
set -e
QUELLE="$(cd "$(dirname "$0")" && pwd)"

if [ $# -eq 0 ]; then
    echo "Aufruf: sh install.sh /pfad/zum/projekt [...]" >&2
    exit 1
fi

for PROJEKT in "$@"; do
    if [ ! -d "$PROJEKT" ]; then
        echo "Uebersprungen (kein Verzeichnis): $PROJEKT" >&2
        continue
    fi
    ZIEL="$PROJEKT/.claude/skills/webuntis"
    mkdir -p "$PROJEKT/.claude/skills"
    [ -e "$ZIEL" ] || [ -L "$ZIEL" ] && rm -rf "$ZIEL"
    ln -s "$QUELLE" "$ZIEL"
    echo "Verlinkt: $ZIEL -> $QUELLE"
done
