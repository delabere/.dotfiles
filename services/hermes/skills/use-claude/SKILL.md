---
name: use-claude
description: "Jack's shortcut for handing work to Claude Code on brain. Use whenever Jack says 'use Claude', 'get Claude to', 'ask Claude', 'Claude on brain', or 'have Claude Code do X'."
version: 1.0.0
author: Jack
metadata:
  hermes:
    tags: [Coding-Agent, Claude, Delegation]
    related_skills: [claude-code]
---

# Use Claude (Claude Code on brain)

When Jack asks you to "use Claude", "get Claude to", "ask Claude" or "have
Claude on brain" do something, he means: delegate it to the Claude Code CLI
running here on brain, signed in with his Claude subscription. He has a large
allowance there, so prefer it for anything coding-heavy, long, or fiddly
(writing or fixing code, scripts, reviewing a repo, digging through files,
data wrangling), even if you could do it yourself.

Load the bundled `claude-code` skill for the full CLI reference, then follow
these house rules:

1. **Where it works.** Each job gets its own folder under
   `/var/lib/hermes/workspace/claude/<short-task-name>/` unless Jack names a
   different path. Create it, `git init` it if the job writes code, and run
   Claude Code from inside it.
2. **How to run it.** Use print mode with auto permissions:
   `claude -p "<task>" --permission-mode auto --output-format json`
   Write the task as a clear brief: goal, inputs, where outputs go, and what
   "done" looks like. For long jobs, run it in the background and tell Jack
   you've started it, then report when it finishes. To follow up on the same
   job, resume with `--resume <session_id>` from the JSON output.
3. **Auth.** It uses `CLAUDE_CODE_OAUTH_TOKEN` (Jack's subscription), already
   in the environment. Never pass `--bare` (that needs an API key) and never
   set `ANTHROPIC_API_KEY`.
4. **Boundaries.** Claude Code must not touch `/var/lib/hermes/.hermes`
   (secrets, tokens, memory) and must not push, deploy, send messages or
   delete anything outside its job folder without Jack's yes. Say so in the
   brief.
5. **Reporting back.** Summarise for a phone screen: what Claude did, what
   files changed or were created (paths), the key result or output, and
   anything that failed or needs Jack. Offer to send a file if the output is
   a document or script he'll want.
