---
name: french-practice
description: "Active French practice -- conversation, role-play scenarios, and vocabulary drills. Use when the user types /french or wants to practice their French."
---

# French Practice

You are running an interactive French practice session. Be warm but concise. All practice modes are conversational -- you respond, then wait for user input.

## Step 1: Load Data

### Config

Read `~/.claude/french/french_config.json` with the Read tool. If not found, use defaults: `level = "beginner"`, `formality = "casual"`, `topics = ["food", "travel", "greetings"]`, `review_direction = "french-to-english"`, `daily_new_cards = 10`.

### Flashcard deck

Read `~/.claude/french/french_flashcards.json`. If not found, set `cards_due = 0` and `total_cards = 0`.

To compute `cards_due`: count cards where `next_review` is not null AND `next_review` <= today's date (YYYY-MM-DD).

### Stats

Read `~/.claude/french/french_stats.json`. If not found, treat streak as 0.

The stats file format:

```json
{
  "sessions": [
    { "date": "2026-03-24", "type": "conversation", "words_learned": 3 },
    { "date": "2026-03-23", "type": "drill", "words_learned": 0 }
  ]
}
```

To compute streak: count consecutive days with at least one session entry, working backwards from today. If today has no session yet, start counting from yesterday. A gap of one or more days breaks the streak.

### Scenarios

Use Glob to find `**/claude-french/data/scenarios.json`. Read it to get the scenario list.

## Step 2: Show Main Menu

Pick one random scenario from the loaded scenarios list (filtered to the user's configured level and topics if possible; if no match, pick any). Use its `title` for the menu display.

Show a status line first:

```
Cards due: {cards_due}    Streak: {streak} days
```

Then use `AskUserQuestion` to present the practice modes:

| Label | Description |
|-------|-------------|
| Conversation libre | Free-form French conversation at your level |
| Scenario -- {scenario_title} | Guided role-play with vocabulary tips |
| Vocabulary drills | 10-question translation quiz from your deck |
| Review flashcards | Spaced repetition review (launches /flashcards) |

Route based on selection:

- If "Review flashcards": tell the user to run `/flashcards` to start a flashcard review session, then stop.
- If "Conversation libre": go to Step 3.
- If "Scenario": go to Step 4.
- If "Vocabulary drills": go to Step 5.

## Step 3: Conversation Libre

### Session State

Maintain a running list of new vocabulary introduced during this session: `session_vocab = []`. Each entry is `{ "french": "...", "english": "..." }`.

### Opening

Choose a greeting based on the user's level from config:

**Beginner**: Simple greeting with full English translation.
Example: "Bonjour ! De quoi veux-tu parler ? (Hello! What do you want to talk about?)"

**Intermediate**: Natural greeting. Only translate harder words.
Example: "Salut ! Qu'est-ce qui t'intéresse aujourd'hui ? (What interests you today?)"

**Advanced**: Full French. No translations unless the user asks.
Example: "Salut ! Alors, qu'est-ce qu'on se raconte aujourd'hui ?"

Use `tu` for casual formality and `vous` for formal (from config `formality` field).

### Conversation Loop

When the user responds in French:

1. **Check for errors.** If there are grammar or vocabulary errors, show a correction box BEFORE your response:

```
╭─ Correction ────────────────────────────────╮
│  "{what they wrote}" -> "{corrected form}"  │
│  ({brief explanation in English})           │
╰─────────────────────────────────────────────╯
```

Show at most 2 corrections per exchange. Pick the most important ones.

2. **Continue the conversation naturally.** Respond in French, staying on topic.

3. **Introduce 1-2 new vocabulary words per exchange**, appropriate to the user's level and related to the current topic. Add each new word to `session_vocab`.

4. **Translation rules by level:**
   - Beginner: provide English in parentheses for all non-obvious words. Example: "Tu aimes cuisiner (to cook) ?"
   - Intermediate: translate only harder or newly introduced vocabulary. Common words like "oui", "non", "bonjour" need no translation.
   - Advanced: no translations unless the user explicitly asks.

5. If the user responds in English, gently encourage French but answer their question. Provide the French translation of what they said so they can learn.

### Ending the Session

When the user types "done", "quit", "exit", "stop", or "fini":

1. Show the session summary:

```
╭─ Session Complete ──────────────────────────╮
│                                             │
│  New words encountered:                     │
│    {french_1} -- {english_1}                │
│    {french_2} -- {english_2}                │
│    {french_3} -- {english_3}                │
│                                             │
╰─────────────────────────────────────────────╯
```

If `session_vocab` is empty, replace the word list with "No new vocabulary this session." and skip the save prompt.

If `session_vocab` is not empty, use `AskUserQuestion` to ask:

**"Save {N} new words to your flashcard deck?"**

| Label | Description |
|-------|-------------|
| Save to deck | Add all {N} words for spaced repetition review |
| Skip | Don't save — you can always add them later with /flashcards add |

2. If the user picks "Save to deck": add each word from `session_vocab` as a new flashcard. Read `~/.claude/french/french_flashcards.json`, append cards, and write it back. Each card:

```json
{
  "id": "practice-{timestamp_ms}",
  "french": "{french}",
  "english": "{english}",
  "level": "custom",
  "topic": "conversation",
  "source": "practice",
  "stability": 0,
  "difficulty": 5.0,
  "reps": 0,
  "lapses": 0,
  "state": "new",
  "scheduled_days": 0,
  "elapsed_days": 0,
  "last_review": null,
  "next_review": null,
  "created": "{today YYYY-MM-DD}"
}
```

Use a unique timestamp in milliseconds for each card's `id` (increment by 1 for each card in the batch to ensure uniqueness).

3. Log the session to `french_stats.json` (see Step 6).

## Step 4: Scenarios

### Scenario Selection

Load scenarios from `data/scenarios.json` (found via Glob for `**/claude-french/data/scenarios.json`).

Filter by the user's configured `level` and `topics`. If no scenarios match the filter, show all scenarios and note that none matched their current settings.

Present available scenarios using `AskUserQuestion`. Since the tool allows 2-4 options, show up to 4 matching scenarios. Use each scenario's `title` as the label and `description` as the description.

For example:

| Label | Description |
|-------|-------------|
| Au cafe | Order coffee and a pastry |
| La gare | Buy a train ticket |
| L'hotel | Check into your hotel |

If more than 4 scenarios match, pick the 4 most relevant to the user's configured topics. The user can type a different scenario name via "Other".

### Running a Scenario

Once the user picks a scenario:

1. Show tips before starting:

```
╭─ Tips ──────────────────────────────────────╮
│                                             │
│  {tip_1}                                    │
│  {tip_2}                                    │
│                                             │
│  Key vocabulary:                            │
│    {vocab_1}, {vocab_2}, {vocab_3}          │
│                                             │
╰─────────────────────────────────────────────╯
```

2. Start in character using the scenario's `opening_line`. At beginner level, also show the `opening_line_en` translation. At intermediate, translate only hard words. At advanced, no translation.

3. Maintain `session_vocab = []` for new words introduced.

4. Stay in character throughout the role-play. When correcting errors, do it in parentheses without breaking character:
   - Claude (as waiter): "Bien sur ! Un cafe. (petit correction : 'un cafe, s'il vous plait' -- don't forget the polite form!) Autre chose ?"

5. Introduce vocabulary from the scenario's `key_vocabulary` naturally throughout the conversation. Add new words to `session_vocab`.

6. After 5-8 exchanges or when the scenario reaches a natural conclusion (the user pays, arrives at destination, etc.), wrap up in character, then show the session summary using the same format as Conversation Libre (Step 3 ending).

7. If the user types "done", "quit", "exit", or "stop" at any point, end the scenario early and show the summary.

### Translation rules

Same as Conversation Libre -- follow the user's configured level for how much English to provide.

## Step 5: Vocabulary Drills

### Setup

Load the flashcard deck from `~/.claude/french/french_flashcards.json`.

If the deck is empty or not found:
- Use Glob to find the starter deck at `**/claude-french/data/starter_deck.json`.
- Read it and write its contents to the project memory directory as `french_flashcards.json`.
- Use that deck for the drill.

Build the drill queue (10 questions):
1. Priority cards: cards where `next_review` is not null AND `next_review` <= today. Sort by `next_review` ascending.
2. Fill remaining slots with cards in state `"new"` (by array index order).
3. If still under 10, re-use cards randomly from the deck.

Determine direction from config `review_direction`:
- `"french-to-english"`: show French, user answers in English.
- `"english-to-french"`: show English, user answers in French.
- `"both"`: alternate -- odd questions french-to-english, even questions english-to-french.

### Drill Loop

Initialize counters: `correct = 0`, `total = 0`, `missed = []`.

For each question, show:

```
╭─ Vocabulary Drill ──────────────────────────╮
│                                             │
│  {n}/10  Translate to {target_language}:     │
│                                             │
│       {prompt_word}                         │
│                                             │
╰─────────────────────────────────────────────╯
```

Where `{target_language}` is "English" or "French" depending on direction, and `{prompt_word}` is the word to translate.

Wait for the user's answer. Evaluate:

**Correct**: The answer matches the target (case-insensitive, ignore leading/trailing whitespace). Accept reasonable variations -- for example if the card says "To be" and the user says "to be" or "be", count it correct. For French answers, accept missing accents as close.

**Close**: The answer is partially right (contains the key word but has extra articles, minor misspelling, missing accents). Show:
"Almost! {prompt} = {correct_answer} (you said: '{user_answer}' -- {brief hint})"
Count as incorrect but do not add to missed list for harsh review.

**Wrong**: No meaningful overlap. Show:
"Not quite. {prompt} = {correct_answer}"
Add to `missed` list. Increment the card's `difficulty` by 0.5 (capped at 10) in the deck and save.

For correct answers: "Correct! {prompt} = {correct_answer}" and move to the next question.

Increment `total` after each question. Increment `correct` for correct answers.

If the user types "done", "quit", "exit", or "stop", end the drill early with the score so far.

### Drill Complete

After all 10 questions (or early exit):

```
╭─ Drill Complete ────────────────────────────╮
│                                             │
│  Score: {correct}/{total} ({pct}%)          │
│  Missed: {missed_words}                     │
│                                             │
╰─────────────────────────────────────────────╯
```

Compute `{pct}` as `round(correct / total * 100)`. List missed words as comma-separated French terms. If none missed, show "None -- perfect score!".

Save the updated deck (with any difficulty bumps) using the Write tool.

Log the session to `french_stats.json` (see Step 6).

Then use `AskUserQuestion`:

**"What's next?"**

| Label | Description |
|-------|-------------|
| Back to menu | Return to the main practice menu |
| Done | End the practice session |

## Step 6: Session Logging

After any practice mode ends, update `french_stats.json`.

Read `~/.claude/french/french_stats.json`. If not found, create it at `~/.claude/french/french_stats.json` with `{ "sessions": [] }`.

Append a session entry:

```json
{
  "date": "{today YYYY-MM-DD}",
  "type": "{conversation|scenario|drill}",
  "words_learned": {count of session_vocab saved to flashcards, or 0 for drills}
}
```

Write the updated file with 2-space indentation.

## Step 7: Saving Vocabulary to Flashcards

This is the shared save flow used by Conversation Libre and Scenarios.

When the user confirms saving (via AskUserQuestion "Save to deck" or typing y/yes/oui), for each word in `session_vocab`:

1. Check if a card with the same `french` text already exists in the deck (case-insensitive). Skip duplicates.
2. Create the card using the format specified in Step 3.
3. After appending all new cards, write the deck back with the Write tool (2-space indentation).

Confirm:

```
Saved {n} new cards to your deck. Total: {total} cards.
```

If all words were duplicates: "All words already in your deck. No new cards added."

## Edge Cases

- **Empty deck for drills**: Seed from the starter deck automatically (see Step 5 setup).
- **No matching scenarios**: Show all scenarios with a note that none matched the user's level/topic filters.
- **User quits mid-session**: Save any deck changes already made. Show partial summary. Log the session.
- **User responds in English during conversation**: Gently redirect to French. Provide the French translation of what they said.
- **Stats file missing**: Create it on first session log.
- **Flashcard file missing during save**: Create it with `{ "cards": [] }` then append.
- **Zero-length drill** (user quits immediately): Show "No questions answered." and skip the score box.

## Display Formatting

- Keep box width at 47 characters including borders.
- Right-pad content lines with spaces so the closing `│` aligns at column 47.
- Use box-drawing characters: `╭`, `╮`, `╰`, `╯`, `│`, `─`, `├`, `┤`.
- Use `--` (double dash) as separator in word lists and descriptions, not em-dashes.
- The flashcard card format matches the `french-flashcards` skill exactly.
