# Proof Obligations

Status: constructed, not machine-checked.

## PO1 - Cause Resolution Respects PEP 415

For every exception-like value `E`:

```text
if E.__cause__ is not None:
    resolve(E) == E.__cause__
elif E.__suppress_context__:
    resolve(E) is None
else:
    resolve(E) == E.__context__
```

Public evidence: E1-E4.

K claims:

- `resolve(CAUSE, SUPPRESS, CTX) => CAUSE` when `CAUSE != none`
- `resolve(none, true, OLD) => none`
- `resolve(none, false, CTX) => CTX`

Source discharge:

`explicit_or_implicit_cause()` in `repo/django/views/debug.py` implements the three branches in this order.

## PO2 - Exception Chain Traversal Uses The PEP 415 Resolver

For the exception-chain loop in `get_traceback_frames()`:

```text
exceptions starts empty
current starts as self.exc_value
while current is not None:
    append current
    current = resolve(current)
    stop early on cycles
```

Public evidence: E1-E4 and E6.

K claims:

- Suppressed issue chain records only `exc(1)`.
- Unsuppressed discriminator chain records `exc(1), exc(0)`.

Source discharge:

V2 uses `while exc_value is not None` and assigns `exc_value = explicit_or_implicit_cause(exc_value)` inside the loop.

## PO3 - Frame Metadata Uses The Same Resolver And An Explicitness Predicate

For every rendered frame associated with exception value `E`:

```text
frame["exc_cause"] == resolve(E)
frame["exc_cause_explicit"] == (E.__cause__ is not None)
```

Public evidence: E5-E6.

K claims:

- `isExplicit(none) => false`
- `isExplicit(CAUSE) => true` when `CAUSE != none`

Source discharge:

V2 sets `exc_cause` through `explicit_or_implicit_cause(exc_value)` and sets `exc_cause_explicit` with `getattr(exc_value, '__cause__', None) is not None`.

## PO4 - Public Compatibility Is Preserved

The fix must not change the public `ExceptionReporter.get_traceback_frames()` signature, remove frame keys, or require template changes.

Public evidence: `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

Source discharge:

V2 keeps the method signature and frame keys unchanged. Existing templates continue to branch on `exc_cause` and `exc_cause_explicit`.

## PO5 - Honesty Gate

The proof artifacts must be labeled constructed, not machine-checked, because this session cannot run K tooling.

Discharge:

`fvk/PROOF.md` includes the exact intended `kompile`, `kast`, and `kprove` commands and labels the proof as constructed only.
