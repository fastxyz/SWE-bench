# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Initial `docID()` state

Statement: For a fresh iterator returned by `IntervalBuilder.NO_INTERVALS.intervals(...)`, before
any call to `nextDoc()` or `advance(int)`, `docID()` returns `-1`.

Evidence: E-001, E-002, E-005.

V1 discharge: `private int doc = -1` initializes the anonymous iterator state, and `docID()` returns
`doc`.

Finding trace: F-001.

## PO-002: `nextDoc()` exhausts the empty iterator

Statement: From the initial state, `nextDoc()` returns `NO_MORE_DOCS`.

Evidence: E-004, E-005, E-006.

V1 discharge: `nextDoc()` executes `return doc = NO_MORE_DOCS;`.

Finding trace: F-001.

## PO-003: `advance(int)` exhausts the empty iterator

Statement: From the initial state, for every target in the `DocIdSetIterator` domain
`target >= 0`, `advance(target)` returns `NO_MORE_DOCS`.

Evidence: E-004, E-005, E-006.

V1 discharge: `advance(int target)` executes `return doc = NO_MORE_DOCS;`; the target is irrelevant
because the iterator has no matching documents.

Finding trace: F-001.

## PO-004: Exhausted `docID()` state

Statement: After `nextDoc()` or `advance(int)` has exhausted the empty iterator, `docID()` returns
`NO_MORE_DOCS`.

Evidence: E-005.

V1 discharge: both document-advancing methods assign `NO_MORE_DOCS` to `doc`, and `docID()` returns
that field.

Finding trace: F-001.

## PO-005: Conjunction setup compatibility

Statement: A `NO_INTERVALS` iterator combined with a normal unpositioned iterator must satisfy the
same-current-doc precondition used by `ConjunctionDISI.createConjunction`.

Evidence: E-004, E-007.

V1 discharge: a fresh `NO_INTERVALS` iterator reports `-1`, so it agrees with normal unpositioned
`DocIdSetIterator` implementations that also report `-1`. The diagnostic formal claim
`sameDoc(NO_MORE_DOCS, -1) => false` explains why V0 failed this obligation.

Finding trace: F-002.

## PO-006: No-match frame condition

Statement: The fix must not turn `NO_INTERVALS` into a matching iterator or change public API shape.
It should only repair document-position state.

Evidence: E-001 through E-004 and the compatibility audit in `SPEC.md`.

V1 discharge: the patch does not change signatures or matching behavior. `nextInterval()` still
returns `NO_MORE_INTERVALS`, `matches(...)` still returns `null`, and costs remain zero.

Finding trace: F-003.
