# FINDINGS

Status: constructed, not machine-checked.

## FVK-F1: V1 removes the exactly-one bug

Input class: non-native XOR fallback with child truths `[true, true, true]`.

Observed in pre-fix code: false, because `truth_count == 1` is false for count
`3`.

Expected by public intent: true, because `3` is odd.

V1 result: true, because `truth_count % 2 == 1`.

Classification: code bug resolved by V1. Discharges `PO-XOR-PARITY` for the
reported three-operand case.

## FVK-F2: V1 handles the full repeated-true family

Input class: repeated identical true predicates of length `n >= 1`.

Observed in pre-fix code: true only when `n == 1`; false for `n == 3` and
`n == 5`.

Expected by public intent: true exactly when `n` is odd, producing the sequence
`1, 0, 1, 0, 1` for lengths `1..5`.

V1 result: `n % 2 == 1`, matching the expected sequence and generalizing it.

Classification: family obligation resolved by V1. Discharges
`PO-REPEATED-TRUE-FAMILY`.

## FVK-F3: Empty internal XOR nodes are outside the public path

Input class: direct internal construction of an empty `WhereNode(connector=XOR)`
on a non-native backend.

Observed in V1 source: the fallback still uses `reduce()` without an initializer,
so an empty child list is not defined by this branch.

Expected by public intent: no public evidence requires direct empty internal
`WhereNode(XOR)` construction to render SQL. Public `Q()` XOR combination avoids
this path: `Q._combine()` returns the non-empty side when one operand is empty,
and `Q() ^ Q()` produces an empty non-XOR `Q()`.

Classification: documented domain boundary, not a code change. Tracked by
`PO-DOMAIN`.

## FVK-F4: The retained OR wrapper is redundant but compatible

Input class: any non-empty child truth list.

Observed in V1 source: the fallback keeps `(c1 OR ... OR cn)` and adds
`truth_count % 2 == 1`.

Expected by public intent: odd parity. The OR wrapper does not change parity
because an odd truth count implies at least one true child.

Classification: compatibility-preserving redundancy, not a defect. Discharges
`PO-OR-REDUNDANCY`.

## FVK-F5: No public compatibility regression found

Input class: public ORM callers using `Q.__xor__()`, queryset XOR combinators,
and `WhereNode.as_sql()` through the compiler.

Observed in V1 source: no public symbol, signature, return shape, or virtual
dispatch contract changed.

Expected by public compatibility: existing callers keep the same API surface.

Classification: pass. Discharges `PO-COMPATIBILITY`.

## Proof-Derived Findings

No proof-derived source bug was found after formalizing the parity contract. The
only open boundary is FVK-F3, which is outside the public issue path and is not
used to justify a source edit.
