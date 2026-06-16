# FVK Spec

Status: constructed, not machine-checked. No tests, Python, `kompile`, or `kprove` were run.

## Scope

This FVK run audits the exception-chain portion of `ExceptionReporter.get_traceback_frames()` in `repo/django/views/debug.py`. The observable under audit is which chained exceptions appear in Django's technical 500 traceback and how each frame marks direct explicit causes versus implicit context.

Out of scope for this issue-specific proof: source file loading, source context line extraction, local variable filtering, HTML escaping, text rendering, email/report plumbing, and traceback hiding. Those operations do not decide whether `raise ... from None` exposes the suppressed handled exception.

## Public Intent Ledger

| ID | Evidence | Obligation |
| --- | --- | --- |
| E1 | `benchmark/PROBLEM.md`: "debug error view doesn't respect exc.__suppress_context__ (PEP 415)" | The debug reporter must consult `__suppress_context__` before exposing `__context__`. |
| E2 | `benchmark/PROBLEM.md`: `raise ValueError('my new error') from None` | A raised exception with `__cause__ is None` and `__suppress_context__ is True` must not show its handled context. |
| E3 | `benchmark/PROBLEM.md`: "the debug error view still shows the RuntimeError" | The legacy behavior of including that `RuntimeError` is the bug, not an invariant. |
| E4 | `benchmark/PROBLEM.md`: proposed helper shape using `__cause__`, then `None if __suppress_context__ else __context__` | Explicit cause has precedence; implicit context is conditional on suppression. |
| E5 | Django technical 500 templates branch on `frame.exc_cause_explicit` | The frame value is used as an explicit-cause flag. |
| E6 | `get_traceback_frames()` first builds an exception chain and later attaches `exc_cause` metadata | Both traversal and metadata must use the same cause-resolution rule. |

The expanded evidence ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

## Contract

For an exception-like value `E`, define:

- `explicit(E) = getattr(E, "__cause__", None)`
- `suppressed(E) = getattr(E, "__suppress_context__", False)`
- `implicit(E) = getattr(E, "__context__", None)`

The intended next visible cause is:

```text
resolve(E) =
    explicit(E), if explicit(E) is not None
    None,        if explicit(E) is None and suppressed(E) is true
    implicit(E), otherwise
```

`get_traceback_frames()` must use this `resolve(E)` for:

1. Building the exception chain before frame rendering.
2. Populating each frame's `exc_cause`.
3. Populating each frame's explicit-cause flag as `explicit(E) is not None`.

## Formal Model

The formal model is intentionally small and property-complete for this defect:

- `Cause ::= none | exc(Int)` models absence or presence of a visible exception edge.
- `resolve(Cause, Bool, Cause)` models explicit cause, suppress flag, and implicit context.
- `isExplicit(Cause)` models the template branch flag.
- `collect(Cause, Int)` models the finite visible-chain traversal used by `get_traceback_frames()`; the integer is proof fuel for the bounded claims.

Files:

- `fvk/mini-exception-chain.k`
- `fvk/exception-reporter-spec.k`

The abstraction distinguishes the reported failing behavior from the expected behavior:

- Suppressed context: `collect(exc(1), 2)` records only `exc(1)`.
- Unsuppressed context: `collect(exc(1), 3)` records `exc(1)` then `exc(0)`.

## Adequacy Result

`fvk/FORMAL_SPEC_ENGLISH.md` paraphrases every nontrivial K claim. `fvk/SPEC_AUDIT.md` compares those paraphrases to `fvk/INTENT_SPEC.md`. All obligations pass the adequacy gate; no claim depends on hidden tests, evaluator results, or legacy behavior as an oracle.

## Compatibility Result

`fvk/PUBLIC_COMPATIBILITY_AUDIT.md` found no public signature change. The only in-repo consumers of `exc_cause_explicit` use it as a boolean branch flag, so V2's boolean value is compatible with the observed consumer contract.
