# Scores — run multilingual002-codex-XC-MINI-PRO-AHP-260616231854

- host: XC-MINI-PRO-AHP
- agent: codex
- model: gpt-5.5
- effort: xhigh
- codex version: codex-cli 0.140.0-alpha.2
- created: 2026-06-16T21:31:14.341296+00:00

| instance | baseline status | baseline resolved | baseline FTP | baseline PTP | fvk status | fvk resolved | fvk FTP | fvk PTP |
|---|---|---|---|---|---|---|---|---|
| apache__lucene-13170 | completed | ✓ | 1/1 | 8/8 | completed | ✗ | 0/1 | 8/8 |
| apache__lucene-13301 | completed | ✓ | 1/1 | 0/0 | completed | ✓ | 1/1 | 0/0 |
| apache__lucene-13494 | completed | ✗ | 0/1 | 0/8 | completed | ✓ | 1/1 | 8/8 |
| apache__lucene-13704 | completed | ✗ | 0/1 | 39/39 | completed | ✗ | 0/1 | 38/39 |
| astral-sh__ruff-15309 | completed | ✓ | 1/1 | 4/4 | completed | ✓ | 1/1 | 4/4 |
| astral-sh__ruff-15330 | completed | ✓ | 1/1 | 12/12 | completed | ✓ | 1/1 | 12/12 |
| astral-sh__ruff-15356 | completed | ✓ | 1/1 | 133/133 | completed | ✓ | 1/1 | 133/133 |
| astral-sh__ruff-15394 | completed | ✗ | 0/1 | 8/8 | completed | ✗ | 0/1 | 8/8 |
| astral-sh__ruff-15443 | completed | ✓ | 1/1 | 58/58 | completed | ✓ | 1/1 | 58/58 |
| astral-sh__ruff-15543 | completed | ✓ | 1/1 | 124/124 | completed | ✓ | 1/1 | 124/124 |

## Aggregates

- baseline resolved: 7/10 (over evaluated instances; completed empty patches score unresolved)
- fvk resolved: 7/10 (over evaluated instances; completed empty patches score unresolved)
- flips baseline→fvk: +1/-1 (up: apache__lucene-13494; down: apache__lucene-13170)

## Orchestration notes (overnight run)

- **Gold-check: 9/10 resolved.** `apache__lucene-13494` was UNRESOLVED in `validate-gold`; its eval verdict is not gold-validated and is excluded from the gold-validated tally below. (All 6 astral-sh/ruff Rust instances resolved gold — no Rust toolchain drift in this batch.)
- **Runs:** 20/20 arm sessions completed cleanly; no arm failures, no retries.
- **Flips:** `evaluate` reports +1/-1. The up-flip is `apache__lucene-13494` — the SAME instance that failed gold-check, so that gain is NOT trustworthy. The down-flip `apache__lucene-13170` (baseline ✓ → fvk ✗; fvk broke the FAIL_TO_PASS test) IS gold-validated — a real fvk regression.
- **Eval (gold-validated subset, 9 instances):** baseline 7/9 resolved, fvk 6/9 resolved — on trustworthy instances fvk is one behind baseline this batch (one real regression, no trustworthy gain). `evaluate`'s all-10 headline is baseline 7/10, fvk 7/10.
