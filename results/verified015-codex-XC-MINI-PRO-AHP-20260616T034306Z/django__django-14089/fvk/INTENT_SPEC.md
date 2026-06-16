# Intent Spec

Status: constructed from public evidence only.

## Obligations

I-001: `OrderedSet` is an ordered collection. Its observable iteration order is
the insertion order of its distinct elements.

I-002: `reversed(ordered_set)` must be a valid operation for every valid
`OrderedSet` instance.

I-003: The elements produced by `reversed(ordered_set)` must be the same
distinct elements as forward iteration, but in the opposite order.

I-004: Calling `reversed(ordered_set)` must not mutate the `OrderedSet`.

I-005: Empty, singleton, and duplicate-containing construction inputs are in
scope. Duplicates are governed by the existing set semantics: only the first
insertion position of each distinct element remains observable.

I-006: The implementation may rely on Python dictionary ordering and reverse
iteration because the local project metadata requires Python `>=3.8`.
