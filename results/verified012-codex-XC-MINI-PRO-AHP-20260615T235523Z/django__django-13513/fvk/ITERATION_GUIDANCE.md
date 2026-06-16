# Iteration Guidance

Status: constructed, not machine-checked.

## Code Decision

V1 did the main issue repair by honoring `__suppress_context__` in the resolver. The FVK audit found one adjacent consistency issue, FINDING F2: traversal and frame metadata still used truthiness where the spec uses the `None` sentinel.

V2 applies these source edits in `repo/django/views/debug.py`:

- Keep V1's ordered resolver branches.
- Change the chain loop from `while exc_value:` to `while exc_value is not None`.
- Change `exc_cause_explicit` from the raw `__cause__` object to `getattr(..., '__cause__', None) is not None`.

## Suggested Tests For Maintainers

Do not add or modify tests in this benchmark. For a normal development follow-up, useful tests would cover:

- `raise ValueError("new") from None` inside an `except RuntimeError` block does not display the `RuntimeError`.
- Explicit cause still displays as a direct cause even when `__suppress_context__` is true.
- Unsuppressed implicit context still displays "During handling..." text.
- `exc_cause_explicit` is true exactly when `__cause__ is not None`.

## Machine-Check Follow-Up

The proof can be machine-checked later with:

```sh
kompile fvk/mini-exception-chain.k --backend haskell
kast --backend haskell fvk/exception-reporter-spec.k
kprove fvk/exception-reporter-spec.k
```

Expected successful result: `#Top`.

## Stop Condition

Within the specified issue scope, V2 discharges PO1-PO4. No further production-code change is justified by the public intent and constructed proof artifacts.
