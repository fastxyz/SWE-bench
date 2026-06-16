# FVK Iteration Guidance

## Verdict

V1 stands unchanged. The FVK audit found that the V1 source branch discharges
the public intent and proof obligations for same-field `AlterField` reduction.

## Decisions

G-001: Keep the V1 `AlterField.reduce()` branch unchanged.

Trace: F-001, PO-001, PO-002, and PO-004.

Reason: the branch exactly implements the public suggested reduction and the
optimizer loop collapses finite same-field chains by repeated pairwise
shortening.

G-002: Do not add a broader generic `FieldOperation` reduction.

Trace: F-002, PO-006.

Reason: a broader branch would risk collapsing operations for different fields
or operations with distinct semantics. The public issue is specifically
same-field `AlterField` followed by `AlterField`.

G-003: Do not add a `preserve_default` guard.

Trace: F-004, PO-002.

Reason: the expected replacement is the later operation itself. Returning
`[operation]` preserves the later payload exactly; adding a guard would leave
some valid same-field `AlterField` chains unreduced.

G-004: Do not edit tests or run tests/tooling in this pass.

Trace: F-005, PO-008.

Reason: the task forbids modifying tests and forbids running tests, Python, or K
tooling. The artifacts record commands for later machine-checking.

## Suggested Future Checks

Add or keep a Django optimizer regression test outside this restricted session
for a sequence of three same-field `AlterField` operations and assert that only
the final `AlterField` remains.

Keep tests that cover different fields, `RemoveField`, `RenameField`,
non-elidable boundaries, and migration/database integration. They exercise
behavior intentionally outside the mini K model.
