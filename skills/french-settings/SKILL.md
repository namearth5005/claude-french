---
name: french-settings
description: "Configure French immersion settings — level, frequency, topics, formality, and more. Use when the user types /french-settings or wants to adjust their French learning preferences."
---

# French Settings

You are managing the user's French immersion configuration. Be concise and direct.

## Step 1: Locate the Config

Read the config file directly:
- Path: `~/.claude/french/french_config.json`

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

Use the Read tool to load the existing config. Parse the JSON to get current values.

## Step 2: Handle Arguments

Check if the user provided arguments after `/french-settings`.

### No arguments — display the dashboard

Read the config and render the dashboard exactly as specified in the rendering section below. Do not change any settings.

### Arguments provided — update the setting

Parse the first argument as the setting name and the rest as the value. Supported commands:

| Command | Example | Effect |
|---------|---------|--------|
| `level` | `level intermediate` | Sets level |
| `frequency` | `frequency off` | Sets frequency |
| `mode` | `mode on` | Sets immersion mode |
| `topics` | `topics food,travel,work` | Sets topic list (comma-separated) |
| `formality` | `formality formal` | Sets formality |
| `direction` | `direction both` | Sets review direction |
| `new-cards` | `new-cards 15` | Sets daily new card limit |

## Step 3: Validate Before Saving

Apply these validation rules strictly. If a value is invalid, show an error message with the valid options and do NOT save.

**level**: Must be one of `beginner`, `intermediate`, `advanced`

**frequency**: Must be one of `low`, `medium`, `high`, `off`

**mode**: Must be one of `on`, `off`, `technical-only-english`

**topics**: Each topic must be one of: `food`, `travel`, `greetings`, `work`, `shopping`, `social`, `numbers`, `common-verbs`, `everyday`. Split on commas, trim whitespace. Must have at least one topic.

**formality**: Must be one of `casual`, `formal`

**review_direction** (command: `direction`): Must be one of `french-to-english`, `english-to-french`, `both`

**daily_new_cards** (command: `new-cards`): Must be a positive integer between 1 and 100.

## Step 4: Save the Config

Use the Write tool to save the updated JSON back to the same file path. Pretty-print the JSON with 2-space indentation.

## Step 5: Render the Dashboard

After reading or updating the config, always display the dashboard. Render it exactly like this, using box-drawing characters. Replace the values with the actual config values.

Build the level indicator:
- `beginner` -> `●○○`
- `intermediate` -> `●●○`
- `advanced` -> `●●●`

Build the frequency indicator:
- `off` -> `○○○`
- `low` -> `●○○`
- `medium` -> `●●○`
- `high` -> `●●●`

Build the formality display:
- `casual` -> `casual (tu)`
- `formal` -> `formal (vous)`

Format topics as a comma-separated string from the array.

Build the direction display:
- `french-to-english` -> `french -> english`
- `english-to-french` -> `english -> french`
- `both` -> `both directions`

Then output:

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

Right-pad each line with spaces so the closing `│` aligns consistently at column 47. Keep the box width fixed at 47 characters (including the border characters).

If a setting was just updated, add a brief confirmation line below the box:

```
Updated {setting} to {value}.
```

## Error Format

If validation fails, output:

```
Error: Invalid value "{value}" for {setting}.
Valid options: {comma-separated valid values}
```

Do not render the dashboard on validation errors.
