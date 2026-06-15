# FVK improvements to flip the 4 STATED fvk-arm failures

**Date:** 2026-06-15
**Goal:** make `django-12325`, `pytest-10356`, `sympy-13852`, `sympy-16597` flip from
baseline-confirm (bug retained) to PASS, by improving the static FVK materials and
fixing how they are staged into the fvk arm.
**Source analysis:** [`SYNTHESIS.md`](SYNTHESIS.md) and the four per-instance `ANALYSIS.md` files.

## Diagnosis

All four are **STATED** cases: FVK localized to the exact fix and *named it*, then
produced a constructed (never machine-checked) reason to keep the buggy behavior. The
self-imposed constraint that rejected the correct fix differs per case:

| Instance | Correct fix (named in the FVK artifacts) | Constraint that rejected it |
|---|---|---|
| django-12325 | `… and field.remote_field.parent_link` | a pre-fix in-repo test treated as binding (the gold patch deletes it) |
| sympy-13852 | put the `Li₂` special values in `polylog.eval` | the issue's pre-fix REPL display read as a "stays-unevaluated" invariant |
| pytest-10356 | forward `obj.__mro__` (drop `reversed`) | a fabricated "forcing" proof obligation predicting the wrong hidden-test order |
| sympy-16597 | `irrational == real & finite & !rational` | rejected as "exceeds issue/hint scope" |

Unifying thesis (SYNTHESIS): *the binding constraint on FVK's value is intent fidelity
and localization — not formal expressiveness.* The fixes below are posture/judgment
guidance, not formal machinery.

## Wiring gap discovered

`AGENTS.md`'s bootstrap tells the agent to read `knowledge/intent-evidence.md` (and
`examples/`), but neither was staged into the fvk workspace — `fvk_bench/config.py`
`FVK_MATERIALS_FILES` omitted them. So the doc that most directly addresses two of the
four failures never reached the agent. Fixing this staging gap is part of the change.

## Changes

### A. FVK materials — fork `xc93/formal-verification-kit`, branch `fvk-improve-4cases`, commit `275cd44`

Each rule lands in the *executed* command file **and** is mirrored into
`intent-evidence.md` / `AGENTS.md` — the command files restate rules inline, so a
primer-only edit would not change agent behavior. Every rule carries a **balance
clause** (still require positive public-intent evidence) so we do not regress instances
where V1 was genuinely correct.

- **Tests & pre-fix displays are defeasible evidence, not an oracle** (django-12325,
  sympy-13852) — `commands/formalize.md §2`, `knowledge/intent-evidence.md §1`,
  `AGENTS.md`. Contrapositive trigger: if the issue reports current behavior X as the
  bug, any test/display encoding X is SUSPECT by default (the bug report *is* the
  contradiction); the correct fix may legitimately delete it.
- **A "forced / backward-compat-requires-it" claim is a hypothesis to falsify**
  (pytest-10356) — `commands/verify.md Step 2`, `knowledge/intent-evidence.md §4`. Name
  the alternative, predict its output, re-derive the legacy trace under both candidates
  side by side; if both satisfy the public obligations the choice is under-determined,
  never CONFIRM, and never a basis for predicting a hidden test's value.
- **A named-then-declined change must be promoted to a tested hypothesis** (sympy-16597)
  — `commands/verify.md Step 3`; the spec-difficulty=bug-signal heuristic now also fires
  on verbal rationalizations ("out of scope", "conventionally wrong but accepted") in
  `commands/formalize.md §7`.
- **Audit against the full intent, not the issue sentence** (cross-cutting) —
  `AGENTS.md` verdict list, broadened `V2 == V1` blocker in `commands/verify.md Step 1`,
  `knowledge/intent-evidence.md §5`.
- `AGENTS.md` TEMPLATE softened to degrade gracefully when `examples/` are not staged.

### B. Staging wiring — this repo, branch `fvk-improve-4cases`

- `fvk_bench/config.py`: add `knowledge/intent-evidence.md` to `FVK_MATERIALS_FILES`.
- `fvk_bench/prompts/fvk.md`: name it in Task 1's explicit read list.
- Tests updated: `tests/fvk_bench/test_config.py` (tuple) and `tests/fvk_bench/test_arms.py`
  (rename `test_stage_fvk_copies_8_files` → `…_9_files`; the count assertion is dynamic).
- The full `examples/` tree was **not** staged — the misses are posture, not template,
  failures; `AGENTS.md` TEMPLATE now degrades gracefully when examples are absent.

### C. Submodule repoint — this repo

- `.gitmodules`: `third_party/formal-verification-kit` URL
  `https://github.com/grosu/formal-verification-kit.git` →
  `git@github.com:xc93/formal-verification-kit.git`.
- Pointer: `cbce1cc` → `275cd44`. `275cd44` includes the 6 fork commits already past
  `cbce1cc` (provenance / adequacy / ordering-gate hardening) plus this change.

## Verification (owner: re-run)

This is a no-execution materials change; the real test is re-running the fvk arm on the
four instances and confirming they flip to PASS without regressing the currently-passing
set. Run off-band so it does not collide with the in-flight benchmark sessions.

## Provenance

- Fork worktree `formal-verification-kit-xc93-wt-fvk`, branch `fvk-improve-4cases`,
  commit `275cd44` (pushed to `origin`).
- Main worktree `fastxyz-SWE-bench-wt-fvk`, branch `fvk-improve-4cases`.
- The benchmark working copy and the submodule it currently uses (`cbce1cc`) were left
  untouched so in-flight sessions are not disturbed.
