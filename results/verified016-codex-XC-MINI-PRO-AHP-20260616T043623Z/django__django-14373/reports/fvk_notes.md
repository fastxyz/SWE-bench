# FVK Notes

## Decision

V1 stands unchanged. No source files under `repo/` were edited during the FVK
pass.

## Trace to findings and proof obligations

- Kept `repo/django/utils/dateformat.py` as V1 because Finding F-02 confirms the
  current `return '%04d' % self.data.year` discharges PO-01, PO-02, PO-03, and
  PO-04 for every valid date year.
- Did not move the padding into `Formatter.format()` because PO-02 is already
  discharged through the existing dispatcher path, and PO-06 requires leaving
  unrelated dispatcher behavior unchanged.
- Accepted the `DateFormat.Y()` return type change from `int` to `str` because
  Finding F-03 and PO-05 show that leading zeroes are required at the method
  level and no in-repo direct caller or override needs a code change.
- Did not change `DateFormat.o()` because Finding F-04 records it as an
  adjacent, underspecified behavior outside the public `Y` obligation audited by
  PO-01 through PO-06.
- Did not modify or add tests because the benchmark forbids test edits, and
  Finding F-05 plus `fvk/PROOF.md` label the proof as constructed, not
  machine-checked.

## Artifacts changed

- Added `fvk/SPEC.md` to record the public intent ledger, formal model,
  adequacy audit, and compatibility audit.
- Added `fvk/FINDINGS.md` to record the pre-V1 bug, V1 confirmation, accepted
  compatibility note, adjacent `o` scope note, and no-execution caveat.
- Added `fvk/PROOF_OBLIGATIONS.md` to list the obligations used to judge V1.
- Added `fvk/PROOF.md` to give the constructed proof and future K commands.
- Added `fvk/ITERATION_GUIDANCE.md` to state that V1 stands and identify future
  tests/questions.
- Added `fvk/mini-dateformat.k` and `fvk/dateformat-y-spec.k` as supporting
  FVK formal-core files; their commands are documented but were not run.
