# claude-french

**Learn French inside Claude Code.**

A Claude Code plugin that teaches French through passive immersion, active practice, and Anki-powered flashcards -- all without leaving your terminal.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code Plugin](https://img.shields.io/badge/Claude_Code-Plugin-blueviolet.svg)](https://github.com/nambouchara/claude-french)

---

## What It Looks Like

### Passive immersion while you code

French phrases appear naturally in Claude's responses. Technical explanations stay in English.

```
You: Fix the null check bug in auth.ts

Claude: I found the issue -- a missing null check on line 42.

--- fr ------------------------------------------------
  C'est regle (It's fixed) -- the auth flow works now.
-------------------------------------------------------
```

### Flashcard review with spaced repetition

```
╭─────────────────────────────────────────────╮
│  FLASHCARD  3/12          ○ ○ ● ○ ○ ○ ○ ○  │
├─────────────────────────────────────────────┤
│                                             │
│          Comment ca va ?                    │
│                                             │
│  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  │
│  How are you?                    [beginner] │
│                                             │
│  Last seen: 3 days ago    Streak: ●●●○○     │
╰─────────────────────────────────────────────╯
  (1) Again  (2) Hard  (3) Good  (4) Easy
```

### Full settings dashboard

```
╭─ French Immersion Settings ─────────────────╮
│                                             │
│  Level       ●○○  beginner                  │
│  Frequency   ●●○  medium                    │
│  Mode        technical-only-english         │
│  Topics      food, travel, greetings        │
│  Formality   casual (tu)                    │
│  Direction   french -> english              │
│  New cards   10/day                         │
│                                             │
╰─────────────────────────────────────────────╯
```

---

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/nambouchara/claude-french/main/scripts/install.sh | bash
```

The installer will:

1. Clone the plugin to `~/.claude/plugins/cache/claude-french/`
2. Install the `ts-fsrs` dependency (spaced repetition engine)
3. Create your config and data files at `~/.claude/french/`
4. Optionally seed your deck with 50 beginner flashcards
5. Register the plugin in your Claude Code settings

---

## Quick Start

1. **Install** the plugin with the command above
2. **Open Claude Code** in any project
3. **Run `/french-settings`** to see your configuration dashboard
4. **Run `/french`** to start a practice session -- conversation, scenarios, or drills
5. **Run `/flashcards`** to review vocabulary with spaced repetition
6. **Start coding** -- French phrases will appear naturally in Claude's responses

That's it. No setup, no accounts, no browser tabs. French finds you while you work.

---

## Features

### Passive Immersion

French phrases are woven into Claude's normal coding responses -- greetings, transitions, affirmations. Every phrase includes a translation at beginner level.

```
I found the config issue. *Parfait* (Perfect) -- here's the fix.
```

```
*Alors* (So), let me check that test output.
```

Immersion respects your work. Technical explanations, error messages, and debugging sessions stay in pure English when you're using the default `technical-only-english` mode.

New phrases encountered during immersion are silently saved to your flashcard deck for later review.

### Active Practice (`/french`)

Three practice modes, accessible through a single command.

```
╭─ French Practice ───────────────────────────╮
│                                             │
│  (1)  Conversation libre                    │
│  (2)  Scenario -- Au cafe                   │
│  (3)  Vocabulary drills                     │
│  (4)  Review flashcards                     │
│                                             │
│  Cards due: 8    Streak: 3 days             │
╰─────────────────────────────────────────────╯
```

**Conversation Libre** -- Open-ended French conversation. Claude corrects grammar mistakes inline, introduces new vocabulary, and adjusts complexity to your level.

```
╭─ Correction ────────────────────────────────╮
│  "je va bien" -> "je vais bien"             │
│  (aller uses "vais" with je)                │
╰─────────────────────────────────────────────╯
```

**Scenarios** -- 10 built-in role-play scenarios across food, travel, shopping, and social situations. Order coffee at a Parisian cafe, buy a train ticket at Gare du Nord, or introduce yourself at a gathering. Claude stays in character while gently correcting mistakes.

**Vocabulary Drills** -- 10-question quizzes drawn from your flashcard deck. Due cards are prioritized. Difficulty adjusts based on your answers.

```
╭─ Drill Complete ────────────────────────────╮
│                                             │
│  Score: 8/10 (80%)                          │
│  Missed: le poulet, la salade               │
│                                             │
╰─────────────────────────────────────────────╯
```

### Flashcards (`/flashcards`)

A full spaced repetition system using FSRS -- the same algorithm that powers Anki. Cards are scheduled based on how well you know them: words you struggle with appear more often, words you know well fade into longer intervals.

| Command | What it does |
|---------|-------------|
| `/flashcards` | Start a review session with all due cards |
| `/flashcards add bonjour / hello` | Add a card manually |
| `/flashcards stats` | View deck statistics |

```
╭─ Session Complete ──────────────────────────╮
│                                             │
│  Reviewed    12 cards                       │
│  Correct     10  (83%)                      │
│  New         4  cards learned               │
│  Total deck  62 cards                       │
│  Due tomorrow 6                             │
│                                             │
╰─────────────────────────────────────────────╯
```

Cards come from three sources:
- **Starter deck** -- 50 beginner cards across greetings, food, travel, numbers, verbs, and everyday words
- **Immersion** -- phrases automatically collected as Claude uses them in responses
- **Practice** -- vocabulary encountered during conversation and scenario sessions
- **Manual** -- cards you add yourself with `/flashcards add`

### Settings (`/french-settings`)

Full control over every aspect of the immersion experience.

| Command | Example |
|---------|---------|
| `/french-settings` | Show the dashboard |
| `/french-settings level intermediate` | Change difficulty |
| `/french-settings frequency off` | Pause immersion for focused work |
| `/french-settings topics food,work,social` | Choose vocabulary domains |
| `/french-settings formality formal` | Switch to vous form |

---

## Configuration

| Setting | Values | Default | Description |
|---------|--------|---------|-------------|
| `level` | `beginner`, `intermediate`, `advanced` | `beginner` | Vocabulary complexity and how much gets translated |
| `frequency` | `low`, `medium`, `high`, `off` | `medium` | How often French appears in normal responses |
| `mode` | `on`, `off`, `technical-only-english` | `technical-only-english` | Where French is allowed (skip during debugging, etc.) |
| `topics` | `food`, `travel`, `greetings`, `work`, `shopping`, `social`, `numbers`, `common-verbs`, `everyday` | `food, travel, greetings` | Vocabulary domains to draw from |
| `formality` | `casual`, `formal` | `casual` | `tu` (casual) vs `vous` (formal) verb forms |
| `direction` | `french-to-english`, `english-to-french`, `both` | `french-to-english` | Flashcard and drill review direction |
| `new-cards` | `1` -- `100` | `10` | Maximum new flashcards introduced per day |

---

## How It Works

### Architecture

```
claude-french/
├── .claude-plugin/plugin.json     Plugin manifest
├── skills/
│   ├── french-immersion/          Passive immersion behavior
│   ├── french-practice/           /french command
│   ├── french-flashcards/         /flashcards command
│   └── french-settings/           /french-settings command
├── hooks/
│   ├── hooks.json                 Session start trigger
│   └── immersion-hook.sh          Reads config, activates immersion
├── data/
│   ├── default_config.json        Default settings
│   ├── starter_deck.json          50 beginner flashcards
│   └── scenarios.json             10 role-play scenarios
├── scripts/install.sh             One-line installer
├── package.json                   ts-fsrs dependency
└── LICENSE
```

### Key concepts

**Skills** are markdown files that instruct Claude how to behave. Each slash command (`/french`, `/flashcards`, `/french-settings`) maps to a skill. The immersion skill runs passively in the background when activated by the hook.

**Hooks** are shell scripts that run at session start. The immersion hook reads your config file, checks if immersion is enabled, and tells Claude to load the immersion skill.

**FSRS** (Free Spaced Repetition Scheduler) is the algorithm behind Anki's scheduling. It tracks stability, difficulty, and review history for each card to compute optimal review intervals. Cards you find hard are shown sooner; cards you know well are spaced further apart.

**Data** is stored locally at `~/.claude/french/`. Nothing leaves your machine. Config, flashcards, and session stats are all JSON files you can inspect, edit, or back up.

---

## Scenarios

The plugin ships with 10 role-play scenarios:

| Scenario | Level | Topic |
|----------|-------|-------|
| Au cafe -- Order coffee and pastry | beginner | food |
| Au restaurant -- Dinner from ordering to paying | intermediate | food |
| Demander son chemin -- Ask for directions | beginner | travel |
| Acheter un billet de train -- Buy a train ticket | beginner | travel |
| Arrivee a l'hotel -- Check into a hotel | intermediate | travel |
| Au marche -- Buy produce at an outdoor market | beginner | shopping |
| Dans un magasin de vetements -- Try on clothes | intermediate | shopping |
| Se presenter -- Introduce yourself | beginner | social |
| Faire la conversation -- Small talk with a colleague | intermediate | social |
| Demander de l'aide -- Ask for help when lost | beginner | social |

Scenarios are filtered to your configured level and topics. Claude stays in character throughout, correcting your French without breaking the scene.

---

## Contributing

Contributions are welcome. Here are some ways to help:

- **Add scenarios** -- Create new role-play situations in `data/scenarios.json`
- **Expand the starter deck** -- Add cards to `data/starter_deck.json`
- **Improve skills** -- Refine the behavior prompts in `skills/`
- **Report bugs** -- Open an issue on GitHub

### Development

```bash
git clone https://github.com/nambouchara/claude-french.git
cd claude-french
npm install
```

The plugin is pure markdown + JSON + shell. No build step required. Edit a skill file, reload Claude Code, and test.

---

## License

[MIT](LICENSE)
