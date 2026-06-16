# Scores — run multilingual001-codex-XC-MINI-PRO-AHP-260616231854

- host: XC-MINI-PRO-AHP
- agent: codex
- model: gpt-5.5
- effort: xhigh
- codex version: codex-cli 0.140.0-alpha.2
- created: 2026-06-16T18:07:34.719253+00:00

| instance | baseline status | baseline resolved | baseline FTP | baseline PTP | fvk status | fvk resolved | fvk FTP | fvk PTP |
|---|---|---|---|---|---|---|---|---|
| apache__druid-13704 | completed | ✓ | 1/1 | 2/2 | completed | ✓ | 1/1 | 2/2 |
| apache__druid-14092 | completed | ✓ | 1/1 | 1/1 | completed | ✓ | 1/1 | 1/1 |
| apache__druid-14136 | completed | ✗ | 2/3 | 2/2 | completed | ✗ | 2/3 | 2/2 |
| apache__druid-15402 | completed | ✓ | 1/1 | 2/2 | completed | ✓ | 1/1 | 2/2 |
| apache__druid-16875 | completed | ✓ | 1/1 | 2/2 | completed | ✓ | 1/1 | 2/2 |
| apache__lucene-11760 | completed | ✓ | 1/1 | 11/11 | completed | ✓ | 1/1 | 11/11 |
| apache__lucene-12022 | completed | ✗ | 0/1 | 23/23 | completed | ✗ | 0/1 | 23/23 |
| apache__lucene-12196 | completed | ✓ | 1/1 | 11/11 | completed | ✓ | 1/1 | 11/11 |
| apache__lucene-12212 | completed | ✓ | 1/1 | 10/10 | completed | ✓ | 1/1 | 10/10 |
| apache__lucene-12626 | completed | ✓ | 1/1 | 106/106 | completed | ✓ | 1/1 | 106/106 |

## Aggregates

- baseline resolved: 8/10 (over evaluated instances; completed empty patches score unresolved)
- fvk resolved: 8/10 (over evaluated instances; completed empty patches score unresolved)
- flips baseline→fvk: +0/-0 (up: none; down: none)

## Orchestration notes (overnight run)

- **Gold-check: 9/10 resolved.** `apache__lucene-12212` was UNRESOLVED in `validate-gold` (the official gold patch did not satisfy the test criteria in this Docker environment on this run). By the benchmark contract its score here is not gold-validated; flagged for transparency (cf. the upstream-drift caveat in START.md). Discrepancy worth noting: both baseline and fvk patches scored ✓ resolved for it in `evaluate`, so the gold miss is most likely a flaky/nondeterministic test rather than a hard environment break.
- **Runs:** 20/20 arm sessions completed cleanly; no arm failures, no retries needed.
- **Eval:** baseline 8/10 resolved, fvk 8/10 resolved, 0 flips (`evaluate` counts all 10). Counting only the 9 gold-validated instances, both arms resolve 7/9. The two gold-validated unresolved instances are `apache__druid-14136` and `apache__lucene-12022` (both ✗ for baseline and fvk alike).
