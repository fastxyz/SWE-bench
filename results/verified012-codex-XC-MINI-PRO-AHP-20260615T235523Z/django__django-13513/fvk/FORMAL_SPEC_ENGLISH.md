# Formal Spec In English

This file paraphrases the K claims in `exception-reporter-spec.k`.

1. `resolve(none, true, OLD) => none`: when there is no explicit cause and context suppression is true, the next visible cause is `None`, regardless of the implicit context value.
2. `resolve(CAUSE, SUPPRESS, CTX) => CAUSE` when `CAUSE != none`: when an explicit cause exists, it is the next visible cause regardless of suppress-context or implicit context.
3. `resolve(none, false, CTX) => CTX`: when there is no explicit cause and suppression is false, the implicit context is the next visible cause.
4. `isExplicit(none) => false`: a missing explicit cause is not an explicit-cause edge.
5. `isExplicit(CAUSE) => true` when `CAUSE != none`: any present explicit cause is an explicit-cause edge.
6. `collect(exc(1), 2)` with `explicit(exc(1)) = none`, `suppress(exc(1)) = true`, and `context(exc(1)) = exc(0)` records only `exc(1)`: the issue's `ValueError from None` does not traverse to the handled `RuntimeError`.
7. `collect(exc(1), 3)` with the same context but `suppress(exc(1)) = false` records `exc(1)` then `exc(0)`: the model distinguishes suppressed and unsuppressed contexts.
