#!/bin/bash
set -e

RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
WHITE="\033[1;37m"
BG_GREEN="\033[42m"
BG_BLUE="\033[44m"

REPO_URL="https://github.com/namearth5005/claude-french.git"
INSTALL_DIR="$HOME/.claude/plugins/cache/namearth5005/claude-french/1.0.0"
DATA_DIR="$HOME/.claude/french"
SETTINGS_FILE="$HOME/.claude/settings.json"

step_num=0
total_steps=5

step() {
  step_num=$((step_num + 1))
  printf "\n${DIM}─────────────────────────────────────────────────${RESET}\n"
  printf "${WHITE}  [${step_num}/${total_steps}]  %s${RESET}\n" "$1"
  printf "${DIM}─────────────────────────────────────────────────${RESET}\n"
}

ok() {
  printf "  ${GREEN}✓${RESET}  %s\n" "$1"
}

skip() {
  printf "  ${DIM}–${RESET}  ${DIM}%s${RESET}\n" "$1"
}

fail() {
  printf "  ${RED}✗${RESET}  %s\n" "$1"
  exit 1
}

note() {
  printf "  ${DIM}%s${RESET}\n" "$1"
}

clear
printf "\n"
printf "${BOLD}${BLUE}"
cat <<'ART'
         ┌─────────────────────────────────┐
         │                                 │
         │    🇫🇷  claude-french            │
         │                                 │
         │    Learn French inside          │
         │    Claude Code                  │
         │                                 │
         └─────────────────────────────────┘
ART
printf "${RESET}"
printf "\n"
printf "  ${DIM}Passive immersion · Active practice · Anki flashcards${RESET}\n"
printf "  ${DIM}github.com/namearth5005/claude-french${RESET}\n"


step "Prerequisites"

if ! command -v git >/dev/null 2>&1; then
  fail "git is required. Install it and try again."
fi
ok "git"

if command -v npm >/dev/null 2>&1; then
  ok "npm"
  HAS_NPM=true
else
  skip "npm not found (optional — needed for full FSRS support)"
  HAS_NPM=false
fi

if command -v jq >/dev/null 2>&1; then
  ok "jq"
elif command -v python3 >/dev/null 2>&1; then
  ok "python3 (will use for JSON updates)"
else
  skip "jq/python3 not found (will need manual settings update)"
fi


step "Install plugin"

if [ -d "$INSTALL_DIR/.git" ]; then
  note "Existing installation found, updating..."
  cd "$INSTALL_DIR" && git pull --ff-only --quiet 2>/dev/null
  ok "Updated to latest"
else
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone --quiet "$REPO_URL" "$INSTALL_DIR" 2>/dev/null
  ok "Cloned to ~/.claude/plugins/cache/claude-french/"
fi

if [ "$HAS_NPM" = true ]; then
  cd "$INSTALL_DIR"
  npm install --production --silent 2>/dev/null
  ok "Dependencies installed"
fi


step "Initialize data"

mkdir -p "$DATA_DIR"

if [ ! -f "$DATA_DIR/french_config.json" ]; then
  cp "$INSTALL_DIR/data/default_config.json" "$DATA_DIR/french_config.json"
  ok "Config created at ~/.claude/french/"
else
  skip "Config already exists"
fi

if [ ! -f "$DATA_DIR/french_flashcards.json" ]; then
  printf '{"cards": []}\n' > "$DATA_DIR/french_flashcards.json"
  ok "Flashcard deck initialized"
else
  skip "Flashcard deck already exists"
fi

if [ ! -f "$DATA_DIR/french_stats.json" ]; then
  printf '{"sessions": []}\n' > "$DATA_DIR/french_stats.json"
  ok "Stats file initialized"
else
  skip "Stats file already exists"
fi

SEED_DECK="y"
if [ -t 0 ]; then
  printf "\n  ${BOLD}Seed 50 beginner flashcards?${RESET} ${DIM}(Y/n)${RESET} "
  read -r SEED_DECK
  SEED_DECK="${SEED_DECK:-y}"
else
  note "Non-interactive mode — auto-seeding starter deck"
fi

if [ "$SEED_DECK" = "y" ] || [ "$SEED_DECK" = "Y" ] || [ "$SEED_DECK" = "" ]; then
  cp "$INSTALL_DIR/data/starter_deck.json" "$DATA_DIR/french_flashcards.json"
  ok "50 beginner cards loaded"
else
  skip "Starter deck skipped"
fi


step "Register plugin"

mkdir -p "$(dirname "$SETTINGS_FILE")"

register_plugin() {
  if [ ! -f "$SETTINGS_FILE" ]; then
    printf '{\n  "enabledPlugins": {\n    "claude-french@namearth5005": true\n  }\n}\n' > "$SETTINGS_FILE"
    ok "Created settings.json with plugin enabled"
    return 0
  fi

  if command -v jq >/dev/null 2>&1; then
    TEMP_FILE=$(mktemp)
    if jq '.enabledPlugins["claude-french@namearth5005"] = true' "$SETTINGS_FILE" > "$TEMP_FILE" 2>/dev/null; then
      mv "$TEMP_FILE" "$SETTINGS_FILE"
      ok "Plugin registered in settings.json"
      return 0
    fi
    rm -f "$TEMP_FILE"
  fi

  if command -v python3 >/dev/null 2>&1; then
    python3 -c "
import json
with open('$SETTINGS_FILE', 'r') as f:
    data = json.load(f)
if 'enabledPlugins' not in data:
    data['enabledPlugins'] = {}
data['enabledPlugins']['claude-french@namearth5005'] = True
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
" 2>/dev/null && ok "Plugin registered in settings.json" && return 0
  fi

  printf "\n"
  printf "  ${YELLOW}Manual step needed:${RESET}\n"
  printf "  Add this to ${BOLD}~/.claude/settings.json${RESET} under enabledPlugins:\n"
  printf "  ${DIM}\"claude-french@namearth5005\": true${RESET}\n"
  return 0
}

register_plugin


step "Done"

printf "\n"
printf "${BOLD}${GREEN}"
cat <<'DONE'
  ╭───────────────────────────────────────────────╮
  │                                               │
  │   ✓  claude-french installed successfully     │
  │                                               │
  ╰───────────────────────────────────────────────╯
DONE
printf "${RESET}"
printf "\n"
printf "  ${BOLD}Commands${RESET}\n"
printf "\n"
printf "    ${CYAN}/french-settings${RESET}   Configure level, frequency, topics\n"
printf "    ${CYAN}/french${RESET}            Practice conversation, scenarios, drills\n"
printf "    ${CYAN}/flashcards${RESET}        Review cards with spaced repetition\n"
printf "\n"
printf "  ${DIM}French immersion is ${RESET}${GREEN}ON${RESET}${DIM} by default.${RESET}\n"
printf "  ${DIM}Pause anytime: ${RESET}/french-settings frequency off\n"
printf "\n"
printf "  ${DIM}Bonne chance ! 🇫🇷${RESET}\n"
printf "\n"
