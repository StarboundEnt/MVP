# Response Shapes Decision Logic + Escalation Thresholds

## Purpose
Define how a single user input on Home maps to a response shape and when escalation is required, without exposing feature tabs (Ask, Journal, Support, Vault, Insights).

## Inputs (Signals)
Signals are inferred from the current input and optional memory (per consent).

- intent_type: question | reflection | uncertainty | request | log_only
- emotional_load: low | medium | high
- time_pressure: low | medium | high
- complexity: simple | tangled | systemic
- agency: can_act_now | constrained | blocked
- social_determinants: list of chance domains (financial, housing, employment, education, caregiving, transportation, social_support, environment, discrimination, healthcare_access, civic_participation)
- risk_flags: none | self_harm | harm_to_others | imminent_danger
- recurrence: none | recent | frequent (same theme appears in last N entries)
- memory_used: true | false (for UI footer)

Notes:
- social_determinants should map to Chance domains defined in `docs/complexity_profile_ontology.md`.
- log_only is true when user explicitly says "just logging", "note to self", or taps a Log/Save-only chip.

## Response Shapes (Primary)
Pick one primary shape per response.

1. clarifying_question
2. gentle_reflection
3. concrete_next_step
4. option_comparison
5. escalation_support
6. pattern_recall

## High-Level Flow
1) Detect risk and decide escalation tier.
2) If log_only, store and confirm with a tiny toast; do not generate full response.
3) Select the primary response shape based on intent + load + complexity + agency.
4) Add optional secondary elements (pattern recall, memory hint, status line).

## Escalation Tiers
### Tier 0: No escalation
Default. Provide the primary response shape.

### Tier 1: Gentle support prompt
Trigger when:
- emotional_load = high AND agency != can_act_now
OR
- recurrence = frequent AND stuckness language is present (e.g., "always", "can't get out of this")

Response shape:
- still primary shape, plus a soft prompt: "Would it help to loop someone in?"
- optional chips: "Get support", "Clarify", "Save"

### Tier 2: Stronger guidance (real-time support recommended)
Trigger when:
- emotional_load = high AND agency = blocked
OR
- risk_flags = none BUT language suggests isolation + inability to cope (e.g., "no one", "can't cope") AND time_pressure = high

Response shape:
- escalation_support as primary
- present trusted person + professional support options
- keep tone calm and directive

### Tier 3: Crisis flow (imminent danger or intent)
Trigger when:
- risk_flags = self_harm OR harm_to_others OR imminent_danger

Response shape:
- escalation_support only
- provide emergency services + crisis hotline + trusted person guidance
- no hedging language; clear, supportive, non-alarming

## Response Shape Selection (Non-Crisis)
If Tier 2 or Tier 3, ignore the mapping below and use escalation_support.

Priority order:
1. intent_type = question -> clarifying_question OR option_comparison if multiple alternatives are present.
2. intent_type = uncertainty -> clarifying_question or gentle_reflection (if emotional_load >= medium).
3. intent_type = reflection -> gentle_reflection, with optional concrete_next_step if agency = can_act_now.
4. intent_type = request -> concrete_next_step (if complexity != systemic), else option_comparison.
5. complexity = systemic OR agency = blocked -> option_comparison or escalation_support (Tier 1/2 rules).

Secondary add-ons:
- pattern_recall: add when recurrence = frequent AND memory_used = true.
- memory footer: add when memory_used = true.
- status line: add when saving or a safety disclaimer applies.

## Example Decision Snippets
Pseudo-logic:

```
if log_only:
  save_entry()
  show_toast("Saved")
  return

if risk_flags in [self_harm, harm_to_others, imminent_danger]:
  respond(escalation_support, tier=3)
  return

if emotional_load == high and agency == blocked:
  respond(escalation_support, tier=2)
  return

shape = choose_shape(intent_type, complexity, agency, emotional_load)
if emotional_load == high and agency != can_act_now:
  add_support_prompt()
if recurrence == frequent and memory_used:
  add_pattern_recall()
respond(shape)
```

## Status Line Rules
Use only when relevant:
- "Saved to Journal" when log_only or explicit save action occurs.
- "Using past entries to personalize this" when memory_used = true.
- "Not medical advice" when responding to health or symptom questions.

## Chips (Default)
Pick at most 2-3:
- Clarify (if next best step is a question)
- Save/Log (if reflective content is detected)
- Get support (if Tier 1+)

## Tone Constraints
- Pragmatic coach with light validation.
- Non-anthropomorphic (no "I feel", "I’m worried").
- No clinical jargon unless user asks.
