# Home Flow Sketch + Lightweight Spec

## Sketches (ASCII)

### Home (idle)
```
------------------------------------------------
Starbound

[ What is on your mind today?                ]
------------------------------------------------
```

### Home (after submit)
```
------------------------------------------------
Starbound

[ What is on your mind today?                ]

----------------------------------------------
WHAT MATTERS
You are under time pressure and low energy.

NEXT STEP
Pick one small action that reduces friction.
----------------------------------------------

Clarify   Save   Get support

Using past entries to personalize this
------------------------------------------------
```

### Why this? drawer (optional)
```
----------------------------------------------
Why this?

Signals picked up
- low energy
- high time pressure
- access constraint

What was remembered
- work stress + sleep disruption (last 2 weeks)

Change what is remembered
Edit memory
----------------------------------------------
```

### Journal entry view (history)
```
------------------------------------------------
Journal

Apr 12, 3:20 PM
You are under time pressure and low energy.
Pick one small action that reduces friction.

Saved from Home
Tags: stress, time pressure

[ View why this ]   [ Edit memory ]
------------------------------------------------
```

## Lightweight Frontend Spec

### Core Components
- HomeInput: single persistent input field on Home.
- ResponseCard: displays "What matters" + "Next step".
- ActionChips: max 3, contextual (Clarify, Save, Get support).
- StatusLine: appears only when relevant.
- WhyThisDrawer: optional tap from ResponseCard footer.
- JournalView: separate tab for history.

### Behavior
1) User submits HomeInput.
2) System classifies signals.
3) ResponseCard renders with primary response shape.
4) Chips appear based on response shape and escalation tier.
5) StatusLine appears only when required (saved, memory used, safety).
6) WhyThisDrawer opens on tap; otherwise hidden.
7) JournalView shows entries and their originating response.

### Data Model (minimal)
- InputEntry: id, text, created_at
- Response: id, entry_id, what_matters, next_step, response_shape, escalation_tier
- Signals: entry_id, intent_type, emotional_load, time_pressure, complexity, agency, social_determinants
- MemoryUsage: entry_id, used (bool), remembered_summary (string)

### User Stories
1) As a user, I submit a single input and get one clear response card, so I am not forced into a chat thread.
2) As a user, I can tap Clarify to answer one short question, so the response can be refined.
3) As a user, I see Save when I am reflecting, so I can log without extra steps.
4) As a user, I see Get support when I am stuck, so I know what help looks like.
5) As a user, I can open Why this? to understand signals and memory use, so the system feels transparent.
6) As a user, I can view my past entries in Journal without cluttering Home.

### Acceptance Criteria
- Home shows only the input by default; no feed or thread.
- After submit, exactly one response card is visible.
- Action chips never exceed three.
- StatusLine only renders when a rule triggers it.
- WhyThisDrawer is hidden by default and reveals signals + memory summary.
- Journal is accessible from a separate tab, not Home.
