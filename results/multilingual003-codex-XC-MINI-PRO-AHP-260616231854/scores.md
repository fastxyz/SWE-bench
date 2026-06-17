# Scores — run multilingual003-codex-XC-MINI-PRO-AHP-260616231854

- host: XC-MINI-PRO-AHP
- agent: codex
- model: gpt-5.5
- effort: xhigh
- codex version: codex-cli 0.140.0-alpha.2
- created: 2026-06-16T22:37:54.762508+00:00

| instance | baseline status | baseline resolved | baseline FTP | baseline PTP | fvk status | fvk resolved | fvk FTP | fvk PTP |
|---|---|---|---|---|---|---|---|---|
| astral-sh__ruff-15626 | completed | ✓ | 2/2 | 34/34 | completed | ✓ | 2/2 | 34/34 |
| axios__axios-4731 | completed | ✓ | 1/1 | 1/1 | completed | ✓ | 1/1 | 1/1 |
| axios__axios-4738 | completed | ✓ | 1/1 | 3/3 | completed | ✓ | 1/1 | 3/3 |
| axios__axios-5085 | completed | ✓ | 1/1 | 1/1 | completed | ✓ | 1/1 | 1/1 |
| axios__axios-5316 | completed | ✗ | 0/1 | 0/2 | completed | ✗ | 0/1 | 0/2 |
| axios__axios-5892 | completed | ✓ | 3/3 | 30/30 | completed | ✓ | 3/3 | 30/30 |
| axios__axios-6539 | completed | ✗ | 0/1 | 0/0 | completed | ✗ | 0/1 | 0/0 |
| babel__babel-13928 | completed | ✓ | 2/2 | 247/247 | completed | ✓ | 2/2 | 247/247 |
| babel__babel-14532 | completed | ✓ | 1/1 | 523/523 | completed | ✓ | 1/1 | 523/523 |
| babel__babel-15445 | completed | ✗ | 0/1 | 55/55 | completed | ✗ | 0/1 | 55/55 |

## Aggregates

- baseline resolved: 7/10 (over evaluated instances; completed empty patches score unresolved)
- fvk resolved: 7/10 (over evaluated instances; completed empty patches score unresolved)
- flips baseline→fvk: +0/-0 (up: none; down: none)

## Orchestration notes (overnight run)

- **Gold-check: 10/10 resolved — eval environment fully validated** (no upstream drift; all of astral-sh/ruff (Rust), axios (JS), babel (JS) resolved gold).
- **Runs:** 20/20 arm sessions completed cleanly; no arm failures, no retries.
- **Eval:** baseline 7/10 resolved, fvk 7/10 resolved, 0 flips — baseline and fvk produced identical verdicts on every instance. The three unresolved instances (both arms) are `axios__axios-5316`, `axios__axios-6539`, and `babel__babel-15445`.
- **No unexpected failures in this batch.**
