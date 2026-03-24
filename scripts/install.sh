#!/bin/bash
set -e

RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
WHITE="\033[1;37m"

REPO_URL="https://github.com/namearth5005/claude-french.git"
REPO_DIR="$HOME/.claude/french/repo"
SKILLS_DIR="$HOME/.claude/skills"
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

if command -v jq >/dev/null 2>&1; then
  ok "jq"
elif command -v python3 >/dev/null 2>&1; then
  ok "python3 (will use for JSON updates)"
else
  skip "jq/python3 not found (will need manual settings update)"
fi


step "Download"

if [ -d "$REPO_DIR/.git" ]; then
  note "Existing installation found, updating..."
  cd "$REPO_DIR" && git pull --ff-only --quiet 2>/dev/null
  ok "Updated to latest"
else
  mkdir -p "$REPO_DIR"
  git clone --quiet "$REPO_URL" "$REPO_DIR" 2>/dev/null
  ok "Downloaded to ~/.claude/french/repo/"
fi


step "Install skills"

mkdir -p "$SKILLS_DIR"

for skill_dir in "$REPO_DIR"/skills/*/; do
  skill_name=$(basename "$skill_dir")
  target="$SKILLS_DIR/$skill_name"

  if [ -L "$target" ]; then
    rm "$target"
  fi

  ln -sf "$skill_dir" "$target"
  ok "$skill_name"
done

note "Skills symlinked to ~/.claude/skills/"


step "Initialize data"

mkdir -p "$DATA_DIR"

if [ ! -f "$DATA_DIR/french_config.json" ]; then
  cp "$REPO_DIR/data/default_config.json" "$DATA_DIR/french_config.json"
  ok "Config created"
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
  cp "$REPO_DIR/data/starter_deck.json" "$DATA_DIR/french_flashcards.json"
  ok "50 beginner cards loaded"
else
  skip "Starter deck skipped"
fi


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
printf "  ${BOLD}Restart Claude Code${RESET}, then try:\n"
printf "\n"
printf "    ${CYAN}/french-settings${RESET}   Configure level, frequency, topics\n"
printf "    ${CYAN}/french${RESET}            Practice conversation, scenarios, drills\n"
printf "    ${CYAN}/flashcards${RESET}        Review cards with spaced repetition\n"
printf "\n"
printf "  ${DIM}Bonne chance ! 🇫🇷${RESET}\n"
printf "\n"
