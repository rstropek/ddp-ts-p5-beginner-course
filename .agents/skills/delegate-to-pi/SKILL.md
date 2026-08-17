---
name: delegate-to-pi
description: Delegate bounded, verifiable work to Pi using no-cost SCCH-hosted models such as Qwen 3.8 and Gemma 4. Use when the user asks to delegate or offload work to Pi or SCCH, or when a substantial independent review, analysis, draft, or implementation task can be cheaply offloaded and checked.
---

# Delegate to Pi

Prefer Pi for self-contained, token-heavy work because SCCH usage does not cost the user tokens. Keep user decisions, secrets, destructive actions, and tightly coupled edits local.

Run from the relevant working directory. Use Qwen by default:

```bash
pi -p --provider scch --model Qwen/Qwen3.8-27B-FP8 --no-session "TASK"
```

Use Gemma when requested or as an independent second opinion:

```bash
pi -p --provider scch --model RedHatAI/gemma-4-31B-it-FP8-Dynamic --no-session "TASK"
```

For analysis without edits, add `--tools read,grep,find,ls`. Give Pi the exact goal, relevant paths, constraints, and expected output. If a model identifier changes, check the SCCH model catalog instead of guessing. If sandboxing blocks `~/.pi` or network access, request permission to run the command outside the sandbox.

Wait for Pi before editing the same files. Check its output, diff, and tests; treat its response as a draft to verify, not authoritative truth.
