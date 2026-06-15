# FVK Notes

The FVK audit confirmed V1 rather than changing production code.

Decision D-001: keep the one-line `_add_q()` recursion change. This follows from
F-001 and PO-001/PO-002: the reported failure is exactly that nested `Q` nodes
lost `simple_col=True`, and V1 preserves the flag through recursion.

Decision D-002: do not add backend-specific SQL cleanup. F-003 and PO-006 trace
the defect to expression construction before backend rendering, so alias
stripping after SQL compilation would be less direct and more fragile.

Decision D-003: do not change public APIs or ordinary query compilation. F-002
and PO-003/PO-005 show that V1 propagates the existing flag value; ordinary
`Query.add_q()` still enters `_add_q()` with `simple_col=False`.

Decision D-004: do not modify tests or claim machine-checked proof status.
F-004 records the proof capability gap, and PROOF.md lists the commands that
should be run later. The task forbids tests and K tooling in this environment.
