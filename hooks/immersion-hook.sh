#!/bin/sh

CONFIG_FILE=""

for f in "$HOME/.claude/french/french_config.json" "$HOME"/.claude/projects/*/memory/french_config.json; do
  if [ -f "$f" ]; then
    CONFIG_FILE="$f"
    break
  fi
done

if [ -z "$CONFIG_FILE" ]; then
  exit 0
fi

FREQUENCY=""
LEVEL=""
MODE=""
FORMALITY=""
TOPICS=""

if command -v jq >/dev/null 2>&1; then
  FREQUENCY=$(jq -r '.frequency // "off"' "$CONFIG_FILE" 2>/dev/null)
  LEVEL=$(jq -r '.level // "beginner"' "$CONFIG_FILE" 2>/dev/null)
  MODE=$(jq -r '.mode // "technical-only-english"' "$CONFIG_FILE" 2>/dev/null)
  FORMALITY=$(jq -r '.formality // "casual"' "$CONFIG_FILE" 2>/dev/null)
  TOPICS=$(jq -r '(.topics // []) | join(",")' "$CONFIG_FILE" 2>/dev/null)
else
  FREQUENCY=$(sed -n 's/.*"frequency"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$CONFIG_FILE" | head -1)
  LEVEL=$(sed -n 's/.*"level"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$CONFIG_FILE" | head -1)
  MODE=$(sed -n 's/.*"mode"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$CONFIG_FILE" | head -1)
  FORMALITY=$(sed -n 's/.*"formality"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$CONFIG_FILE" | head -1)
  TOPICS=$(sed -n 's/.*"topics"[[:space:]]*:[[:space:]]*\[\([^]]*\)\].*/\1/p' "$CONFIG_FILE" | head -1 | sed 's/"//g; s/ //g')

  : "${FREQUENCY:=off}"
  : "${LEVEL:=beginner}"
  : "${MODE:=technical-only-english}"
  : "${FORMALITY:=casual}"
  : "${TOPICS:=}"
fi

if [ "$FREQUENCY" = "off" ]; then
  exit 0
fi

echo "French immersion is active. Load the french-immersion skill. User settings: level=${LEVEL}, frequency=${FREQUENCY}, mode=${MODE}, formality=${FORMALITY}, topics=${TOPICS}"
