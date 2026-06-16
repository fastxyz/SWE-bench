# FVK Findings

Status: constructed, not machine-checked. Findings do not rely on hidden tests
or evaluator results.

## F-001: Missing `Pipeline.__len__` on the issue path

Input: a valid two-step `Pipeline`, such as the issue reproducer with
`('anova', anova_filter)` and `('svc', clf)`.

Pre-V1 observed behavior: `len(pipe)` raises because `Pipeline` did not
implement `__len__`; consequently `pipe[:len(pipe)]` fails before existing
slice handling can run.

Expected behavior: `len(pipe)` returns `2`, and `pipe[:len(pipe)]` is evaluable
as the full pipeline slice.

Related proof obligations: PO-1 and PO-2.

Status: CLOSED by V1. The source now returns `len(self.steps)`, and the formal
claims discharge the length and full-slice obligations over any non-negative
step count.

## F-002: Broader sequence behavior is intentionally out of scope

Input: attempts to rely on iteration over `Pipeline` merely because indexing and
length exist.

Observed V1 behavior: V1 does not add `__iter__`.

Expected behavior: no broader sequence protocol is required; the public hints
explicitly prefer adding only length and not adding sequence methods such as
`__iter__`.

Related proof obligation: PO-3.

Status: CONFIRMED. No source change is needed.

## F-003: Truthiness compatibility after adding `__len__`

Input: valid constructed `Pipeline` objects.

Potential observed behavior: Python may call `__len__` for truthiness once the
method exists.

Expected behavior: valid `Pipeline` instances remain truthy.

Related proof obligation: PO-4.

Status: CONFIRMED for valid public objects. Valid construction requires at least
one step, so `len(pipe) >= 1`. A manually mutated empty `steps` sequence is
outside the documented valid construction contract, and `__len__` would still
return the actual cardinality.

## Proof-derived findings from `/verify`

No proof-derived code bug or missing precondition was found in V1. The only side
condition introduced by the formal model is `N >= 0`, which is the standard
cardinality condition for sequence lengths. No loop invariant, ordering rule, or
candidate-derived postcondition is required to justify keeping V1.
