# Findings

Status: FVK audit of V1. Findings use public evidence only; no hidden tests,
benchmark outcomes, or upstream fixes were used.

## F1: Original empty-input failure is closed by V1

Input: interactive quickstart with selected root containing `conf.py`.

Observed in V0: quickstart warned about existing `conf.py`, prompted for a new
root, and pressing Enter reached `is_path('')`, producing "Please enter a valid
path name" instead of exiting.

Expected: status-1 termination with no generation.

V1 status: closed. `ask_user()` now exits immediately after the existing-project
warning, and `main()` converts that `SystemExit(1)` into return code `1`.

Trace: PO1, PO2, PO4, PO5; claims QS-EXISTING-ROOT and QS-EXISTING-SOURCE.

## F2: Replacement-root retry prompt is rejected as SUSPECT legacy behavior

Input: same as F1, but user attempts to enter a different root at the legacy
prompt.

Observed in V0: quickstart allowed a replacement-root retry loop. The issue
quotes this prompt because its empty-input branch is broken.

Expected per adopted intent: immediate status-1 failure for the already-selected
root. The public hint explicitly recommends this behavior.

V1 status: intentional behavior change, not a bug. The alternative fix of
allowing empty input through a custom validator was considered, but would
preserve a prompt that the FVK ledger classifies as legacy-derived and not
required.

Trace: PO1, PO4, SPEC_AUDIT "PASS" for no `replacementPrompt`.

## F3: Source-layout existing project is covered

Input: selected root lacks `conf.py` but contains `source/conf.py`.

Observed in V0: the same existing-project loop was entered and empty input could
hit the same invalid-path validator.

Expected: same status-1/no-generation behavior as root-level `conf.py`.

V1 status: closed by preserving the original two-location guard and applying the
immediate exit to both locations.

Trace: PO3; claim QS-EXISTING-SOURCE.

## F4: Public tests should be added, but not edited in this task

Input classes to cover later:

- `main([])` or equivalent interactive invocation in a directory with `conf.py`
  returns status `1` without calling the replacement-root prompt.
- Same for `source/conf.py`.
- A normal empty target still proceeds through the existing questionnaire.

V1 status: no source-code blocker. This is a test-gap recommendation only; the
task forbids modifying tests and forbids running them.

Trace: PO6, PO8.

## Proof-derived findings from `/verify`

No blocking proof-derived code defect was found in the audited branch. The only
open proof limitation is scope: QS-NO-CONF-FRAME is a reduced frame claim rather
than a proof of the entire quickstart questionnaire. This does not block V1
because the V1 diff does not change the questionnaire after the existing-project
guard.
