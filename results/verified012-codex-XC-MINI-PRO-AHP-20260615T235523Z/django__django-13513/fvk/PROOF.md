# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, Python, or tests were run.

## Machine-Check Commands Not Executed

The commands to machine-check this proof later are:

```sh
kompile fvk/mini-exception-chain.k --backend haskell
kast --backend haskell fvk/exception-reporter-spec.k
kprove fvk/exception-reporter-spec.k
```

Expected successful machine-check result: `#Top` for all claims.

## Proof Summary

The core property is the resolver contract:

```text
resolve(explicit, suppress, implicit) =
    explicit, if explicit != none
    none,     if explicit == none and suppress == true
    implicit, otherwise
```

The V2 source implements this with ordered branches:

```python
explicit = getattr(exc_value, '__cause__', None)
if explicit is not None:
    return explicit
if getattr(exc_value, '__suppress_context__', False):
    return None
return getattr(exc_value, '__context__', None)
```

This directly discharges PO1.

## Claim Proofs

### `resolve(none, true, OLD) => none`

Symbolic execution selects the second resolver rule in `mini-exception-chain.k`. The explicit cause is `none`, so the explicit-cause rule is unavailable. The suppress flag is `true`, so the result rewrites to `none`.

This proves the reported `raise ... from None` cause edge stops before the implicit context.

### `resolve(CAUSE, SUPPRESS, CTX) => CAUSE` when `CAUSE != none`

The precondition makes the explicit-cause rule available. That rule has precedence over suppression and context in both the formal model and the V2 source branch order. The result is `CAUSE`.

### `resolve(none, false, CTX) => CTX`

The explicit-cause rule is unavailable because the explicit value is `none`. The suppress rule is unavailable because suppression is `false`. The implicit-context rule rewrites to `CTX`.

### `isExplicit(none) => false`

The `none` rule for `isExplicit` rewrites directly to `false`, matching the absence of a direct explicit cause.

### `isExplicit(CAUSE) => true` when `CAUSE != none`

The precondition enables the non-`none` rule for `isExplicit`, which rewrites directly to `true`. This matches V2's `getattr(..., '__cause__', None) is not None`.

### Suppressed Issue Chain

Initial state:

```text
collect(exc(1), 2)
explicit(exc(1)) = none
suppress(exc(1)) = true
context(exc(1)) = exc(0)
seen = []
```

Symbolic execution:

1. `collect(exc(1), 2)` looks up the three attributes and schedules `resolve(none, true, exc(0))`.
2. The suppressed resolver claim rewrites that value to `none`.
3. `continueCollect(exc(1), 2)` appends `exc(1)` to `seen` and continues with `collect(none, 1)`.
4. `collect(none, 1)` terminates.

Post-state:

```text
seen = [exc(1)]
```

The handled `exc(0)` is not collected. This discharges PO2 for the public issue case.

### Unsuppressed Discriminator Chain

Initial state is the same except `suppress(exc(1)) = false`, and `exc(0)` has no further context. Symbolic execution follows the implicit-context resolver rule on the first step, appending `exc(1)` and continuing with `exc(0)`. The second exception resolves to `none`, so traversal terminates with:

```text
seen = [exc(1), exc(0)]
```

This shows the abstraction distinguishes the defect axis: suppressed and unsuppressed contexts produce different visible chains.

## Source-Level Composition

`get_traceback_frames()` uses `explicit_or_implicit_cause()` in both places relevant to the issue:

- The pre-render loop advances `exc_value` through the chain.
- Each frame's `exc_cause` is computed for template display.

V2 also changes the loop guard to `exc_value is not None`, aligning the traversal with the resolver's sentinel semantics, and changes `exc_cause_explicit` to the predicate `__cause__ is not None`.

## Residual Risk

This proof is partial correctness over the exception-chain model. It does not prove total correctness, actual Django template rendering, source-file lookup, traceback hiding, cycle-warning emission, or performance. Test removal is not recommended in this benchmark because no tests were inspected for redundancy and the proof was not machine-checked.
