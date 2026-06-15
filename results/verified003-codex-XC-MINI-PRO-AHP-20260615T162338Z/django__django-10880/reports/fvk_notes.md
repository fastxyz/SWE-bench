# FVK Notes

The FVK audit confirms V1 should stand unchanged.

Decision D-1: keep the source change in `repo/django/db/models/aggregates.py`.

Trace: `fvk/FINDINGS.md` F-1 identifies the bug as missing token separation in distinct aggregate SQL, and `fvk/PROOF_OBLIGATIONS.md` PO-1 and PO-2 show the V1 marker `DISTINCT ` discharges it for `COUNT(CASE ...)`.

Decision D-2: make no additional source edits for backend-specific conditional aggregation.

Trace: F-2 and PO-4/PO-5 show that `Aggregate.as_sql()` sets the fixed distinct marker before branching, so both the native `FILTER` path and the fallback `Case(When(...))` path receive the same corrected value.

Decision D-3: do not move the space into `Aggregate.template`.

Trace: F-3 and PO-3 require preserving non-distinct rendering. Putting a literal space in the template would create an extra post-parenthesis space when `distinct=False`.

Decision D-4: do not special-case `Count` or `Case`.

Trace: F-1 localizes the symptom to the shared `%(distinct)s%(expressions)s` interpolation, and PO-2 proves the shared marker is the needed separator for any expression whose SQL follows `DISTINCT` immediately.

Decision D-5: leave tests untouched and do not run tests or K tooling.

Trace: F-5 and PO-8 record the task constraint and the FVK honesty gate. `fvk/PROOF.md` includes the exact commands a future environment can run, labeled constructed but not machine-checked.
