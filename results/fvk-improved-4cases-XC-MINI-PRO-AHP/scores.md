# Scores — run fvk-improved-4cases-XC-MINI-PRO-AHP

- host: XC-MINI-PRO-AHP
- model: claude-opus-4-8
- claude version: 2.1.169 (Claude Code)
- created: 2026-06-15T06:30:19.856704+00:00

| instance | baseline status | baseline resolved | baseline FTP | baseline PTP | fvk status | fvk resolved | fvk FTP | fvk PTP | control status | control resolved | control FTP | control PTP |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| django__django-12325 | completed | ✗ | 0/2 | 201/201 | completed | ✗ | 0/2 | 201/201 | pending | — | — | — |
| pytest-dev__pytest-10356 | completed | ✗ | 0/1 | 79/79 | completed | ✓ | 1/1 | 79/79 | pending | — | — | — |
| sympy__sympy-13852 | completed | ✗ | 0/1 | 4/4 | completed | ✗ | 0/1 | 4/4 | pending | — | — | — |
| sympy__sympy-16597 | completed | ✗ | 0/3 | 74/74 | completed | ✗ | 0/3 | 74/74 | pending | — | — | — |

## Aggregates

- baseline resolved: 0/4 (over evaluated instances; completed empty patches score unresolved)
- fvk resolved: 1/4 (over evaluated instances; completed empty patches score unresolved)
- control resolved: 0/0 (over evaluated instances; completed empty patches score unresolved)
- flips baseline→fvk: +1/-0 (up: pytest-dev__pytest-10356; down: none)
- flips baseline→control: +0/-0 (up: none; down: none)
- fvk vs control resolved delta: +1
