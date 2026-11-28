---
name: spend
description: "Jack's AI spend: what Hermes has cost on OpenRouter today, this week, this month, the monthly cap, and credit left. Use for 'what have I spent', 'how much has this cost', 'usage', 'credits', 'budget'."
version: 1.0.0
author: Jack
metadata:
  hermes:
    tags: [Cost, OpenRouter, Usage]
---

# Spend

Run `openrouter-spend` in the terminal. It prints JSON with:

- `key.usage_daily`, `key.usage_weekly`, `key.usage_monthly`, `key.usage`:
  USD spent through Hermes's OpenRouter key (today / this week / this calendar
  month / all time). Days and months are UTC.
- `key.limit` and `key.limit_remaining`: the key's monthly cap ($50, resets
  on the 1st) and what's left of it.
- `credits.total_credits - credits.total_usage`: prepaid credit left on the
  whole OpenRouter account.

Report in US dollars (that's what OpenRouter bills), rounded to cents,
phone-friendly, e.g.
"Today $0.42 · this week $3.10 · this month $11.80 of $50 cap · $38 credit left".

For a breakdown by model or by kind of work, combine it with `/insights`
(Hermes's own token logs, estimates) and say which numbers are estimates.

For just the current chat session's own token use and estimated cost, the
`/usage` command is a quicker alternative to `openrouter-spend`.

Claude Code jobs ("use Claude") run on Jack's Claude subscription, not
OpenRouter, so they don't appear here.
