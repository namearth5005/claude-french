---
name: french-settings
description: "Configure French immersion settings — level, frequency, topics, formality, and more. Use when the user types /french-settings or wants to adjust their French learning preferences."
model: haiku
effort: low
---

# French Settings (Interactive)

You are managing the user's French immersion configuration through an interactive menu. Be concise and direct.

## Step 1: Load Config

Read `~/.claude/french/french_config.json` with the Read tool.

If the file does not exist, create the directory `~/.claude/french/` and write a new config file there with these defaults:

```json
{
  "level": "beginner",
  "frequency": "medium",
  "mode": "technical-only-english",
  "topics": ["food", "travel", "greetings"],
  "formality": "casual",
  "review_direction": "french-to-english",
  "daily_new_cards": 10
}
```

## Step 2: Route Based on Arguments

Check if the user provided arguments after `/french-settings`.

- **Arguments provided** → go to Direct Command Mode (Step 6).
- **No arguments** → show the dashboard (Step 3), then start the interactive menu (Step 4).

## Step 3: Render Dashboard

Display the settings dashboard using the rendering rules in the Dashboard Rendering section below. Always show this before entering the interactive menu.

## Step 4: Interactive Menu

Use `AskUserQuestion` to ask which setting to change. Group settings into intuitive categories so they fit the 2-4 option limit.

### First Question: "Which setting would you like to change?"

Present these options:

| Label | Description |
|-------|-------------|
| Level & Formality | Level: {level} ({dots}), Formality: {formality_display} |
| Immersion style | Frequency: {frequency} ({freq_dots}), Mode: {mode} |
| Learning content | Topics, review direction, cards/day |

The user can also type a specific setting name via "Other" (e.g., "topics" or "new-cards").

If the user picks "Other" and types "done", "exit", "quit", or "nothing", stop — do not enter the edit flow.

### Second Question: Disambiguate Within Group

If the user selected a group containing multiple settings, use `AskUserQuestion` to ask which specific setting:

**Level & Formality:**

| Label | Description |
|-------|-------------|
| Level | Currently: {level} ({dots}) |
| Formality | Currently: {formality_display} |

**Immersion style:**

| Label | Description |
|-------|-------------|
| Frequency | Currently: {frequency} ({freq_dots}) |
| Mode | Currently: {mode} |

**Learning content:**

| Label | Description |
|-------|-------------|
| Topics | Currently: {topics_str} |
| Review direction | Currently: {direction_display} |
| Daily new cards | Currently: {daily_new_cards}/day |

### Third Question: Pick the New Value

Use `AskUserQuestion` to present valid values for the chosen setting. Mark the current value with "(current)" in its description.

**Level:**
| Label | Description |
|-------|-------------|
| Beginner ●○○○ | Foundation vocabulary and grammar |
| Intermediate ●●○○ | Complex phrases and idioms |
| Advanced ●●●○ | Full fluency, minimal translations |
| Native ●●●● | Responses in French, English only for code |

**Frequency:**
| Label | Description |
|-------|-------------|
| Off ○○○○○ | No French in responses |
| Low ●○○○○ | 1 phrase every 3-4 responses |
| Medium ●●○○○ | 1-2 phrases per response |
| High ●●●○○ | French in almost every sentence |
| Intense ●●●●○ | Full French sentences with inline translations |
| Full ●●●●● | All prose in French, no translations |

**Mode:**
| Label | Description |
|-------|-------------|
| On | French everywhere, including technical explanations |
| Off | No French at all (same as frequency off) |
| Technical-only-english | French in casual talk, English for technical content |

**Formality:**
| Label | Description |
|-------|-------------|
| Casual (tu) | Informal — tu veux, tu peux |
| Formal (vous) | Polite — vous voulez, vous pouvez |

**Topics** (use `multiSelect: true`):

Present the top 4 most relevant topics (prioritize currently selected ones). Valid topics: food, travel, greetings, work, shopping, social, numbers, common-verbs, everyday. The user can type additional topics via "Other" (comma-separated). Must select at least one topic.

**Review direction:**
| Label | Description |
|-------|-------------|
| French -> English | See French, recall English |
| English -> French | See English, recall French |
| Both directions | Alternate between the two |

**Daily new cards:**
| Label | Description |
|-------|-------------|
| 5/day | Light — steady pace |
| 10/day | Standard — balanced learning |
| 20/day | Intensive — faster vocabulary growth |

The user can type a custom number (1-100) via "Other".

## Step 5: Save, Confirm & Loop

1. Validate the new value (see Validation Rules below).
2. Save the updated config with the Write tool (pretty-print JSON, 2-space indent).
3. Show the updated dashboard with a confirmation line below.
4. Use `AskUserQuestion` to ask: "Change another setting?"
   - **"Yes, change another"** → loop back to Step 4 (first question).
   - **"Done"** → stop.

## Step 6: Direct Command Mode (Backward Compatible)

If the user provided arguments after `/french-settings`, parse them directly without the interactive flow.

| Command | Example | Effect |
|---------|---------|--------|
| `level` | `level intermediate` | Sets level |
| `frequency` | `frequency off` | Sets frequency |
| `mode` | `mode on` | Sets immersion mode |
| `topics` | `topics food,travel,work` | Sets topic list (comma-separated) |
| `formality` | `formality formal` | Sets formality |
| `direction` | `direction both` | Sets review direction |
| `new-cards` | `new-cards 15` | Sets daily new card limit |

Validate, save, and show the dashboard with a confirmation line. Do not enter the interactive loop.

## Validation Rules

Apply these strictly. If a value is invalid, show the error format and do NOT save.

- **level**: `beginner`, `intermediate`, `advanced`, `native`
- **frequency**: `off`, `low`, `medium`, `high`, `intense`, `full`
- **mode**: `on`, `off`, `technical-only-english`
- **topics**: Each must be one of: `food`, `travel`, `greetings`, `work`, `shopping`, `social`, `numbers`, `common-verbs`, `everyday`. At least one required.
- **formality**: `casual`, `formal`
- **review_direction**: `french-to-english`, `english-to-french`, `both`
- **daily_new_cards**: Positive integer between 1 and 100.

## Dashboard Rendering

Build indicators:
- level: beginner → `●○○○`, intermediate → `●●○○`, advanced → `●●●○`, native → `●●●●`
- frequency: off → `○○○○○`, low → `●○○○○`, medium → `●●○○○`, high → `●●●○○`, intense → `●●●●○`, full → `●●●●●`
- formality: casual → `casual (tu)`, formal → `formal (vous)`
- topics: comma-separated string from the array
- direction: french-to-english → `french -> english`, english-to-french → `english -> french`, both → `both directions`

```
╭─ French Immersion Settings ─────────────────╮
│                                             │
│  Level       {level_dots}  {level}          │
│  Frequency   {freq_dots}  {frequency}       │
│  Mode        {mode}                         │
│  Topics      {topics_str}                   │
│  Formality   {formality_display}            │
│  Direction   {direction_display}            │
│  New cards   {daily_new_cards}/day          │
│                                             │
╰─────────────────────────────────────────────╯
```

Right-pad each line with spaces so the closing `│` aligns at column 47. Keep the box width fixed at 47 characters (including the border characters).

If a setting was just updated, add a confirmation line below the box:
```
Updated {setting} to {value}.
```

## Error Format

```
Error: Invalid value "{value}" for {setting}.
Valid options: {comma-separated valid values}
```

Do not render the dashboard on validation errors.
