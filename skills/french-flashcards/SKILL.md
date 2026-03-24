---
name: french-flashcards
description: "Review French flashcards with Anki-powered spaced repetition (FSRS). Use when the user types /flashcards or wants to review, add, or manage their French vocabulary cards."
---

# French Flashcards

You are running an Anki-style spaced repetition flashcard session. Be concise and focused. Present one card at a time, wait for the user's rating, update the card, and move to the next.

## Step 1: Load Data

### Locate the deck

Use Glob to find the flashcard deck:
- Pattern: `**/memory/french_flashcards.json`
- Search in: `~/.claude/projects/`

If the file is not found or is empty, ask the user:

```
No flashcard deck found. Would you like to seed it from the starter deck (50 beginner cards)?
```

If yes, use Glob to find the plugin's starter deck at `**/claude-french/data/starter_deck.json`, read it, then write its contents to the project memory directory as `french_flashcards.json`.

If no, create an empty deck: `{ "cards": [] }`.

### Load config

Use Glob to find `**/memory/french_config.json` in `~/.claude/projects/`. Read it to get `review_direction` and `daily_new_cards`. If not found, use defaults: `review_direction = "french-to-english"`, `daily_new_cards = 10`.

## Step 2: Parse Arguments

Check what comes after `/flashcards`:

| Argument | Action |
|----------|--------|
| (none) | Start a review session (Step 3) |
| `add {french} {english...}` | Add a card manually (Step 7) |
| `stats` | Show deck statistics (Step 8) |

## Step 3: Select Cards Due for Review

Today's date is the current date. Build the review queue:

1. **Due reviews**: Cards where `next_review` is not null AND `next_review` <= today. Sort by `next_review` ascending (most overdue first).
2. **New cards**: Cards where `state` is `"new"` AND `next_review` is null. Limit to `daily_new_cards` from config. Take them in deck order (by array index).
3. **Combined queue**: Due reviews first, then new cards.

If the queue is empty, show the "nothing due" display and stop:

```
╭─ Flashcards ────────────────────────────────╮
│                                             │
│  Nothing due right now!                     │
│  Next review: {N} cards {when}              │
│  Total deck: {total} cards                  │
│                                             │
╰─────────────────────────────────────────────╯
```

To fill in `{N} cards {when}`: scan all cards for the earliest `next_review` that is after today. Count how many cards share that date. Display as "tomorrow" if it's tomorrow, otherwise as the date. If no cards have a future `next_review`, display "No upcoming reviews".

## Step 4: Present a Card

Determine the display direction for this card:

- If `review_direction` is `"french-to-english"`: show French as the prompt, English as the answer.
- If `review_direction` is `"english-to-french"`: show English as the prompt, French as the answer.
- If `review_direction` is `"both"`: alternate — odd-numbered cards in the session use french-to-english, even-numbered use english-to-french.

Build the progress dots: one dot per card in the session queue. Use `●` for the current card's position, `○` for all others. Show up to 12 dots; if more than 12 cards, show the first 11 dots plus `…` at the end.

Build the streak indicator: count consecutive reviews where the card was NOT lapsed (i.e., `reps` minus `lapses` gives a rough streak, but more precisely: the streak is `reps - lapses` clamped to 0..5 for display). Use `●` for earned dots and `○` for remaining, always 5 dots total. For new cards (reps = 0), show `○○○○○`.

Compute "last seen": if `last_review` is null, show "new card". Otherwise compute the number of days between today and `last_review` and show "today", "yesterday", "N days ago", etc.

Display the card — first show only the prompt side:

```
╭─────────────────────────────────────────────╮
│  FLASHCARD  {n}/{total}       {progress}    │
├─────────────────────────────────────────────┤
│                                             │
│          {prompt text}                      │
│                                             │
╰─────────────────────────────────────────────╯

Think of the answer, then say "flip" or "f" to reveal.
```

Wait for the user to say "flip", "f", "show", or any indication they want to see the answer. Then reveal:

```
╭─────────────────────────────────────────────╮
│  FLASHCARD  {n}/{total}       {progress}    │
├─────────────────────────────────────────────┤
│                                             │
│          {prompt text}                      │
│                                             │
│  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  │
│  {answer text}                   [{level}]  │
│                                             │
│  Last seen: {last_seen}   Streak: {streak}  │
╰─────────────────────────────────────────────╯

  (1) Again  (2) Hard  (3) Good  (4) Easy
```

The `{level}` tag shows the card's `level` field (e.g., "beginner", "custom").

## Step 5: Process Rating

Accept the user's rating as a number 1-4, or the words "again", "hard", "good", "easy" (case-insensitive). If input is invalid, ask again.

Initialize session counters on the first card if not already done:
- `session_reviewed = 0`
- `session_correct = 0`
- `session_new = 0`

Track: increment `session_reviewed`. If rating is 3 (Good) or 4 (Easy), increment `session_correct`. If the card's state was `"new"` before this review, increment `session_new`.

### FSRS Scheduling

Compute `elapsed_days`: if `last_review` is not null, the number of days between `last_review` and today. Otherwise 0.

#### New cards (state = "new")

| Rating | stability | scheduled_days | state |
|--------|-----------|---------------|-------|
| Again (1) | 0.4 | 1 | "learning" |
| Hard (2) | 0.9 | 1 | "learning" |
| Good (3) | 2.5 | 3 | "review" |
| Easy (4) | 5.0 | 5 | "review" |

Difficulty starts at 5.0 for new cards (override the 0 from starter deck on first review).

#### Learning cards (state = "learning")

| Rating | stability | scheduled_days | state | extra |
|--------|-----------|---------------|-------|-------|
| Again (1) | 0.4 | 1 | "learning" | lapses += 1 |
| Hard (2) | 1.2 | 1 | "learning" | |
| Good (3) | 2.5 | 3 | "review" | |
| Easy (4) | 5.0 | 5 | "review" | |

#### Review cards (state = "review") and Relearning cards (state = "relearning")

| Rating | stability | scheduled_days | state |
|--------|-----------|---------------|-------|
| Again (1) | reset (see below) | 1 | "relearning" |
| Hard (2) | old_stability * 1.2 | max(new_stability * 0.8, elapsed_days + 1) | "review" |
| Good (3) | old_stability * (2.5 + difficulty * 0.1) | round(new_stability) | "review" |
| Easy (4) | old_stability * (3.5 + difficulty * 0.15) | round(new_stability * 1.3) | "review" |

For Again on review/relearning: reset stability to `max(0.4, old_stability * 0.2)`. `lapses += 1`.

Round `scheduled_days` to the nearest integer, minimum 1.

#### Difficulty adjustment (all states)

| Rating | Adjustment |
|--------|-----------|
| Again (1) | difficulty = min(difficulty + 1, 10) |
| Hard (2) | difficulty = min(difficulty + 0.5, 10) |
| Good (3) | no change |
| Easy (4) | difficulty = max(difficulty - 0.5, 1) |

#### Final card updates

After computing the new values:
- `reps += 1`
- `elapsed_days = computed elapsed_days`
- `last_review = today's date (YYYY-MM-DD)`
- `next_review = today + scheduled_days (YYYY-MM-DD)`
- Update `stability`, `difficulty`, `state`, `scheduled_days`, `lapses` as computed above.

### Save the deck

After updating the card, write the entire deck JSON back to the file using the Write tool. Pretty-print with 2-space indentation.

## Step 6: Next Card or Session Summary

After processing a rating:
- If there are more cards in the queue, proceed to Step 4 with the next card.
- If all cards are reviewed, show the session summary:

```
╭─ Session Complete ──────────────────────────╮
│                                             │
│  Reviewed    {session_reviewed} cards       │
│  Correct     {session_correct}  ({pct}%)    │
│  New         {session_new}  cards learned   │
│  Total deck  {total_cards} cards            │
│  Due tomorrow {due_tomorrow}                │
│                                             │
╰─────────────────────────────────────────────╯
```

Compute `{pct}` as `round(session_correct / session_reviewed * 100)`. Compute `{due_tomorrow}` by counting cards where `next_review` equals tomorrow's date.

## Step 7: Manual Add (`/flashcards add`)

Parse the arguments after "add". The first word is the French term, everything after is the English meaning.

Example: `/flashcards add bonjour hello` -> french = "bonjour", english = "hello"
Example: `/flashcards add au revoir goodbye` is ambiguous, so if there are more than 2 words, ask the user to clarify which part is French and which is English. Suggest using a slash separator: `/flashcards add au revoir / goodbye`.

If a `/` separator is present, split on it: left side is French, right side is English. Trim whitespace from both.

Create a new card:

```json
{
  "id": "manual-{timestamp}",
  "french": "{french}",
  "english": "{english}",
  "level": "custom",
  "topic": "custom",
  "source": "manual",
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

Use the current Unix timestamp in milliseconds for `{timestamp}` (e.g., `manual-1711324800000`).

Append the card to the deck's `cards` array and save.

Confirm:

```
╭─ Card Added ────────────────────────────────╮
│                                             │
│  {french} -> {english}                      │
│  Total deck: {total} cards                  │
│                                             │
╰─────────────────────────────────────────────╯
```

## Step 8: Stats Command (`/flashcards stats`)

Count cards by state and compute due counts:

```
╭─ Deck Statistics ───────────────────────────╮
│                                             │
│  Total cards   {total}                      │
│  New           {count state=new}            │
│  Learning      {count state=learning}       │
│  Review        {count state=review}         │
│  Relearning    {count state=relearning}     │
│                                             │
│  Due today     {due_today}                  │
│  Due tomorrow  {due_tomorrow}               │
│                                             │
╰─────────────────────────────────────────────╯
```

`due_today`: cards where `next_review` <= today OR (`state` is `"new"` AND `next_review` is null), capped by `daily_new_cards` for new cards.
`due_tomorrow`: cards where `next_review` equals tomorrow's date.

## Edge Cases

- **Empty deck with no starter**: Show stats as all zeros and suggest using `/flashcards add` to create cards.
- **Invalid rating input**: Re-prompt with `Please enter 1-4 (Again, Hard, Good, Easy):`.
- **User wants to quit mid-session**: If the user says "quit", "stop", "q", or "exit", save the deck immediately and show a partial session summary using the same format as Step 6 but with the counts so far.
- **Difficulty field is 0 on starter cards**: When a card has `difficulty` of 0, treat it as 5.0 on first review (this is the initial default; starter deck ships with 0 to indicate unreviewed).
- **Cards with future next_review**: Skip them entirely; they are not due.
- **Scheduled_days rounding**: Always round to nearest integer, minimum 1 day.

## Display Formatting

- Keep box width at 47 characters including borders.
- Right-pad content lines with spaces so the closing `│` aligns at column 47.
- Use box-drawing characters: `╭`, `╮`, `╰`, `╯`, `│`, `─`, `├`, `┤`.
- Center the prompt/answer text within the card body.
- The dashed separator uses spaced en-dashes: `─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─`.

## Review Flow Summary

The full interaction for a review session:

1. Load deck and config.
2. Build queue of due cards.
3. For each card:
   a. Show the prompt side. Wait for "flip".
   b. Show the full card with answer. Show rating options.
   c. Accept rating. Apply FSRS. Save deck.
4. Show session summary.

Keep the conversation tight. Do not add extra commentary between cards unless the user asks a question. The rhythm should be: card -> flip -> rate -> next card.
