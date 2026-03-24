#!/bin/bash
set -e

GREEN="\033[0;32m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
BOLD="\033[1m"
RESET="\033[0m"

REPO_URL="https://github.com/nambouchara/claude-french.git"
INSTALL_DIR="$HOME/.claude/plugins/cache/claude-french/1.0.0"
DATA_DIR="$HOME/.claude/french"
SETTINGS_FILE="$HOME/.claude/settings.json"

info() {
  printf "${CYAN}%s${RESET}\n" "$1"
}

success() {
  printf "${GREEN}%s${RESET}\n" "$1"
}

warn() {
  printf "${YELLOW}%s${RESET}\n" "$1"
}

error() {
  printf "\033[0;31m%s${RESET}\n" "$1"
  exit 1
}

echo ""
printf "${BOLD}${CYAN}"
cat <<'BANNER'
╭─────────────────────────────────────────────╮
│  claude-french installer                    │
│  Learn French inside Claude Code            │
╰─────────────────────────────────────────────╯
BANNER
printf "${RESET}"
echo ""

info "Checking prerequisites..."

if ! command -v git >/dev/null 2>&1; then
  error "git is required but not installed. Please install git and try again."
fi
success "  git found"

info "Installing plugin..."

if [ -d "$INSTALL_DIR/.git" ]; then
  info "  Existing installation found, pulling latest..."
  cd "$INSTALL_DIR" && git pull --ff-only
else
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone "$REPO_URL" "$INSTALL_DIR"
fi
success "  Plugin cloned to $INSTALL_DIR"

info "Installing dependencies..."
cd "$INSTALL_DIR"
if command -v npm >/dev/null 2>&1; then
  npm install --production --silent 2>/dev/null
  success "  Dependencies installed"
else
  warn "  npm not found, skipping dependency install. Install Node.js for full functionality."
fi

info "Setting up user data..."

mkdir -p "$DATA_DIR"

if [ ! -f "$DATA_DIR/french_config.json" ]; then
  cp "$INSTALL_DIR/data/default_config.json" "$DATA_DIR/french_config.json"
  success "  Created french_config.json"
else
  warn "  french_config.json already exists, skipping"
fi

if [ ! -f "$DATA_DIR/french_flashcards.json" ]; then
  printf '{"cards": []}\n' > "$DATA_DIR/french_flashcards.json"
  success "  Created french_flashcards.json"
else
  warn "  french_flashcards.json already exists, skipping"
fi

if [ ! -f "$DATA_DIR/french_stats.json" ]; then
  printf '{"sessions": [], "streak": 0, "last_session": null}\n' > "$DATA_DIR/french_stats.json"
  success "  Created french_stats.json"
else
  warn "  french_stats.json already exists, skipping"
fi

echo ""
printf "${BOLD}Seed starter deck with 50 beginner flashcards? (y/n) ${RESET}"
read -r SEED_DECK
if [ "$SEED_DECK" = "y" ] || [ "$SEED_DECK" = "Y" ]; then
  cp "$INSTALL_DIR/data/starter_deck.json" "$DATA_DIR/french_flashcards.json"
  success "  Starter deck loaded!"
else
  info "  Skipped starter deck"
fi

info "Registering plugin in Claude settings..."

mkdir -p "$(dirname "$SETTINGS_FILE")"

if [ ! -f "$SETTINGS_FILE" ]; then
  printf '{\n  "enabledPlugins": {\n    "claude-french@nambouchara": true\n  }\n}\n' > "$SETTINGS_FILE"
  success "  Created settings.json with plugin enabled"
else
  if command -v jq >/dev/null 2>&1; then
    TEMP_FILE=$(mktemp)
    if jq '.enabledPlugins["claude-french@nambouchara"] = true' "$SETTINGS_FILE" > "$TEMP_FILE" 2>/dev/null; then
      mv "$TEMP_FILE" "$SETTINGS_FILE"
      success "  Plugin registered via jq"
    else
      rm -f "$TEMP_FILE"
      warn "  Could not update settings.json with jq, trying fallback..."
      if command -v python3 >/dev/null 2>&1; then
        python3 -c "
import json, sys
with open('$SETTINGS_FILE', 'r') as f:
    data = json.load(f)
if 'enabledPlugins' not in data:
    data['enabledPlugins'] = {}
data['enabledPlugins']['claude-french@nambouchara'] = True
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
" && success "  Plugin registered via python3" || warn "  Could not update settings.json automatically. Please add \"claude-french@nambouchara\": true to enabledPlugins in $SETTINGS_FILE"
      else
        warn "  Neither jq nor python3 found. Please add \"claude-french@nambouchara\": true to enabledPlugins in $SETTINGS_FILE"
      fi
    fi
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c "
import json, sys
with open('$SETTINGS_FILE', 'r') as f:
    data = json.load(f)
if 'enabledPlugins' not in data:
    data['enabledPlugins'] = {}
data['enabledPlugins']['claude-french@nambouchara'] = True
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
" && success "  Plugin registered via python3" || warn "  Could not update settings.json automatically. Please add \"claude-french@nambouchara\": true to enabledPlugins in $SETTINGS_FILE"
  else
    warn "  Neither jq nor python3 found. Please add \"claude-french@nambouchara\": true to enabledPlugins in $SETTINGS_FILE"
  fi
fi

echo ""
printf "${BOLD}${GREEN}"
cat <<'SUCCESS'
╭─ Installed! ────────────────────────────────╮
│                                             │
│  Try these commands in Claude Code:         │
│                                             │
│  /french-settings  — Configure preferences  │
│  /french           — Start practicing       │
│  /flashcards       — Review vocabulary      │
│                                             │
│  French immersion is ON by default.         │
│  Use /french-settings frequency off         │
│  to pause during focused work.              │
│                                             │
╰─────────────────────────────────────────────╯
SUCCESS
printf "${RESET}"
echo ""
