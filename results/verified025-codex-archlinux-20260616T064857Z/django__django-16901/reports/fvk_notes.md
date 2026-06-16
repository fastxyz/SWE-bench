# FVK Notes

## Decision: keep V1 source unchanged

V1 changes the non-native XOR fallback in `repo/django/db/models/sql/where.py`
from `truth_count == 1` to `truth_count % 2 == 1`. FVK-F1 shows this fixes the
reported `[true, true, true]` counterexample, and FVK-F2 shows the same formula
covers the full repeated-true family required by the issue's expected
`1, 0, 1, 0, 1` sequence.

This decision is discharged by `PO-XOR-PARITY`, `PO-CASE-COUNT`, `PO-SUM`, and
`PO-MOD-PARITY`: the existing `CASE` terms still count true children, the sum is
unchanged, and the new modulo comparison is exactly odd parity. The issue's
explicit repeated-true sequence is covered by `PO-REPEATED-TRUE-FAMILY`.

## Decision: retain the OR wrapper

I left `(c1 OR ... OR cn)` in the fallback even though parity alone is sufficient.
FVK-F4 and `PO-OR-REDUNDANCY` show this term is logically redundant because an
odd truth count implies at least one true child. Keeping it avoids an unrelated
shape change to the generated SQL and preserves the existing short-circuit
structure.

## Decision: do not add an empty-list initializer

I did not change `reduce(operator.add, ...)` to handle a directly constructed
empty internal XOR node. FVK-F3 and `PO-DOMAIN` classify that as outside the
public issue path: normal `Q()` XOR combination removes empty operands before an
XOR node reaches SQL rendering. The public intent requires parity for
ORM-produced `Q(...) ^ Q(...)` predicate lists, not a new behavior for direct
internal `WhereNode(connector=XOR)` construction.

## Decision: no compatibility edits

FVK-F5 and `PO-COMPATIBILITY` show V1 changes no public symbol, method signature,
return shape, virtual dispatch call, or test file. The existing negation path is
covered by `PO-NEGATION`, which confirms `self.negated` still negates the parity
predicate through the synthesized node.

## Artifacts

I wrote the requested FVK artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

I also emitted the formal core required by the FVK docs:

- `fvk/mini-xor-fallback.k`
- `fvk/xor-fallback-spec.k`

No tests, Python code, or K tooling were run.
